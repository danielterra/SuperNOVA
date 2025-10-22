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
                .listRowBackground(Color.black)
            }

            // Basic Information
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name *")
                        .font(.headline)
                    TextField("", text: $name, prompt: Text("Object name"))
                        .pillTextFieldStyle()
                        .focused($focusedField, equals: .name)
                }
                .listRowBackground(Color.black)

                VStack(alignment: .leading, spacing: 8) {
                    IconPickerButton(
                        icon: $icon,
                        classIcon: entityClass.icon,
                        emojiCaptureHelper: emojiCaptureHelper,
                        focusedField: $focusedField
                    )
                }
                .listRowBackground(Color.black)

                VStack(alignment: .leading, spacing: 8) {
                    Text("State *")
                        .font(.headline)
                    Picker("", selection: $selectedStateId) {
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
                    .pillPickerStyle()
                }
                .listRowBackground(Color.black)
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
                        .listRowBackground(Color.black)
                    }
                }
            }

            // Footer
            Section {
                Text("Fields marked with * are required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.black)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("New \(entityClass.name)")
        .toolbarBackground(Color.black, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
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
        properties = EntityClassManager.shared.getProperties(for: entityClass.id)
        states = EntityClassManager.shared.getStates(for: entityClass.id)

        // Set first state as default
        if let firstState = states.first {
            selectedStateId = firstState.id
        }
    }

    private func createObject() {
        guard isValid else {
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

        // Use class icon if no custom icon set
        let finalIcon = icon.isEmpty ? entityClass.icon : icon

        if EntityObjectManager.shared.createObject(
            classId: entityClass.id,
            name: name,
            icon: finalIcon,
            stateId: selectedStateId,
            propertyValues: convertedValues
        ) != nil {
            onObjectCreated()
            dismiss()
        } else {
            errorMessage = "Failed to create object. Please try again."
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
