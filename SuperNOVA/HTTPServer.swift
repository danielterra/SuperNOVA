//
//  HTTPServer.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class HTTPServer {
    let port: UInt16 = 8080
    var serverSocket: Int32 = -1
    
    func start() {
        LogManager.shared.addLog("Initializing HTTP server on port \(port)", component: "HTTPServer")

        serverSocket = socket(AF_INET, SOCK_STREAM, 0)

        guard serverSocket >= 0 else {
            LogManager.shared.addError("Error creating socket", component: "HTTPServer", code: errno)
            return
        }

        LogManager.shared.addLog("Socket created successfully (fd: \(serverSocket))", component: "HTTPServer")

        var yes: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult >= 0 else {
            LogManager.shared.addError("Error binding socket to port \(port)", component: "HTTPServer", code: errno)
            return
        }

        LogManager.shared.addLog("Socket bound successfully to port \(port)", component: "HTTPServer")
        LogManager.shared.addLog("Server starting on port \(port), listening for connections...", component: "HTTPServer")
        listen(serverSocket, 5)
        acceptConnections()
    }
    
    func acceptConnections() {
        LogManager.shared.addLog("Entering accept loop, waiting for client connections", component: "HTTPServer")

        while true {
            let clientSocket = accept(serverSocket, nil, nil)

            if clientSocket < 0 {
                LogManager.shared.addError("Error accepting connection", component: "HTTPServer", code: errno)
                continue
            }

            LogManager.shared.addLog("Client connected (fd: \(clientSocket))", component: "HTTPServer")
            handleRequest(clientSocket: clientSocket)
        }
    }
    
    func handleRequest(clientSocket: Int32) {
        LogManager.shared.addLog("Handling request from client (fd: \(clientSocket))", component: "HTTPServer")

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)

        guard bytesRead > 0 else {
            LogManager.shared.addError("No data received or connection closed (fd: \(clientSocket))", component: "HTTPServer")
            close(clientSocket)
            return
        }

        LogManager.shared.addLog("Received \(bytesRead) bytes from client", component: "HTTPServer")

        let requestData = String(bytes: buffer[..<bytesRead], encoding: .utf8) ?? ""
        let lines = requestData.components(separatedBy: "\r\n")

        guard let requestLine = lines.first else {
            LogManager.shared.addError("Invalid request: no request line", component: "HTTPServer")
            close(clientSocket)
            return
        }

        let parts = requestLine.components(separatedBy: " ")
        let method = parts.count > 0 ? parts[0] : "UNKNOWN"
        let path = parts.count > 1 ? parts[1] : "/"
        let httpVersion = parts.count > 2 ? parts[2] : ""

        var headers: [String] = []
        for i in 1..<lines.count {
            let line = lines[i]
            if line.isEmpty { break }
            headers.append(line)
        }

        var logDescription: String = ""
        logDescription += "\(method) \(path)\n"
        logDescription += "   HTTP Version: \(httpVersion)\n"
        for header in headers {
            logDescription += "   \(header)\n"
        }
        LogManager.shared.addLog(logDescription, component: "HTTPServer")

        let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
        let bytesSent = send(clientSocket, response, response.count, 0)

        if bytesSent > 0 {
            LogManager.shared.addLog("Response sent: \(bytesSent) bytes to client (fd: \(clientSocket))", component: "HTTPServer")
        } else {
            LogManager.shared.addError("Failed to send response to client", component: "HTTPServer", code: errno)
        }

        close(clientSocket)
        LogManager.shared.addLog("Connection closed (fd: \(clientSocket))", component: "HTTPServer")
    }
}
