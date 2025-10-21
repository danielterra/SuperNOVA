//
//  EditPropertiesListEditor.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct EditPropertiesListEditor: View {
    @Binding var properties: [PropertyItem]
    let availableClasses: [EntityClassModel]

    var body: some View {
        VStack(spacing: 0) {
            // Properties Header
            HStack {
                Text("Properties")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    properties.append(PropertyItem(id: "", name: "", type: .text, isRequired: false))
                } label: {
                    Label("Add Property", systemImage: "plus")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Default properties (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Properties")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)

                        DefaultPropertyRow(name: "name", type: "Text", required: true)
                        DefaultPropertyRow(name: "icon", type: "Text", required: false)
                        DefaultPropertyRow(name: "created_at", type: "Date & Time", required: true)
                        DefaultPropertyRow(name: "updated_at", type: "Date & Time", required: true)
                    }
                    .padding(.bottom, 12)

                    if !properties.isEmpty {
                        Divider()

                        Text("Custom Properties")
                            .font(.headline)
                            .padding(.top, 8)
                    }

                    // Custom properties
                    ForEach(properties.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Property name", text: $properties[index].name)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Type")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $properties[index].type) {
                                        ForEach(PropertyType.allCases, id: \.self) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .frame(width: 180)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(" ")
                                        .font(.caption)
                                    Toggle("Required", isOn: $properties[index].isRequired)
                                        .toggleStyle(.checkbox)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(" ")
                                        .font(.caption)
                                    Button {
                                        properties.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Reference class selector (only for reference types)
                            if properties[index].type == .referenceUnique || properties[index].type == .referenceMultiple {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reference Class")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("Select class", selection: $properties[index].referenceTargetClassId) {
                                        Text("Select class...").tag(nil as String?)
                                        ForEach(availableClasses, id: \.id) { availableClass in
                                            Text("\(availableClass.icon ?? "") \(availableClass.name)")
                                                .tag(availableClass.id as String?)
                                        }
                                    }
                                    .frame(width: 250)
                                }
                            }

                            Divider()
                        }
                    }

                    Text("Default properties are automatically included and cannot be modified.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
    }
}
