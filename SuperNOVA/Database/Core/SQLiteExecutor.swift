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
        LogManager.shared.addLog("Executing SQL statement with \(parameters.count) parameters", component: "SQLiteExecutor")

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(connection.db, sql, -1, &statement, nil) == SQLITE_OK else {
            LogManager.shared.addError("SQL Error preparing statement: \(connection.errorMessage())", component: "SQLiteExecutor")
            LogManager.shared.addError("SQL: \(sql)", component: "SQLiteExecutor")
            return false
        }

        SQLiteBinder.bind(parameters: parameters, to: statement)

        let result = sqlite3_step(statement)
        sqlite3_finalize(statement)

        if result != SQLITE_DONE && result != SQLITE_ROW {
            LogManager.shared.addError("SQL Error executing statement: \(connection.errorMessage())", component: "SQLiteExecutor")
            LogManager.shared.addError("SQL: \(sql)", component: "SQLiteExecutor")
            return false
        }

        LogManager.shared.addLog("SQL statement executed successfully", component: "SQLiteExecutor")
        return true
    }

    func query(_ sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        LogManager.shared.addLog("Executing SQL query with \(parameters.count) parameters", component: "SQLiteExecutor")

        var statement: OpaquePointer?
        var results: [[String: Any]] = []

        guard sqlite3_prepare_v2(connection.db, sql, -1, &statement, nil) == SQLITE_OK else {
            LogManager.shared.addError("SQL Error preparing query: \(connection.errorMessage())", component: "SQLiteExecutor")
            LogManager.shared.addError("SQL: \(sql)", component: "SQLiteExecutor")
            return []
        }

        SQLiteBinder.bind(parameters: parameters, to: statement)

        while sqlite3_step(statement) == SQLITE_ROW {
            let row = SQLiteRowParser.parseRow(from: statement)
            results.append(row)
        }

        sqlite3_finalize(statement)

        LogManager.shared.addLog("SQL query returned \(results.count) rows", component: "SQLiteExecutor")
        return results
    }

    func lastInsertRowId() -> Int64 {
        let rowId = connection.lastInsertRowId()
        LogManager.shared.addLog("Last insert row ID: \(rowId)", component: "SQLiteExecutor")
        return rowId
    }
}
