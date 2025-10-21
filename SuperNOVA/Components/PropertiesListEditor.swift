//
//  PropertiesListEditor.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct PropertiesListEditor: View {
    @Binding var properties: [PropertyItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Properties")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    properties.append(PropertyItem(name: "", type: .text, isRequired: false))
                } label: {
                    Label("Add Property", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                // Default properties (read-only)
                Group {
                    DefaultPropertyRow(name: "name", type: "Text", required: true)
                    DefaultPropertyRow(name: "icon", type: "Text", required: false)
                    DefaultPropertyRow(name: "created_at", type: "Date & Time", required: true)
                    DefaultPropertyRow(name: "updated_at", type: "Date & Time", required: true)
                }
                .opacity(0.7)

                // Divider between default and custom properties
                if !properties.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                }

                // Custom properties (editable)
                ForEach(properties.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            TextField("Property name", text: $properties[index].name)
                                .textFieldStyle(.roundedBorder)

                            Picker("", selection: $properties[index].type) {
                                ForEach(PropertyType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .frame(width: 150)

                            Toggle("Required", isOn: $properties[index].isRequired)
                                .toggleStyle(.checkbox)
                                .frame(width: 80)

                            Button {
                                properties.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Text("Default properties (name, icon, created_at, updated_at) are automatically included and cannot be modified.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
