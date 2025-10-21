//
//  ObjectTableView.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct TableObjectRow: Identifiable {
    let id: String
    let name: String
    let icon: String
    let state: String
    let stateColor: Color
    let createdAt: String
    let updatedAt: String
    let properties: [String: String]
}

struct TableView: View {
    let objects: [[String: Any]]
    let properties: [PropertyModel]
    let states: [StateModel]
    let classId: String
    let entityClass: EntityClassModel
    let onObjectUpdated: () -> Void

    @State private var selection = Set<String>()
    @State private var selectedObject: [String: Any]?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @AppStorage private var columnCustomization: TableColumnCustomization<TableObjectRow>

    init(objects: [[String: Any]], properties: [PropertyModel], states: [StateModel], classId: String, entityClass: EntityClassModel, onObjectUpdated: @escaping () -> Void) {
        self.objects = objects
        self.properties = properties
        self.states = states
        self.classId = classId
        self.entityClass = entityClass
        self.onObjectUpdated = onObjectUpdated

        // Use class-specific key for column customization
        let key = "tableColumnCustomization_\(classId)"

        // Check if we need to reset customization (for adding checkbox column with new ID)
        let resetKey = "tableColumnCustomization_reset_v4_\(classId)"
        if !UserDefaults.standard.bool(forKey: resetKey) {
            // Reset old customization to ensure checkbox is first with proper ordering
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.set(true, forKey: resetKey)
            LogManager.shared.addLog("Reset column customization for class: \(classId)", component: "TableView")
        }

        self._columnCustomization = AppStorage(wrappedValue: TableColumnCustomization<TableObjectRow>(), key)
    }

    private var tableRows: [TableObjectRow] {
        objects.map { object in
            let objectId = object["id"] as? String ?? ""
            let name = object["name"] as? String ?? "-"
            let objectIcon = object["icon"] as? String ?? ""
            let icon = objectIcon.isEmpty ? (entityClass.icon ?? "") : objectIcon

            let stateId = object["current_state_id"] as? String ?? ""
            let state = states.first(where: { $0.id == stateId })
            let stateName = state?.name ?? "-"
            let stateColor = state != nil ? self.stateColor(for: state!.type) : .gray

            let createdAt = formatDate(object["created_at"])
            let updatedAt = formatDate(object["updated_at"])

            var propertyValues: [String: String] = [:]
            for property in properties {
                let columnName = SQLTypeConverter.sanitizeColumnName(property.name)
                let value = object[columnName]
                propertyValues[property.name] = formatValue(value, property: property)
            }

            return TableObjectRow(
                id: objectId,
                name: name,
                icon: icon,
                state: stateName,
                stateColor: stateColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                properties: propertyValues
            )
        }
    }

    private var checkboxColumn: some TableColumnContent<TableObjectRow, Never> {
        TableColumn("☑") { (row: TableObjectRow) in
            Toggle("", isOn: Binding(
                get: { selection.contains(row.id) },
                set: { isSelected in
                    if isSelected {
                        selection.insert(row.id)
                    } else {
                        selection.remove(row.id)
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
        }
        .width(30)
        .customizationID("_00_checkbox")
    }

    private var nameColumn: some TableColumnContent<TableObjectRow, Never> {
        TableColumn("Name") { row in
            Text(row.name)
        }
        .customizationID("name")
    }

    private var iconColumn: some TableColumnContent<TableObjectRow, Never> {
        TableColumn("Icon") { row in
            Text(row.icon)
                .font(.title3)
        }
        .customizationID("icon")
    }

    private var stateColumn: some TableColumnContent<TableObjectRow, Never> {
        TableColumn("State") { row in
            HStack {
                Circle()
                    .fill(row.stateColor)
                    .frame(width: 8, height: 8)
                Text(row.state)
            }
        }
        .customizationID("state")
    }

    private var createdAtColumn: some TableColumnContent<TableObjectRow, Never> {
        TableColumn("Created At") { row in
            Text(row.createdAt)
        }
        .customizationID("createdAt")
    }

    private var updatedAtColumn: some TableColumnContent<TableObjectRow, Never> {
        TableColumn("Updated At") { row in
            Text(row.updatedAt)
        }
        .customizationID("updatedAt")
    }

    private var dynamicPropertyColumns: some TableColumnContent<TableObjectRow, Never> {
        TableColumnForEach(properties) { property in
            TableColumn(property.name) { row in
                Text(row.properties[property.name] ?? "-")
            }
            .customizationID("prop_\(property.id)")
        }
    }

    private var tableContent: some View {
        Table(tableRows, selection: $selection, columnCustomization: $columnCustomization) {
            checkboxColumn
            nameColumn
            iconColumn
            stateColumn
            createdAtColumn
            updatedAtColumn
            dynamicPropertyColumns
        }
            .tableColumnHeaders(.visible)
            .onChange(of: columnCustomization) { oldValue, newValue in
                LogManager.shared.addLog("📊 Column customization changed for class: \(classId)", component: "TableView")

                // Try to log column order if accessible
                if let data = try? JSONEncoder().encode(newValue),
                   let jsonString = String(data: data, encoding: .utf8) {
                    LogManager.shared.addLog("   Customization JSON: \(jsonString)", component: "TableView")
                } else {
                    LogManager.shared.addLog("   New customization: \(String(describing: newValue))", component: "TableView")
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if !selection.isEmpty {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete Selected", systemImage: "trash")
                        }
                        .help("Delete \(selection.count) selected \(selection.count == 1 ? "object" : "objects")")
                    }
                }
            }
            .onTapGesture {
                // Double click to edit - handled by row click
            }
            .contextMenu(forSelectionType: String.self) { selectedIds in
                if selectedIds.count == 1, let selectedId = selectedIds.first {
                    Button("Edit") {
                        if let object = objects.first(where: { $0["id"] as? String == selectedId }) {
                            selectedObject = object
                            showingEditSheet = true
                        }
                    }
                    Divider()
                }

                Button("Delete", role: .destructive) {
                    selection = selectedIds
                    showingDeleteAlert = true
                }
            } primaryAction: { selectedIds in
                // Double-click action
                if selectedIds.count == 1, let selectedId = selectedIds.first {
                    if let object = objects.first(where: { $0["id"] as? String == selectedId }) {
                        selectedObject = object
                        showingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let object = selectedObject {
                    NavigationStack {
                        EditObjectView(entityClass: entityClass, object: object) {
                            onObjectUpdated()
                        }
                    }
                }
            }
            .alert("Delete Objects", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteSelectedObjects()
                }
            } message: {
                Text("Are you sure you want to delete \(selection.count) \(selection.count == 1 ? "object" : "objects")? This action cannot be undone.")
            }
    }

    var body: some View {
        if objects.isEmpty {
            ContentUnavailableView(
                "No Objects",
                systemImage: "tray",
                description: Text("Create your first object for this class")
            )
        } else {
            tableContent
        }
    }

    private func deleteSelectedObjects() {
        LogManager.shared.addLog("Deleting \(selection.count) selected objects from table view", component: "TableView")

        var successCount = 0
        for objectId in selection {
            if EntityObjectManager.shared.deleteObject(classId: classId, objectId: objectId) {
                successCount += 1
            }
        }

        if successCount == selection.count {
            LogManager.shared.addLog("Successfully deleted \(successCount) objects from table view", component: "TableView")
        } else {
            LogManager.shared.addError("Deleted \(successCount) of \(selection.count) objects - some deletions failed", component: "TableView")
        }

        selection.removeAll()
        onObjectUpdated()
    }

    private func stateColor(for type: StateType) -> Color {
        switch type {
        case .active: return .green
        case .inactive: return .gray
        case .inProgress: return .orange
        }
    }

    private func formatDate(_ value: Any?) -> String {
        guard let timestamp = value as? Double else {
            return "-"
        }

        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatValue(_ value: Any?, property: PropertyModel) -> String {
        if value == nil || value is NSNull {
            return "-"
        }

        // Handle reference types - fetch the referenced object name
        if property.type == .referenceUnique || property.type == .referenceMultiple {
            if let referenceId = value as? String,
               !referenceId.isEmpty,
               let targetClassId = property.referenceTargetClassId,
               let referencedObject = EntityObjectManager.shared.getObject(classId: targetClassId, objectId: referenceId) {

                let name = referencedObject["name"] as? String ?? "Unknown"
                let icon = referencedObject["icon"] as? String ?? ""
                return icon.isEmpty ? name : "\(icon) \(name)"
            }
            return "-"
        }

        if let stringValue = value as? String {
            return stringValue
        }

        if let intValue = value as? Int {
            return "\(intValue)"
        }

        if let doubleValue = value as? Double {
            return String(format: "%.2f", doubleValue)
        }

        return "\(value!)"
    }
}
