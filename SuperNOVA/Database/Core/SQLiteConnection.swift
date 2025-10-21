//
//  SQLiteConnection.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation
import SQLite3

class SQLiteConnection {
    private(set) var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.supernova.database", qos: .userInitiated)
    private(set) var databasePath: String = ""

    init() {
        openDatabase()
    }

    deinit {
        closeDatabase()
    }

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("supernova.sqlite")

        databasePath = fileURL.path

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }

        // Enable foreign keys
        _ = executeRaw("PRAGMA foreign_keys = ON")

        print("✅ Database opened at: \(fileURL.path)")
    }

    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing database")
        }
        db = nil
    }

    func executeRaw(_ sql: String) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        let result = sqlite3_step(statement)
        sqlite3_finalize(statement)
        return result == SQLITE_DONE || result == SQLITE_ROW
    }

    func lastInsertRowId() -> Int64 {
        return sqlite3_last_insert_rowid(db)
    }

    func errorMessage() -> String {
        return String(cString: sqlite3_errmsg(db))
    }
}
