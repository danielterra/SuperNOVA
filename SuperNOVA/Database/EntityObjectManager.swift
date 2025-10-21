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
        LogManager.shared.addLog("Fetching object \(objectId) from class \(classId)", component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let results = db.query("SELECT * FROM \(tableName) WHERE id = ?", parameters: [objectId])

        if let object = results.first {
            let name = object["name"] as? String ?? "Unknown"
            LogManager.shared.addLog("Object found: '\(name)' (ID: \(objectId))", component: "EntityObject")
            return object
        } else {
            LogManager.shared.addError("Object not found: \(objectId) in class \(classId)", component: "EntityObject")
            return nil
        }
    }

    func getAllObjects(classId: String, whereClause: String? = nil, parameters: [Any?] = []) -> [[String: Any]] {
        LogManager.shared.addLog("Fetching all objects from class \(classId)" + (whereClause != nil ? " with filter" : ""), component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        var sql = "SELECT * FROM \(tableName)"

        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        let results = db.query(sql, parameters: parameters)
        LogManager.shared.addLog("Retrieved \(results.count) objects from class \(classId)", component: "EntityObject")

        return results
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
        LogManager.shared.addLog("Executing custom query on class \(classId)", component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        let fullSql = sql.replacingOccurrences(of: "{table}", with: tableName)
        let results = db.query(fullSql, parameters: parameters)

        LogManager.shared.addLog("Custom query returned \(results.count) results", component: "EntityObject")
        return results
    }

    func executeRawSQL(_ sql: String, parameters: [Any?] = []) -> [[String: Any]] {
        LogManager.shared.addLog("Executing raw SQL query", component: "EntityObject")

        let results = db.query(sql, parameters: parameters)

        LogManager.shared.addLog("Raw SQL query returned \(results.count) results", component: "EntityObject")
        return results
    }

    // MARK: - Advanced Queries

    func getObjectsByState(classId: String, stateId: String) -> [[String: Any]] {
        LogManager.shared.addLog("Fetching objects by state \(stateId) from class \(classId)", component: "EntityObject")

        let results = getAllObjects(classId: classId, whereClause: "current_state_id = ?", parameters: [stateId])

        LogManager.shared.addLog("Found \(results.count) objects in state \(stateId)", component: "EntityObject")
        return results
    }

    func countObjects(classId: String, whereClause: String? = nil, parameters: [Any?] = []) -> Int {
        LogManager.shared.addLog("Counting objects in class \(classId)" + (whereClause != nil ? " with filter" : ""), component: "EntityObject")

        let tableName = SQLTypeConverter.generateTableName(for: classId)
        var sql = "SELECT COUNT(*) as count FROM \(tableName)"

        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        let results = db.query(sql, parameters: parameters)
        if let first = results.first, let count = first["count"] as? Int {
            LogManager.shared.addLog("Object count for class \(classId): \(count)", component: "EntityObject")
            return count
        }

        LogManager.shared.addError("Failed to count objects in class \(classId)", component: "EntityObject")
        return 0
    }

    func searchObjects(
        classId: String,
        propertyName: String,
        searchTerm: String,
        matchType: SearchMatchType = .contains
    ) -> [[String: Any]] {
        LogManager.shared.addLog("Searching objects in class \(classId) by \(propertyName) for '\(searchTerm)' (type: \(matchType))", component: "EntityObject")

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

        let results = getAllObjects(classId: classId, whereClause: whereClause, parameters: [searchValue])

        LogManager.shared.addLog("Search returned \(results.count) objects matching '\(searchTerm)'", component: "EntityObject")
        return results
    }
}

enum SearchMatchType {
    case exact
    case contains
    case startsWith
    case endsWith
}
