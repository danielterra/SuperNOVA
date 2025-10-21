//
//  SuperNOVAApp.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers
import os.log

@main
struct SuperNOVAApp: App {
    let server = HTTPServer()

    init() {
        // Suppress benign system warnings
        suppressSystemWarnings()

        // Initialize SQLite database
        _ = SQLiteDatabase.shared

        // Initialize SwiftData for logs
        LogManager.shared.modelContext = sharedModelContainer.mainContext
        LogManager.shared.addLog("🚀 Server starting...")

        DispatchQueue.global(qos: .background).async { [server] in
            server.start()
        }
    }

    private func suppressSystemWarnings() {
        // Redirect stderr to suppress benign ViewBridge warnings
        let suppressedMessages = [
            "ViewBridge to RemoteViewService Terminated",
            "Unable to obtain a task name port right",
            "FSFindFolder failed"
        ]

        // Custom log handler to filter out unwanted messages
        let originalStderr = dup(STDERR_FILENO)
        var pipe: [Int32] = [0, 0]
        Darwin.pipe(&pipe)

        dup2(pipe[1], STDERR_FILENO)
        close(pipe[1])

        DispatchQueue.global(qos: .background).async {
            let readPipe = pipe[0]
            let bufferSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            while true {
                let bytesRead = read(readPipe, &buffer, bufferSize)
                guard bytesRead > 0 else { break }

                let output = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""

                // Only write to original stderr if not suppressed
                let shouldSuppress = suppressedMessages.contains { output.contains($0) }
                if !shouldSuppress {
                    write(originalStderr, output, output.utf8.count)
                }
            }
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Log.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If schema migration fails, delete old database and recreate
            print("⚠️ ModelContainer creation failed: \(error)")
            print("🔄 Attempting to delete old SwiftData store and recreate...")

            // Delete SwiftData files
            if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupportURL.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)

                // Try again
                do {
                    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    print("✅ ModelContainer created successfully after cleanup")
                    return container
                } catch {
                    fatalError("Could not create ModelContainer even after cleanup: \(error)")
                }
            }

            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .importExport) {
                Button("Export Database...") {
                    exportDatabase()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }

    private func exportDatabase() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "sqlite")!]
        savePanel.nameFieldStringValue = "supernova_backup_\(Date().timeIntervalSince1970).sqlite"
        savePanel.title = "Export Database"
        savePanel.message = "Choose where to save the database backup"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                let dbPath = SQLiteDatabase.shared.getDatabasePath()
                try FileManager.default.copyItem(at: URL(fileURLWithPath: dbPath), to: url)

                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Export Successful"
                    alert.informativeText = "Database exported to:\n\(url.path)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = "Error: \(error.localizedDescription)"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
}
