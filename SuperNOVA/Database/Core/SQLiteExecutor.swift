//
//  SQLiteExecutor.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation
import SQLite3

class SQLiteExecutor {
    private let connection: SQLiteConnection

    init(connection: SQLiteConnection) {
        self.connection = connection
    }

    @discardableResult
    func execute(_ sql: String, parameters: [Any?] = []) -> Bool {
        // Log complete SQL with parameters
        let parametersStr = parameters.map { param in
            if let value = param {
                return "\(value)"
            }
            return "NULL"
        }.joined(separator: ", ")

        LogManager.shared.addLog("📝 SQL EXECUTE: \(sql)", component: "SQLiteExecutor")
        if !parameters.isEmpty {
            LogManager.shared.addLog("   Parameters: [\(parametersStr)]", component: "SQLiteExecutor")
        }

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(connection.db, sql, -1, &statement, nil) == SQLITE_OK else {
            LogManager.shared.addError("SQL Error preparing statement: \(connection.errorMessage())", component: "SQLiteExecutor")
            return false
        }

        SQLiteBinder.bind(parameters: parameters, to: statement)

        let result = sqlite3_step(statement)
        sqlite3_finalize(statement)

        if result != SQLITE_DONE && result != SQLITE_ROW {
            LogManager.shared.addError("SQL Error executing statement: \(connection.errorMessage())", component: "SQLiteExecutor")
            return false
        }

        LogManager.shared.addLog("✅ SQL execution successful", component: "SQLiteExecutor")
        return true
    }

    func query(_ sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        // Log complete SQL with parameters
        let parametersStr = parameters.map { param in
            if let value = param {
                return "\(value)"
            }
            return "NULL"
        }.joined(separator: ", ")

        LogManager.shared.addLog("🔍 SQL QUERY: \(sql)", component: "SQLiteExecutor")
        if !parameters.isEmpty {
            LogManager.shared.addLog("   Parameters: [\(parametersStr)]", component: "SQLiteExecutor")
        }

        var statement: OpaquePointer?
        var results: [[String: Any]] = []

        guard sqlite3_prepare_v2(connection.db, sql, -1, &statement, nil) == SQLITE_OK else {
            LogManager.shared.addError("SQL Error preparing query: \(connection.errorMessage())", component: "SQLiteExecutor")
            return []
        }

        SQLiteBinder.bind(parameters: parameters, to: statement)

        while sqlite3_step(statement) == SQLITE_ROW {
            let row = SQLiteRowParser.parseRow(from: statement)
            results.append(row)
        }

        sqlite3_finalize(statement)

        LogManager.shared.addLog("✅ Query returned \(results.count) row\(results.count == 1 ? "" : "s")", component: "SQLiteExecutor")
        return results
    }

    func lastInsertRowId() -> Int64 {
        let rowId = connection.lastInsertRowId()
        LogManager.shared.addLog("Last insert row ID: \(rowId)", component: "SQLiteExecutor")
        return rowId
    }
}
