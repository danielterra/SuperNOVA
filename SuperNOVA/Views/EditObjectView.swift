//
//  EditObjectView.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI
import Combine

struct EditObjectView: View {
    @Environment(\.dismiss) private var dismiss

    let entityClass: EntityClassModel
    let object: [String: Any]
    let onObjectUpdated: () -> Void

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var selectedStateId: String = ""
    @State private var propertyValues: [String: String] = [:]
    @State private var properties: [PropertyModel] = []
    @State private var states: [StateModel] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @State private var emojiCaptureHelper = EmojiCaptureHelper()
    @FocusState private var focusedField: ObjectField?

    enum ObjectField: Hashable {
        case name
    }

    private var isValid: Bool {
        !name.isEmpty && !selectedStateId.isEmpty
    }

    var body: some View {
        Form {
            // Icon Preview Section
            Section {
                HStack {
                    Spacer()
                    IconPreview(icon: icon, defaultIcon: entityClass.icon, size: 80)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Basic Information
            Section {
                TextField("Name", text: $name)
                    .focused($focusedField, equals: .name)

                IconPickerButton(
                    icon: $icon,
                    classIcon: entityClass.icon,
                    emojiCaptureHelper: emojiCaptureHelper,
                    focusedField: $focusedField
                )

                Picker("State", selection: $selectedStateId) {
                    Text("Select state...").tag("")
                    ForEach(states, id: \.id) { state in
                        HStack {
                            Circle()
                                .fill(stateColor(for: state.type))
                                .frame(width: 8, height: 8)
                            Text(state.name)
                        }
                        .tag(state.id)
                    }
                }
            } header: {
                Text("Basic Information")
            }

            // Custom Properties
            if !properties.isEmpty {
                Section("Properties") {
                    ForEach(properties, id: \.id) { property in
                        PropertyInputField(
                            property: property,
                            value: Binding(
                                get: { propertyValues[property.name] ?? "" },
                                set: { propertyValues[property.name] = $0 }
                            )
                        )
                    }
                }
            }

            // Footer
            Section {
                Text("Fields marked with * are required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit \(entityClass.name)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Save Changes") {
                    updateObject()
                }
                .disabled(!isValid)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Delete Object", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteObject()
            }
        } message: {
            Text("Are you sure you want to delete '\(name)'? This action cannot be undone.")
        }
        .onAppear {
            loadData()
        }
        .background {
            // Hidden emoji capture field
            EmojiCaptureView(capturedEmoji: $icon, helper: emojiCaptureHelper)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
    }

    private func loadData() {
        guard object["id"] as? String != nil else {
            return
        }

        properties = EntityClassManager.shared.getProperties(for: entityClass.id)
        states = EntityClassManager.shared.getStates(for: entityClass.id)

        // Load current object values
        name = object["name"] as? String ?? ""
        icon = object["icon"] as? String ?? ""
        selectedStateId = object["current_state_id"] as? String ?? ""

        // Load property values
        for property in properties {
            let columnName = SQLTypeConverter.sanitizeColumnName(property.name)
            if let value = object[columnName] {
                propertyValues[property.name] = formatValueForEditing(value, type: property.type)
            }
        }
    }

    private func formatValueForEditing(_ value: Any, type: PropertyType) -> String {
        if value is NSNull {
            return ""
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

        return "\(value)"
    }

    private func updateObject() {
        guard isValid else {
            return
        }

        guard let objectId = object["id"] as? String else {
            errorMessage = "Invalid object ID"
            showingError = true
            return
        }

        // Validate required properties
        for property in properties where property.isRequired {
            let value = propertyValues[property.name] ?? ""
            if value.isEmpty {
                errorMessage = "Property '\(property.name)' is required."
                showingError = true
                return
            }
        }

        // Convert property values to proper types
        var convertedValues: [String: Any] = [:]

        // Add basic fields
        convertedValues["name"] = name
        convertedValues["icon"] = icon.isEmpty ? NSNull() : icon
        convertedValues["current_state_id"] = selectedStateId

        // Add custom properties
        for property in properties {
            let stringValue = propertyValues[property.name] ?? ""

            if stringValue.isEmpty {
                // Empty value means we want to remove/null the field
                convertedValues[property.name] = NSNull()
                continue
            }

            switch property.type {
            case .number:
                if let intValue = Int(stringValue) {
                    convertedValues[property.name] = intValue
                } else {
                    convertedValues[property.name] = NSNull()
                }
            case .currency:
                if let doubleValue = Double(stringValue) {
                    convertedValues[property.name] = doubleValue
                } else {
                    convertedValues[property.name] = NSNull()
                }
            default:
                convertedValues[property.name] = stringValue
            }
        }

        if EntityObjectManager.shared.updateObject(
            classId: entityClass.id,
            objectId: objectId,
            propertyValues: convertedValues
        ) {
            onObjectUpdated()
            dismiss()
        } else {
            errorMessage = "Failed to update object. Please try again."
            showingError = true
        }
    }

    private func deleteObject() {
        guard let objectId = object["id"] as? String else {
            errorMessage = "Invalid object ID"
            showingError = true
            return
        }

        if EntityObjectManager.shared.deleteObject(classId: entityClass.id, objectId: objectId) {
            onObjectUpdated()
            dismiss()
        } else {
            errorMessage = "Failed to delete object. Please try again."
            showingError = true
        }
    }

    private func stateColor(for type: StateType) -> Color {
        switch type {
        case .active: return .green
        case .inactive: return .gray
        case .inProgress: return .orange
        }
    }
}

#Preview {
    NavigationStack {
        EditObjectView(
            entityClass: EntityClassModel(
                id: "1",
                name: "Person",
                icon: "😀",
                description: "A person",
                createdAt: Date(),
                updatedAt: Date()
            ),
            object: [
                "id": "123",
                "name": "John Doe",
                "icon": "👤",
                "current_state_id": "active"
            ]
        ) {}
    }
}
