//
//  ClassDetailView.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI

enum ViewMode {
    case grid
    case table
}

struct ClassDetailView: View {
    @State var entityClass: EntityClassModel

    @State private var objects: [[String: Any]] = []
    @State private var properties: [PropertyModel] = []
    @State private var states: [StateModel] = []
    @State private var viewMode: ViewMode = .grid
    @State private var selectedObjectForEdit: ObjectWrapper?

    let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 20)
    ]

    private var viewModeKey: String {
        "viewMode_\(entityClass.id)"
    }

    private var savedViewMode: String {
        get {
            UserDefaults.standard.string(forKey: viewModeKey) ?? "grid"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: viewModeKey)
        }
    }

    var body: some View {
        Group {
            // Content
            if viewMode == .grid {
                if objects.isEmpty {
                    ContentUnavailableView(
                        "No Objects",
                        systemImage: "tray",
                        description: Text("Create your first object for this class")
                    )
                } else {
                    GridView(objects: objects, entityClass: entityClass, states: states, onObjectUpdated: loadData)
                }
            } else {
                TableView(
                    objects: objects,
                    properties: properties,
                    states: states,
                    classId: entityClass.id,
                    entityClass: entityClass,
                    onObjectUpdated: loadData,
                    onObjectSelected: { object in
                        selectedObjectForEdit = ObjectWrapper(data: object)
                    }
                )
            }
        }
        .sheet(item: $selectedObjectForEdit) { wrapper in
            NavigationStack {
                EditObjectView(entityClass: entityClass, object: wrapper.data) {
                    loadData()
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            // Leading - Class info
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 12) {
                    // Class icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)

                        if let icon = entityClass.icon {
                            Text(icon)
                                .font(.system(size: 20))
                        } else {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }

                    // Class name and object count
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entityClass.name)
                            .font(.headline)

                        Text("\(objects.count) \(objects.count == 1 ? "object" : "objects")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.trailing, 20)
            }

            // Center - View mode picker
            ToolbarItem(placement: .principal) {
                Picker("View Mode", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.table)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: viewMode) { oldValue, newValue in
                    UserDefaults.standard.set(newValue == .grid ? "grid" : "table", forKey: viewModeKey)
                }
            }

            // Trailing - Edit and New buttons
            ToolbarItem(placement: .automatic) {
                NavigationLink(destination: EditClassView(entityClass: entityClass) { updatedClass in
                    entityClass = updatedClass
                    loadData()
                }) {
                    Label("Edit Class", systemImage: "pencil")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: CreateObjectView(entityClass: entityClass) {
                    loadData()
                }) {
                    Label("New Object", systemImage: "plus")
                }
            }
        }
        .onAppear {
            // Restore saved view mode for this specific class
            let saved = UserDefaults.standard.string(forKey: viewModeKey) ?? "grid"
            viewMode = saved == "table" ? .table : .grid
            loadData()
        }
    }

    private func loadData() {
        properties = EntityClassManager.shared.getProperties(for: entityClass.id)
        states = EntityClassManager.shared.getStates(for: entityClass.id)
        objects = EntityObjectManager.shared.getAllObjects(classId: entityClass.id)
    }
}

// Wrapper to make dictionary Identifiable for sheet(item:)
struct ObjectWrapper: Identifiable {
    let id = UUID()
    let data: [String: Any]
}

#Preview {
    NavigationStack {
        ClassDetailView(entityClass: EntityClassModel(
            id: "1",
            name: "Person",
            icon: "😀",
            description: "A person",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
