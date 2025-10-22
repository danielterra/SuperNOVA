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
        isLongText: Bool = false,
        order: Int = 0,
        referenceTargetClassId: String? = nil
    ) -> String? {
        let id = UUID().uuidString

        let success = db.execute("""
            INSERT INTO property (id, entity_class_id, name, type, is_required, is_long_text, order_index, reference_target_class_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, parameters: [id, entityClassId, name, type.rawValue, isRequired, isLongText, order, referenceTargetClassId])

        if success {
            let property = PropertyModel(
                id: id,
                entityClassId: entityClassId,
                name: name,
                type: type,
                isRequired: isRequired,
                isLongText: isLongText,
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

    func update(
        propertyId: String,
        name: String? = nil,
        type: PropertyType? = nil,
        isRequired: Bool? = nil,
        isLongText: Bool? = nil,
        referenceTargetClassId: String? = nil
    ) -> Bool {
        // Get current property to preserve values not being updated
        let current = db.query("SELECT * FROM property WHERE id = ?", parameters: [propertyId])
        guard let row = current.first else { return false }

        let finalName = name ?? (row["name"] as! String)
        let finalType = type?.rawValue ?? (row["type"] as! String)
        let finalIsRequired = isRequired ?? ((row["is_required"] as! Int) == 1)
        let finalIsLongText = isLongText ?? ((row["is_long_text"] as! Int) == 1)
        let finalReferenceTargetClassId = referenceTargetClassId ?? (row["reference_target_class_id"] as? String)

        return db.execute("""
            UPDATE property
            SET name = ?, type = ?, is_required = ?, is_long_text = ?, reference_target_class_id = ?
            WHERE id = ?
        """, parameters: [finalName, finalType, finalIsRequired, finalIsLongText, finalReferenceTargetClassId, propertyId])
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
            isLongText: (row["is_long_text"] as! Int) == 1,
            order: row["order_index"] as! Int,
            referenceTargetClassId: row["reference_target_class_id"] as? String
        )
    }
}
