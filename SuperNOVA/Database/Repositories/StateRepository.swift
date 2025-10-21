//
//  StateRepository.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class StateRepository {
    private let db: SQLiteDatabase

    init(db: SQLiteDatabase = .shared) {
        self.db = db
    }

    func create(
        entityClassId: String,
        name: String,
        type: StateType,
        icon: String? = nil,
        color: String? = nil,
        order: Int = 0
    ) -> String? {
        let id = UUID().uuidString

        let success = db.execute("""
            INSERT INTO state (id, entity_class_id, name, type, icon, color, order_index)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, parameters: [id, entityClassId, name, type.rawValue, icon, color, order])

        return success ? id : nil
    }

    func getAll(for entityClassId: String) -> [StateModel] {
        let results = db.query("""
            SELECT * FROM state WHERE entity_class_id = ? ORDER BY order_index
        """, parameters: [entityClassId])

        return results.map { mapToModel(row: $0) }
    }

    func delete(id: String) -> Bool {
        return db.execute("DELETE FROM state WHERE id = ?", parameters: [id])
    }

    private func mapToModel(row: [String: Any]) -> StateModel {
        return StateModel(
            id: row["id"] as! String,
            entityClassId: row["entity_class_id"] as! String,
            name: row["name"] as! String,
            type: StateType(rawValue: row["type"] as! String) ?? .inactive,
            icon: row["icon"] as? String,
            color: row["color"] as? String,
            order: row["order_index"] as! Int
        )
    }
}
