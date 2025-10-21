//
//  SQLiteBinder.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation
import SQLite3

class SQLiteBinder {
    static func bind(parameters: [Any?], to statement: OpaquePointer?) {
        for (index, param) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)

            if param == nil || param is NSNull {
                sqlite3_bind_null(statement, bindIndex)
            } else if let intValue = param as? Int {
                sqlite3_bind_int64(statement, bindIndex, Int64(intValue))
            } else if let doubleValue = param as? Double {
                sqlite3_bind_double(statement, bindIndex, doubleValue)
            } else if let stringValue = param as? String {
                sqlite3_bind_text(statement, bindIndex, (stringValue as NSString).utf8String, -1, nil)
            } else if let dataValue = param as? Data {
                _ = dataValue.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, bindIndex, bytes.baseAddress, Int32(dataValue.count), nil)
                }
            } else if let boolValue = param as? Bool {
                sqlite3_bind_int(statement, bindIndex, boolValue ? 1 : 0)
            }
        }
    }
}
