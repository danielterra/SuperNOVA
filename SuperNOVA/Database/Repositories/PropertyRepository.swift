//
//  PropertyRepository.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class PropertyRepository {
    private let db: SQLiteDatabase
    private let dynamicTableManager: DynamicTableManager

    init(db: SQLiteDatabase = .shared, dynamicTableManager: DynamicTableManager = .shared) {
        self.db = db
        self.dynamicTableManager = dynamicTableManager
    }

    func create(
        entityClassId: String,
        name: String,
        type: PropertyType,
        isRequired: Bool = false,
        order: Int = 0,
        referenceTargetClassId: String? = nil
    ) -> String? {
        let id = UUID().uuidString

        let success = db.execute("""
            INSERT INTO property (id, entity_class_id, name, type, is_required, order_index, reference_target_class_id)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, parameters: [id, entityClassId, name, type.rawValue, isRequired, order, referenceTargetClassId])

        if success {
            let property = PropertyModel(
                id: id,
                entityClassId: entityClassId,
                name: name,
                type: type,
                isRequired: isRequired,
                order: order,
                referenceTargetClassId: referenceTargetClassId
            )
            dynamicTableManager.addColumn(classId: entityClassId, property: property)
            return id
        }

        return nil
    }

    func getAll(for entityClassId: String) -> [PropertyModel] {
        let results = db.query("""
            SELECT * FROM property WHERE entity_class_id = ? ORDER BY order_index
        """, parameters: [entityClassId])

        return results.map { mapToModel(row: $0) }
    }

    func updateOrder(propertyId: String, newOrder: Int) -> Bool {
        return db.execute("""
            UPDATE property SET order_index = ? WHERE id = ?
        """, parameters: [newOrder, propertyId])
    }

    func delete(id: String) -> Bool {
        return db.execute("DELETE FROM property WHERE id = ?", parameters: [id])
    }

    private func mapToModel(row: [String: Any]) -> PropertyModel {
        return PropertyModel(
            id: row["id"] as! String,
            entityClassId: row["entity_class_id"] as! String,
            name: row["name"] as! String,
            type: PropertyType(rawValue: row["type"] as! String)!,
            isRequired: (row["is_required"] as! Int) == 1,
            order: row["order_index"] as! Int,
            referenceTargetClassId: row["reference_target_class_id"] as? String
        )
    }
}
