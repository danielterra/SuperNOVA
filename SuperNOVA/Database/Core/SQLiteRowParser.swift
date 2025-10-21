//
//  SQLiteRowParser.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation
import SQLite3

class SQLiteRowParser {
    static func parseRow(from statement: OpaquePointer?) -> [String: Any] {
        var row: [String: Any] = [:]
        let columnCount = sqlite3_column_count(statement)

        for i in 0..<columnCount {
            let columnName = String(cString: sqlite3_column_name(statement, i))
            let columnType = sqlite3_column_type(statement, i)

            switch columnType {
            case SQLITE_INTEGER:
                row[columnName] = Int(sqlite3_column_int64(statement, i))
            case SQLITE_FLOAT:
                row[columnName] = sqlite3_column_double(statement, i)
            case SQLITE_TEXT:
                if let cString = sqlite3_column_text(statement, i) {
                    row[columnName] = String(cString: cString)
                }
            case SQLITE_BLOB:
                if let blob = sqlite3_column_blob(statement, i) {
                    let size = sqlite3_column_bytes(statement, i)
                    row[columnName] = Data(bytes: blob, count: Int(size))
                }
            case SQLITE_NULL:
                row[columnName] = NSNull()
            default:
                break
            }
        }

        return row
    }
}
