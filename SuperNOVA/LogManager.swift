//
//  LogManager.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation
import SwiftData

@Observable
class LogManager {
    static let shared = LogManager()
    var modelContext: ModelContext?
    
    func addLog(_ message: String, component: String = "System", severity: LogSeverity = .info) {
        DispatchQueue.main.async {
            let log = Log(message: message, component: component, severity: severity)
            self.modelContext?.insert(log)
            try? self.modelContext?.save()
        }
    }
    
    func addError(_ message: String, component: String = "System", code: Int32 = 0) {
        DispatchQueue.main.async {
            let fullMessage = code != 0 ? "\(message): \(String(cString: strerror(code)))" : message
            let log = Log(message: fullMessage, component: component, severity: .error)
            self.modelContext?.insert(log)
            try? self.modelContext?.save()
        }
    }
}
