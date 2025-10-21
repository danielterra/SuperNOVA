//
//  CreateObjectView.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI
import Combine

struct CreateObjectView: View {
    @Environment(\.dismiss) private var dismiss

    let entityClass: EntityClassModel
    let onObjectCreated: () -> Void

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var selectedStateId: String = ""
    @State private var propertyValues: [String: String] = [:]
    @State private var properties: [PropertyModel] = []
    @State private var states: [StateModel] = []
    @State private var showingError = false
    @State private var errorMessage = ""
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
                TextField("Name *", text: $name, prompt: Text("Object name"))
                    .focused($focusedField, equals: .name)

                IconPickerButton(
                    icon: $icon,
                    classIcon: entityClass.icon,
                    emojiCaptureHelper: emojiCaptureHelper,
                    focusedField: $focusedField
                )

                Picker("State *", selection: $selectedStateId) {
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
        .navigationTitle("New \(entityClass.name)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Create") {
                    createObject()
                }
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
        .background {
            // Hidden emoji capture field
            EmojiCaptureView(capturedEmoji: $icon, helper: emojiCaptureHelper)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
    }

    private func loadData() {
        LogManager.shared.addLog("Loading data for creating new \(entityClass.name)", component: "CreateObjectView")

        properties = EntityClassManager.shared.getProperties(for: entityClass.id)
        states = EntityClassManager.shared.getStates(for: entityClass.id)

        LogManager.shared.addLog("Loaded \(properties.count) properties and \(states.count) states", component: "CreateObjectView")

        // Set first state as default
        if let firstState = states.first {
            selectedStateId = firstState.id
            LogManager.shared.addLog("Default state set to '\(firstState.name)'", component: "CreateObjectView")
        }
    }

    private func createObject() {
        guard isValid else {
            LogManager.shared.addError("Cannot create object: validation failed", component: "CreateObjectView")
            return
        }

        LogManager.shared.addLog("Attempting to create new \(entityClass.name) object '\(name)'", component: "CreateObjectView")

        // Validate required properties
        for property in properties where property.isRequired {
            let value = propertyValues[property.name] ?? ""
            if value.isEmpty {
                errorMessage = "Property '\(property.name)' is required."
                showingError = true
                LogManager.shared.addError("Validation failed: required property '\(property.name)' is empty", component: "CreateObjectView")
                return
            }
        }

        // Convert property values to proper types
        var convertedValues: [String: Any] = [:]
        for property in properties {
            guard let stringValue = propertyValues[property.name], !stringValue.isEmpty else {
                continue
            }

            switch property.type {
            case .number:
                if let intValue = Int(stringValue) {
                    convertedValues[property.name] = intValue
                }
            case .currency:
                if let doubleValue = Double(stringValue) {
                    convertedValues[property.name] = doubleValue
                }
            default:
                convertedValues[property.name] = stringValue
            }
        }

        LogManager.shared.addLog("Converted \(convertedValues.count) property values", component: "CreateObjectView")

        // Use class icon if no custom icon set
        let finalIcon = icon.isEmpty ? entityClass.icon : icon

        if let objectId = EntityObjectManager.shared.createObject(
            classId: entityClass.id,
            name: name,
            icon: finalIcon,
            stateId: selectedStateId,
            propertyValues: convertedValues
        ) {
            LogManager.shared.addLog("Object created successfully with ID: \(objectId)", component: "CreateObjectView")
            onObjectCreated()
            dismiss()
        } else {
            errorMessage = "Failed to create object. Please try again."
            showingError = true
            LogManager.shared.addError("Failed to create object '\(name)'", component: "CreateObjectView")
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
        CreateObjectView(entityClass: EntityClassModel(
            id: "1",
            name: "Person",
            icon: "😀",
            description: "A person",
            createdAt: Date(),
            updatedAt: Date()
        )) {}
    }
}
