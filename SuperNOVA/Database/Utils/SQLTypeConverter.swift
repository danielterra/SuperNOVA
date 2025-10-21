//
//  SQLTypeConverter.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class SQLTypeConverter {
    static func convertValue(_ value: Any?) -> Any? {
        // Handle nil explicitly
        guard let value = value else {
            return nil
        }

        if value is NSNull {
            return nil
        }

        if let array = value as? [Any] {
            if let jsonData = try? JSONSerialization.data(withJSONObject: array),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }

        if let dict = value as? [String: Any] {
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }

        if let date = value as? Date {
            return date.timeIntervalSince1970
        }

        return value
    }

    static func sanitizeColumnName(_ name: String) -> String {
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
    }

    static func generateTableName(for classId: String) -> String {
        return "entity_\(classId.replacingOccurrences(of: "-", with: "_"))"
    }
}
