//
//  EntityClassRepository.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class EntityClassRepository {
    private let db: SQLiteDatabase
    private let dynamicTableManager: DynamicTableManager

    init(db: SQLiteDatabase = .shared, dynamicTableManager: DynamicTableManager = .shared) {
        self.db = db
        self.dynamicTableManager = dynamicTableManager
    }

    func create(name: String, icon: String? = nil, description: String? = nil) -> String? {
        let id = UUID().uuidString
        let now = Date().timeIntervalSince1970

        let success = db.execute("""
            INSERT INTO entity_class (id, name, icon, description, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, parameters: [id, name, icon, description, now, now])

        if success {
            dynamicTableManager.createTable(for: id, className: name)
            LogManager.shared.addLog("✅ Class created: '\(name)' \(icon ?? "")", component: "EntityClass")
            return id
        } else {
            LogManager.shared.addError("❌ Failed to create class: '\(name)'", component: "EntityClass")
        }

        return nil
    }

    func get(id: String) -> EntityClassModel? {
        let results = db.query("SELECT * FROM entity_class WHERE id = ?", parameters: [id])
        guard let row = results.first else { return nil }

        return mapToModel(row: row)
    }

    func getAll() -> [EntityClassModel] {
        let results = db.query("SELECT * FROM entity_class ORDER BY name")
        return results.map { mapToModel(row: $0) }
    }

    func update(id: String, name: String? = nil, icon: String? = nil, description: String? = nil) -> Bool {
        var updates: [String] = []
        var parameters: [Any?] = []
        var changes: [String] = []

        if let name = name {
            updates.append("name = ?")
            parameters.append(name)
            changes.append("name to '\(name)'")
        }

        if icon != nil {
            updates.append("icon = ?")
            parameters.append(icon)
            changes.append("icon to '\(icon ?? "none")'")
        }

        if description != nil {
            updates.append("description = ?")
            parameters.append(description)
            changes.append("description")
        }

        guard !updates.isEmpty else { return false }

        updates.append("updated_at = ?")
        parameters.append(Date().timeIntervalSince1970)
        parameters.append(id)

        let success = db.execute("""
            UPDATE entity_class SET \(updates.joined(separator: ", ")) WHERE id = ?
        """, parameters: parameters)

        if success {
            let className = get(id: id)?.name ?? "Unknown"
            LogManager.shared.addLog("✏️ Class updated: '\(className)' - Changed: \(changes.joined(separator: ", "))", component: "EntityClass")
        } else {
            LogManager.shared.addError("❌ Failed to update class with id: \(id)", component: "EntityClass")
        }

        return success
    }

    func delete(id: String) -> Bool {
        // Get class name before deleting for logging
        let className = get(id: id)?.name ?? "Unknown"
        let icon = get(id: id)?.icon ?? ""

        dynamicTableManager.dropTable(for: id)
        let success = db.execute("DELETE FROM entity_class WHERE id = ?", parameters: [id])

        if success {
            LogManager.shared.addLog("🗑️ Class deleted: '\(className)' \(icon)", component: "EntityClass")
        } else {
            LogManager.shared.addError("❌ Failed to delete class: '\(className)'", component: "EntityClass")
        }

        return success
    }

    private func mapToModel(row: [String: Any]) -> EntityClassModel {
        return EntityClassModel(
            id: row["id"] as! String,
            name: row["name"] as! String,
            icon: row["icon"] as? String,
            description: row["description"] as? String,
            createdAt: Date(timeIntervalSince1970: row["created_at"] as! Double),
            updatedAt: Date(timeIntervalSince1970: row["updated_at"] as! Double)
        )
    }
}
