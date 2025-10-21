//
//  ActionRepository.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class ActionRepository {
    private let db: SQLiteDatabase

    init(db: SQLiteDatabase = .shared) {
        self.db = db
    }

    func create(
        entityClassId: String,
        name: String,
        icon: String? = nil,
        description: String? = nil,
        triggerType: ActionTriggerType = .manual,
        order: Int = 0,
        triggerStateId: String? = nil,
        allowedStateIds: [String] = []
    ) -> String? {
        let id = UUID().uuidString

        let success = db.execute("""
            INSERT INTO action (id, entity_class_id, name, icon, description, trigger_type, order_index, trigger_state_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, parameters: [id, entityClassId, name, icon, description, triggerType.rawValue, order, triggerStateId])

        if success {
            for stateId in allowedStateIds {
                db.execute("""
                    INSERT INTO action_allowed_state (action_id, state_id) VALUES (?, ?)
                """, parameters: [id, stateId])
            }
            return id
        }

        return nil
    }

    func getAll(for entityClassId: String) -> [ActionModel] {
        let results = db.query("""
            SELECT * FROM action WHERE entity_class_id = ? ORDER BY order_index
        """, parameters: [entityClassId])

        return results.map { row in
            let actionId = row["id"] as! String
            let allowedStateIds = getAllowedStateIds(for: actionId)
            return mapToModel(row: row, allowedStateIds: allowedStateIds)
        }
    }

    func delete(id: String) -> Bool {
        return db.execute("DELETE FROM action WHERE id = ?", parameters: [id])
    }

    private func getAllowedStateIds(for actionId: String) -> [String] {
        let allowedStates = db.query("""
            SELECT state_id FROM action_allowed_state WHERE action_id = ?
        """, parameters: [actionId])

        return allowedStates.map { $0["state_id"] as! String }
    }

    private func mapToModel(row: [String: Any], allowedStateIds: [String]) -> ActionModel {
        return ActionModel(
            id: row["id"] as! String,
            entityClassId: row["entity_class_id"] as! String,
            name: row["name"] as! String,
            icon: row["icon"] as? String,
            description: row["description"] as? String,
            triggerType: ActionTriggerType(rawValue: row["trigger_type"] as! String)!,
            order: row["order_index"] as! Int,
            triggerStateId: row["trigger_state_id"] as? String,
            allowedStateIds: allowedStateIds
        )
    }
}
