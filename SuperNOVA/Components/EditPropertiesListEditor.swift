//
//  EditPropertiesListEditor.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct EditPropertiesListEditor: View {
    @Binding var properties: [PropertyItem]
    let availableClasses: [EntityClassModel]
    @State private var draggedProperty: PropertyItem?

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

            ScrollView(.vertical, showsIndicators: true) {
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

                    // Custom properties (with drag & drop reordering)
                    ForEach(properties) { property in
                        if let index = properties.firstIndex(where: { $0.id == property.id }) {
                            PropertyRow(
                                property: $properties[index],
                                availableClasses: availableClasses,
                                onDelete: {
                                    withAnimation {
                                        if let idx = properties.firstIndex(where: { $0.id == property.id }) {
                                            properties.remove(at: idx)
                                        }
                                    }
                                }
                            )
                            .opacity(draggedProperty?.id == property.id ? 0.5 : 1.0)
                            .onDrag {
                                self.draggedProperty = property
                                return NSItemProvider(object: property.id as NSString)
                            }
                            .onDrop(of: [.text], delegate: PropertyDropDelegate(
                                destinationProperty: property,
                                properties: $properties,
                                draggedProperty: $draggedProperty
                            ))
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

// Drop delegate for drag & drop reordering
struct PropertyDropDelegate: DropDelegate {
    let destinationProperty: PropertyItem
    @Binding var properties: [PropertyItem]
    @Binding var draggedProperty: PropertyItem?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedProperty = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedProperty = self.draggedProperty,
              draggedProperty.id != destinationProperty.id,
              let fromIndex = properties.firstIndex(where: { $0.id == draggedProperty.id }),
              let toIndex = properties.firstIndex(where: { $0.id == destinationProperty.id }) else {
            return
        }

        withAnimation(.default) {
            properties.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}

// Property row component
struct PropertyRow: View {
    @Binding var property: PropertyItem
    let availableClasses: [EntityClassModel]
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.trailing, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Property name", text: $property.name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $property.type) {
                        ForEach(PropertyType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .frame(width: 180)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(" ")
                        .font(.caption)
                    Toggle("Required", isOn: $property.isRequired)
                        .toggleStyle(.checkbox)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(" ")
                        .font(.caption)
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Reference class selector (only for reference types)
            if property.type == .referenceUnique || property.type == .referenceMultiple {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reference Class")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Select class", selection: $property.referenceTargetClassId) {
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
}
