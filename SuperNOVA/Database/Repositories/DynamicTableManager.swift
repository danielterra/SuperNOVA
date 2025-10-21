//
//  DynamicTableManager.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class DynamicTableManager {
    static let shared = DynamicTableManager()
    private let db: SQLiteDatabase

    init(db: SQLiteDatabase = .shared) {
        self.db = db
    }

    func createTable(for classId: String, className: String) {
        let tableName = generateTableName(for: classId)

        let sql = """
            CREATE TABLE IF NOT EXISTS \(tableName) (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT,
                current_state_id TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            )
        """

        db.execute(sql)
        LogManager.shared.addLog("📊 Created dynamic table: \(tableName) for class: \(className)", component: "DynamicTableManager")
    }

    func dropTable(for classId: String) {
        let tableName = generateTableName(for: classId)
        db.execute("DROP TABLE IF EXISTS \(tableName)")
    }

    func addColumn(classId: String, property: PropertyModel) {
        let tableName = generateTableName(for: classId)
        let columnType = mapToSQLType(property.type)
        let notNull = property.isRequired ? "NOT NULL" : ""
        let columnName = sanitizeColumnName(property.name)

        let sql = """
            ALTER TABLE \(tableName) ADD COLUMN \(columnName) \(columnType) \(notNull)
        """

        db.execute(sql)
    }

    func removeColumn(classId: String, columnName: String) {
        // SQLite doesn't support DROP COLUMN directly
        // Would need to recreate table without the column
        LogManager.shared.addLog("⚠️ Column removal not yet implemented", component: "DynamicTableManager", severity: .warning)
    }

    func generateTableName(for classId: String) -> String {
        return "entity_\(classId.replacingOccurrences(of: "-", with: "_"))"
    }

    private func sanitizeColumnName(_ name: String) -> String {
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
    }

    private func mapToSQLType(_ propertyType: PropertyType) -> String {
        switch propertyType {
        case .text, .datetime, .date, .duration, .location, .referenceUnique:
            return "TEXT"
        case .number:
            return "INTEGER"
        case .currency:
            return "REAL"
        case .images, .files, .audios, .referenceMultiple:
            return "TEXT" // Store as JSON array
        }
    }
}
