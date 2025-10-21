//
//  ObjectGridView.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct GridView: View {
    let objects: [[String: Any]]
    let entityClass: EntityClassModel
    let states: [StateModel]
    let onObjectUpdated: () -> Void

    let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(objects.enumerated()), id: \.offset) { index, object in
                    ObjectGridCard(object: object, entityClass: entityClass, states: states, onObjectUpdated: onObjectUpdated)
                }
            }
            .padding()
        }
    }
}

struct ObjectGridCard: View {
    let object: [String: Any]
    let entityClass: EntityClassModel
    let states: [StateModel]
    let onObjectUpdated: () -> Void

    @State private var isHovering = false
    @State private var showingDeleteAlert = false

    private var objectName: String {
        return (object["name"] as? String) ?? "Unnamed"
    }

    private var objectIcon: String? {
        // Use object's icon if set, otherwise use class icon
        if let icon = object["icon"] as? String, !icon.isEmpty {
            return icon
        }
        return entityClass.icon
    }

    private var currentState: StateModel? {
        guard let stateId = object["current_state_id"] as? String else { return nil }
        return states.first { $0.id == stateId }
    }

    var body: some View {
        NavigationLink(destination: EditObjectView(entityClass: entityClass, object: object, onObjectUpdated: onObjectUpdated)) {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)

                if let icon = objectIcon {
                    Text(icon)
                        .font(.system(size: 32))
                } else {
                    Image(systemName: "doc")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }

            // Name
            Text(objectName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // State badge
            if let state = currentState {
                Text(state.name)
                    .font(.system(size: 9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(stateColor(for: state.type).opacity(0.2))
                    .foregroundColor(stateColor(for: state.type))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .frame(width: 120, height: 120)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: isHovering ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isHovering {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(4)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        }
        .buttonStyle(.plain)
        .alert("Delete Object", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteObject()
            }
        } message: {
            Text("Are you sure you want to delete '\(objectName)'? This action cannot be undone.")
        }
    }

    private func deleteObject() {
        guard let objectId = object["id"] as? String else {
            LogManager.shared.addError("Cannot delete object: invalid object ID", component: "ObjectGridCard")
            return
        }

        let objectName = object["name"] as? String ?? "Unknown"
        LogManager.shared.addLog("Attempting to delete object '\(objectName)' (ID: \(objectId))", component: "ObjectGridCard")

        if EntityObjectManager.shared.deleteObject(classId: entityClass.id, objectId: objectId) {
            LogManager.shared.addLog("Object deleted successfully from grid view: '\(objectName)'", component: "ObjectGridCard")
            onObjectUpdated()
        } else {
            LogManager.shared.addError("Failed to delete object '\(objectName)' (ID: \(objectId))", component: "ObjectGridCard")
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
