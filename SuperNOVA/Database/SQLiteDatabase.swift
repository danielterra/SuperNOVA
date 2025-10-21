//
//  SQLiteDatabase.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class SQLiteDatabase {
    static let shared = SQLiteDatabase()

    private let connection: SQLiteConnection
    private let executor: SQLiteExecutor
    private let schemaManager: SQLiteSchemaManager

    private init() {
        connection = SQLiteConnection()
        executor = SQLiteExecutor(connection: connection)
        schemaManager = SQLiteSchemaManager(executor: executor)
        schemaManager.createMetadataTables()
    }

    @discardableResult
    func execute(_ sql: String, parameters: [Any?] = []) -> Bool {
        return executor.execute(sql, parameters: parameters)
    }

    func query(_ sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        return executor.query(sql, parameters: parameters)
    }

    func lastInsertRowId() -> Int64 {
        return executor.lastInsertRowId()
    }

    func getDatabasePath() -> String {
        return connection.databasePath
    }
}
