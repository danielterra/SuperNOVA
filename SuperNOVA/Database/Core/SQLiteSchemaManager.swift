//
//  SQLiteSchemaManager.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import Foundation

class SQLiteSchemaManager {
    private let executor: SQLiteExecutor

    init(executor: SQLiteExecutor) {
        self.executor = executor
    }

    func createMetadataTables() {
        createEntityClassTable()
        createPropertyTable()
        createStateTable()
        createActionTable()
        createActionAllowedStateTable()
        runMigrations()
        print("✅ Metadata tables created")
    }

    private func runMigrations() {
        // Migration 1: Check if state table has type column
        let stateColumns = executor.query("PRAGMA table_info(state)")
        let hasTypeColumn = stateColumns.contains { row in
            (row["name"] as? String) == "type"
        }

        if !hasTypeColumn {
            print("🔄 Running migration: Adding 'type' column to state table...")
            executor.execute("ALTER TABLE state ADD COLUMN type TEXT NOT NULL DEFAULT 'inactive'")
            print("✅ Migration completed")
        }

        // Migration 2: Add name and icon columns to existing dynamic tables
        let classes = executor.query("SELECT id FROM entity_class")
        for classRow in classes {
            guard let classId = classRow["id"] as? String else { continue }
            let tableName = "entity_\(classId.replacingOccurrences(of: "-", with: "_"))"

            // Check if table exists
            let tableExists = executor.query("SELECT name FROM sqlite_master WHERE type='table' AND name=?", parameters: [tableName])
            if tableExists.isEmpty { continue }

            let columns = executor.query("PRAGMA table_info(\(tableName))")
            let hasNameColumn = columns.contains { row in
                (row["name"] as? String) == "name"
            }
            let hasIconColumn = columns.contains { row in
                (row["name"] as? String) == "icon"
            }

            if !hasNameColumn {
                print("🔄 Running migration: Adding 'name' column to \(tableName)...")
                executor.execute("ALTER TABLE \(tableName) ADD COLUMN name TEXT NOT NULL DEFAULT 'Unnamed'")
                print("✅ Migration completed")
            }

            if !hasIconColumn {
                print("🔄 Running migration: Adding 'icon' column to \(tableName)...")
                executor.execute("ALTER TABLE \(tableName) ADD COLUMN icon TEXT")
                print("✅ Migration completed")
            }
        }
    }

    private func createEntityClassTable() {
        executor.execute("""
            CREATE TABLE IF NOT EXISTS entity_class (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT,
                description TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            )
        """)
    }

    private func createPropertyTable() {
        executor.execute("""
            CREATE TABLE IF NOT EXISTS property (
                id TEXT PRIMARY KEY,
                entity_class_id TEXT NOT NULL,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                is_required INTEGER NOT NULL DEFAULT 0,
                order_index INTEGER NOT NULL DEFAULT 0,
                reference_target_class_id TEXT,
                FOREIGN KEY (entity_class_id) REFERENCES entity_class(id) ON DELETE CASCADE
            )
        """)
    }

    private func createStateTable() {
        executor.execute("""
            CREATE TABLE IF NOT EXISTS state (
                id TEXT PRIMARY KEY,
                entity_class_id TEXT NOT NULL,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                icon TEXT,
                color TEXT,
                order_index INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (entity_class_id) REFERENCES entity_class(id) ON DELETE CASCADE
            )
        """)
    }

    private func createActionTable() {
        executor.execute("""
            CREATE TABLE IF NOT EXISTS action (
                id TEXT PRIMARY KEY,
                entity_class_id TEXT NOT NULL,
                name TEXT NOT NULL,
                icon TEXT,
                description TEXT,
                trigger_type TEXT NOT NULL,
                order_index INTEGER NOT NULL DEFAULT 0,
                trigger_state_id TEXT,
                FOREIGN KEY (entity_class_id) REFERENCES entity_class(id) ON DELETE CASCADE
            )
        """)
    }

    private func createActionAllowedStateTable() {
        executor.execute("""
            CREATE TABLE IF NOT EXISTS action_allowed_state (
                action_id TEXT NOT NULL,
                state_id TEXT NOT NULL,
                PRIMARY KEY (action_id, state_id),
                FOREIGN KEY (action_id) REFERENCES action(id) ON DELETE CASCADE,
                FOREIGN KEY (state_id) REFERENCES state(id) ON DELETE CASCADE
            )
        """)
    }
}
