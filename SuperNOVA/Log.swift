//
//  Log.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation
import SwiftData

enum LogSeverity: String, Codable {
    case info
    case warning
    case error
}

@Model
final class Log {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var message: String
    var component: String
    var severity: LogSeverity

    init(message: String, component: String, severity: LogSeverity) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.component = component
        self.severity = severity
    }
}
