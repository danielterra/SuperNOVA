//
//  EntityObjectManager.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class EntityObjectManager {
    static let shared = EntityObjectManager()
    private let db = SQLiteDatabase.shared

    private init() {}

    // MARK: - CRUD Operations

    func createObject(
        classId: String,
        name: String,
        icon: String?,
        stateId: String,
        propertyValues: [String: Any] = [:]
    ) -> String? {
        LogManager.shared.addLog("Creating object '\(name)' in class \(classId) with state \(stateId)", component: "EntityObject")

        let id = UUID().uuidString
        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let now = Date().timeIntervalSince1970

        var columns = ["id", "name", "icon", "current_state_id", "created_at", "updated_at"]
        var placeholders = ["?", "?", "?", "?", "?", "?"]
        var parameters: [Any?] = [id, name, icon, stateId, now, now]

        for (propertyName, value) in propertyValues {
            let sanitizedName = SQLTypeConverter.sanitizeColumnName(propertyName)
            columns.append(sanitizedName)
            placeholders.append("?")
            parameters.append(SQLTypeConverter.convertValue(value))
        }

        let sql = """
            INSERT INTO \(tableName) (\(columns.joined(separator: ", ")))
            VALUES (\(placeholders.joined(separator: ", ")))
        """

        let success = db.execute(sql, parameters: parameters)

        if success {
            LogManager.shared.addLog("Object created successfully: '\(name)' (ID: \(id)) with \(propertyValues.count) properties", component: "EntityObject")
        } else {
            LogManager.shared.addError("Failed to create object '\(name)' in class \(classId)", component: "EntityObject")
        }

        return success ? id : nil
    }

    func getObject(classId: String, objectId: String) -> [String: Any]? {
        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let results = db.query("SELECT * FROM \(tableName) WHERE id = ?", parameters: [objectId])
        return results.first
    }

    func getAllObjects(classId: String, whereClause: String? = nil, parameters: [Any?] = []) -> [[String: Any]] {
        let tableName = SQLTypeConverter.generateTableName(for: classId)
        var sql = "SELECT * FROM \(tableName)"

        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        return db.query(sql, parameters: parameters)
    }

    func updateObject(
        classId: String,
        objectId: String,
        propertyValues: [String: Any]
    ) -> Bool {
        LogManager.shared.addLog("Updating object \(objectId) in class \(classId) with \(propertyValues.count) properties", component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let now = Date().timeIntervalSince1970

        var updates: [String] = []
        var parameters: [Any?] = []

        for (propertyName, value) in propertyValues {
            let sanitizedName = SQLTypeConverter.sanitizeColumnName(propertyName)
            updates.append("\(sanitizedName) = ?")
            parameters.append(SQLTypeConverter.convertValue(value))
        }

        updates.append("updated_at = ?")
        parameters.append(now)
        parameters.append(objectId)

        let sql = """
            UPDATE \(tableName) SET \(updates.joined(separator: ", ")) WHERE id = ?
        """

        let success = db.execute(sql, parameters: parameters)

        if success {
            LogManager.shared.addLog("Object updated successfully: \(objectId)", component: "EntityObject")
        } else {
            LogManager.shared.addError("Failed to update object \(objectId) in class \(classId)", component: "EntityObject")
        }

        return success
    }

    func updateObjectState(classId: String, objectId: String, newStateId: String) -> Bool {
        LogManager.shared.addLog("Updating state for object \(objectId) to \(newStateId)", component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let now = Date().timeIntervalSince1970

        let success = db.execute("""
            UPDATE \(tableName) SET current_state_id = ?, updated_at = ? WHERE id = ?
        """, parameters: [newStateId, now, objectId])

        if success {
            LogManager.shared.addLog("Object state updated successfully: \(objectId)", component: "EntityObject")
        } else {
            LogManager.shared.addError("Failed to update state for object \(objectId)", component: "EntityObject")
        }

        return success
    }

    func deleteObject(classId: String, objectId: String) -> Bool {
        LogManager.shared.addLog("Deleting object \(objectId) from class \(classId)", component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let success = db.execute("DELETE FROM \(tableName) WHERE id = ?", parameters: [objectId])

        if success {
            LogManager.shared.addLog("Object deleted successfully: \(objectId)", component: "EntityObject")
        } else {
            LogManager.shared.addError("Failed to delete object \(objectId) from class \(classId)", component: "EntityObject")
        }

        return success
    }

    // MARK: - Query Helpers

    func queryObjects(classId: String, sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let fullSql = sql.replacingOccurrences(of: "{table}", with: tableName)
        return db.query(fullSql, parameters: parameters)
    }

    func executeRawSQL(_ sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        return db.query(sql, parameters: parameters)
    }

    // MARK: - Advanced Queries

    func getObjectsByState(classId: String, stateId: String) -> [[String: Any]] {
        return getAllObjects(classId: classId, whereClause: "current_state_id = ?", parameters: [stateId])
    }

    func countObjects(classId: String, whereClause: String? = nil, parameters: [Any?] = []) -> Int {
        let tableName = SQLTypeConverter.generateTableName(for: classId)
        var sql = "SELECT COUNT(*) as count FROM \(tableName)"

        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        let results = db.query(sql, parameters: parameters)
        if let first = results.first, let count = first["count"] as? Int {
            return count
        }

        return 0
    }

    func searchObjects(
        classId: String,
        propertyName: String,
        searchTerm: String,
        matchType: SearchMatchType = .contains
    ) -> [[String: Any]] {
        let sanitizedName = SQLTypeConverter.sanitizeColumnName(propertyName)
        let whereClause: String
        let searchValue: String

        switch matchType {
        case .exact:
            whereClause = "\(sanitizedName) = ?"
            searchValue = searchTerm
        case .contains:
            whereClause = "\(sanitizedName) LIKE ?"
            searchValue = "%\(searchTerm)%"
        case .startsWith:
            whereClause = "\(sanitizedName) LIKE ?"
            searchValue = "\(searchTerm)%"
        case .endsWith:
            whereClause = "\(sanitizedName) LIKE ?"
            searchValue = "%\(searchTerm)"
        }

        return getAllObjects(classId: classId, whereClause: whereClause, parameters: [searchValue])
    }
}

enum SearchMatchType {
    case exact
    case contains
    case startsWith
    case endsWith
}
