//
//  EditClassView.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI
import Combine

struct EditClassView: View {
    @Environment(\.dismiss) private var dismiss

    let entityClass: EntityClassModel
    let onClassUpdated: (EntityClassModel) -> Void

    @State private var name: String
    @State private var icon: String
    @State private var description: String
    @State private var states: [StateItem] = []
    @State private var properties: [PropertyItem] = []
    @State private var availableClasses: [EntityClassModel] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: FormField?
    @State private var emojiCaptureHelper = EmojiCaptureHelper()

    init(entityClass: EntityClassModel, onClassUpdated: @escaping (EntityClassModel) -> Void) {
        self.entityClass = entityClass
        self.onClassUpdated = onClassUpdated
        _name = State(initialValue: entityClass.name)
        _icon = State(initialValue: entityClass.icon ?? "")
        _description = State(initialValue: entityClass.description ?? "")
    }

    private var isValid: Bool {
        !name.isEmpty && !states.isEmpty && states.allSatisfy { !$0.name.isEmpty }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Column - Basic Info and States (40%)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Icon Preview
                        IconPreview(icon: icon)

                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)

                            TextField("Class name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
                        }

                        // Icon Field
                        IconPickerButton(
                            icon: $icon,
                            classIcon: nil,
                            emojiCaptureHelper: emojiCaptureHelper,
                            focusedField: $focusedField
                        )

                        // Description Field
                        DescriptionEditor(
                            description: $description,
                            focusedField: $focusedField,
                            fieldIdentifier: FormField.description
                        )

                        // States Section
                        StatesListEditor(states: $states)
                    }
                    .padding()
                }

                // Hidden emoji capture field
                EmojiCaptureView(capturedEmoji: $icon, helper: emojiCaptureHelper)
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right Column - Properties (60%)
            EditPropertiesListEditor(
                properties: $properties,
                availableClasses: availableClasses
            )
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Edit Class")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save Changes") {
                    updateClass()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        LogManager.shared.addLog("Loading data for editing class '\(entityClass.name)' (ID: \(entityClass.id))", component: "EditClassView")

        let existingStates = EntityClassManager.shared.getStates(for: entityClass.id)
        states = existingStates.map { state in
            StateItem(id: state.id, name: state.name, type: state.type)
        }

        let existingProperties = EntityClassManager.shared.getProperties(for: entityClass.id)
        properties = existingProperties.map { property in
            PropertyItem(
                id: property.id,
                name: property.name,
                type: property.type,
                isRequired: property.isRequired,
                isLongText: property.isLongText,
                referenceTargetClassId: property.referenceTargetClassId
            )
        }

        availableClasses = EntityClassManager.shared.getAllEntityClasses()

        LogManager.shared.addLog("Loaded \(states.count) states, \(properties.count) properties, and \(availableClasses.count) available classes", component: "EditClassView")
    }

    private func updateClass() {
        guard isValid else {
            LogManager.shared.addError("Cannot update class: validation failed", component: "EditClassView")
            return
        }

        LogManager.shared.addLog("Attempting to update class '\(name)' (ID: \(entityClass.id))", component: "EditClassView")

        let iconValue = icon.isEmpty ? nil : icon
        let descriptionValue = description.isEmpty ? nil : description

        let success = EntityClassManager.shared.updateEntityClass(
            id: entityClass.id,
            name: name,
            icon: iconValue,
            description: descriptionValue
        )

        if success {
            LogManager.shared.addLog("Class basic info updated successfully", component: "EditClassView")

            // Create new states
            let newStates = states.filter { $0.id.isEmpty }
            for state in newStates {
                let stateId = EntityClassManager.shared.createState(
                    entityClassId: entityClass.id,
                    name: state.name,
                    type: state.type,
                    order: states.firstIndex(where: { $0.id == state.id }) ?? 0
                )
                if stateId != nil {
                    LogManager.shared.addLog("Created new state: '\(state.name)'", component: "EditClassView")
                }
            }

            // Create new properties
            for (index, property) in properties.enumerated() where property.id.isEmpty && !property.name.isEmpty {
                let propertyId = EntityClassManager.shared.createProperty(
                    entityClassId: entityClass.id,
                    name: property.name,
                    type: property.type,
                    isRequired: property.isRequired,
                    isLongText: property.isLongText,
                    order: index,
                    referenceTargetClassId: property.referenceTargetClassId
                )
                if propertyId != nil {
                    LogManager.shared.addLog("Created new property: '\(property.name)' with order \(index)", component: "EditClassView")
                }
            }

            // Update existing properties
            for (index, property) in properties.enumerated() where !property.id.isEmpty {
                _ = EntityClassManager.shared.updateProperty(
                    propertyId: property.id,
                    name: property.name,
                    type: property.type,
                    isRequired: property.isRequired,
                    isLongText: property.isLongText,
                    referenceTargetClassId: property.referenceTargetClassId
                )
                _ = EntityClassManager.shared.updatePropertyOrder(propertyId: property.id, newOrder: index)
            }

            if let updatedClass = EntityClassManager.shared.getEntityClass(id: entityClass.id) {
                LogManager.shared.addLog("Class update completed successfully: '\(name)'", component: "EditClassView")
                onClassUpdated(updatedClass)
                dismiss()
            } else {
                LogManager.shared.addError("Failed to retrieve updated class after update", component: "EditClassView")
            }
        } else {
            errorMessage = "Failed to update class. Please try again."
            showingError = true
            LogManager.shared.addError("Failed to update class '\(name)' (ID: \(entityClass.id))", component: "EditClassView")
        }
    }
}

#Preview {
    EditClassView(entityClass: EntityClassModel(
        id: "1",
        name: "Person",
        icon: "😀",
        description: "A person",
        createdAt: Date(),
        updatedAt: Date()
    )) { _ in }
}
