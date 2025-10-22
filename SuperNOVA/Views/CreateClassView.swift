//
//  CreateClassView.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI
import Combine

struct CreateClassView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = ""
    @State private var description = ""
    @State private var states: [StateItem] = [
        StateItem(name: "Inactive", type: .inactive),
        StateItem(name: "Active", type: .active),
        StateItem(name: "In Progress", type: .inProgress)
    ]
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: FormField?
    @State private var emojiCaptureHelper = EmojiCaptureHelper()

    let onClassCreated: (EntityClassModel) -> Void

    private var isValid: Bool {
        !name.isEmpty && !states.isEmpty && states.allSatisfy { !$0.name.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Class")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.black)

            Divider()

            // Form Content
            ZStack {
                // Hidden emoji capture field
                EmojiCaptureView(capturedEmoji: $icon, helper: emojiCaptureHelper)
                    .frame(width: 0, height: 0)
                    .opacity(0)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Icon Preview
                        IconPreview(icon: icon)
                            .padding(.top)

                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Class name", text: $name)
                                .pillTextFieldStyle()
                                .textContentType(.none)
                                .autocorrectionDisabled()
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
                        .padding(.bottom, 8)

                        // States Section
                        StatesListEditor(states: $states)

                        // Footer Text
                        Text("You can add custom properties after creating the class.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .background(Color.black)

            Divider()

            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create Class") {
                    createClass()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color.black)
        }
        .frame(width: 550, height: 700)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func createClass() {
        guard isValid else { return }

        let iconValue = icon.isEmpty ? nil : icon
        let descriptionValue = description.isEmpty ? nil : description

        if let classId = EntityClassManager.shared.createEntityClass(
            name: name,
            icon: iconValue,
            description: descriptionValue
        ) {
            // Create states for the class
            for (index, state) in states.enumerated() {
                _ = EntityClassManager.shared.createState(
                    entityClassId: classId,
                    name: state.name,
                    type: state.type,
                    order: index
                )
            }

            if let newClass = EntityClassManager.shared.getEntityClass(id: classId) {
                onClassCreated(newClass)
                dismiss()
            }
        } else {
            errorMessage = "Failed to create class. Please try again."
            showingError = true
        }
    }
}

#Preview {
    CreateClassView { _ in }
}
