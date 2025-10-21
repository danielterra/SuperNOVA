//
//  ReferenceFieldPicker.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct ReferenceFieldPicker: View {
    let property: PropertyModel
    @Binding var selectedId: String
    @State private var searchText = ""
    @State private var objects: [[String: Any]] = []
    @State private var targetClass: EntityClassModel?
    @State private var showingCreateSheet = false
    @State private var isExpanded = false

    private var filteredObjects: [[String: Any]] {
        if searchText.isEmpty {
            return objects
        }
        return objects.filter { object in
            if let name = object["name"] as? String {
                return name.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }

    private var selectedObjectName: String {
        if selectedId.isEmpty {
            return "Select \(property.name.lowercased())..."
        }
        if let object = objects.first(where: { ($0["id"] as? String) == selectedId }),
           let name = object["name"] as? String {
            return name
        }
        return "Select \(property.name.lowercased())..."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            HStack {
                Text(property.name + (property.isRequired ? " *" : ""))
                Spacer()
                if !selectedId.isEmpty {
                    Button(action: {
                        selectedId = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Selected object display / Search trigger
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    if let object = objects.first(where: { ($0["id"] as? String) == selectedId }) {
                        if let icon = object["icon"] as? String {
                            Text(icon)
                                .font(.system(size: 16))
                        }
                        Text(object["name"] as? String ?? "Unknown")
                            .foregroundColor(.primary)
                    } else {
                        Text(selectedObjectName)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Expanded search and list
            if isExpanded {
                VStack(spacing: 8) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search by name...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

                    Divider()

                    // Create new button
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Create New \(targetClass?.name ?? "Object")")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    // Objects list
                    ScrollView {
                        VStack(spacing: 4) {
                            if filteredObjects.isEmpty {
                                Text("No objects found")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(Array(filteredObjects.enumerated()), id: \.offset) { _, object in
                                    if let objectId = object["id"] as? String {
                                        Button(action: {
                                            selectedId = objectId
                                            isExpanded = false
                                            searchText = ""
                                        }) {
                                            HStack {
                                                if let icon = object["icon"] as? String {
                                                    Text(icon)
                                                        .font(.system(size: 16))
                                                }
                                                Text(object["name"] as? String ?? "Unknown")
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                if selectedId == objectId {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(8)
                                            .background(selectedId == objectId ? Color.blue.opacity(0.1) : Color.clear)
                                            .cornerRadius(4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingCreateSheet) {
            if let targetClass = targetClass {
                NavigationStack {
                    CreateObjectView(entityClass: targetClass) {
                        // Reload objects after creation
                        loadData()
                        // Select the newly created object (last in the list)
                        if let lastObject = objects.last,
                           let lastId = lastObject["id"] as? String {
                            selectedId = lastId
                        }
                    }
                }
            }
        }
    }

    private func loadData() {
        guard let targetClassId = property.referenceTargetClassId else { return }

        // Load target class
        if let entityClass = EntityClassManager.shared.getEntityClass(id: targetClassId) {
            targetClass = entityClass
        }

        // Load objects from target class
        objects = EntityObjectManager.shared.getAllObjects(classId: targetClassId)
    }
}
