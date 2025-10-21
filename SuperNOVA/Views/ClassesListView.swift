//
//  ClassesListView.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI

struct ClassesListView: View {
    @State private var classes: [EntityClassModel] = []
    @State private var showingCreateSheet = false
    @State private var navigationPath = NavigationPath()
    @State private var classToEdit: EntityClassModel?

    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if classes.isEmpty {
                    ContentUnavailableView(
                        "No Classes",
                        systemImage: "square.grid.2x2",
                        description: Text("Create your first class to start building your no-code platform")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(classes, id: \.id) { entityClass in
                                ClassCardView(
                                    entityClass: entityClass,
                                    onDelete: {
                                        deleteClass(entityClass)
                                    },
                                    onUpdate: {
                                        loadClasses()
                                    }
                                )
                                .id(entityClass.id) // Force refresh when class changes
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        loadClasses()
                    }
                }
            }
            .navigationTitle("Classes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("Create Class", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateClassView { newClass in
                    classes.append(newClass)
                    classToEdit = newClass
                }
            }
            .navigationDestination(item: $classToEdit) { entityClass in
                EditClassView(entityClass: entityClass) { updatedClass in
                    if let index = classes.firstIndex(where: { $0.id == updatedClass.id }) {
                        classes[index] = updatedClass
                    }
                    classToEdit = nil
                }
            }
        }
        .onAppear {
            loadClasses()
        }
    }

    private func loadClasses() {
        classes = EntityClassManager.shared.getAllEntityClasses()
    }

    private func deleteClass(_ entityClass: EntityClassModel) {
        if EntityClassManager.shared.deleteEntityClass(id: entityClass.id) {
            classes.removeAll { $0.id == entityClass.id }
        }
    }
}

struct ClassCardView: View {
    let entityClass: EntityClassModel
    let onDelete: () -> Void
    let onUpdate: () -> Void
    @State private var isHovering = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationLink(destination: ClassDetailView(entityClass: entityClass)
            .onDisappear {
                onUpdate()
            }
        ) {
            VStack(spacing: 12) {
                // Icon with prominent display
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)

                        if let icon = entityClass.icon {
                            Text(icon)
                                .font(.system(size: 48))
                        } else {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                    }

                    // Delete button (visible on hover)
                    if isHovering {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .offset(x: 8, y: -8)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // Name
                Text(entityClass.name)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                // Description with fixed height
                Group {
                    if let description = entityClass.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
                    } else {
                        Text(" ")
                            .font(.caption)
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovering ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: isHovering ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .alert("Delete Class", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(entityClass.name)'? This will also delete all objects of this class and cannot be undone.")
        }
    }
}

#Preview {
    ClassesListView()
}
