//
//  FormComponents.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

// MARK: - Icon Preview

struct IconPreview: View {
    let icon: String?
    let defaultIcon: String?
    let size: CGFloat

    init(icon: String?, defaultIcon: String? = nil, size: CGFloat = 100) {
        self.icon = icon
        self.defaultIcon = defaultIcon
        self.size = size
    }

    var body: some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: size, height: size)

                if let icon = icon, !icon.isEmpty {
                    Text(icon)
                        .font(.system(size: size * 0.6))
                } else if let defaultIcon = defaultIcon {
                    Text(defaultIcon)
                        .font(.system(size: size * 0.6))
                        .opacity(0.5)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: size * 0.48))
                        .foregroundColor(.blue.opacity(0.5))
                }
            }
            Spacer()
        }
    }
}

// MARK: - Icon Picker Button

struct IconPickerButton<Field: Hashable>: View {
    @Binding var icon: String
    let classIcon: String?
    let emojiCaptureHelper: EmojiCaptureHelper
    var focusedField: FocusState<Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon (emoji)")
                .font(.headline)

            HStack(spacing: 8) {
                Button {
                    openEmojiPicker()
                } label: {
                    HStack {
                        if icon.isEmpty {
                            if let classIcon = classIcon {
                                Text(classIcon)
                                    .font(.title3)
                                    .opacity(0.5)
                                Text("Use class icon or change...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select emoji...")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(icon)
                                .font(.title3)
                            Text("Change")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "face.smiling")
                            .foregroundColor(.blue)
                    }
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if !icon.isEmpty {
                    Button {
                        icon = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Clear emoji")
                }
            }
        }
    }

    private func openEmojiPicker() {
        focusedField.wrappedValue = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emojiCaptureHelper.startCapturing()
            NSApp.orderFrontCharacterPalette(nil)
        }
    }
}

// MARK: - Description Editor

struct DescriptionEditor<Field: Hashable>: View {
    @Binding var description: String
    var focusedField: FocusState<Field?>.Binding
    let fieldIdentifier: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused(focusedField, equals: fieldIdentifier)
                    .padding(4)

                if description.isEmpty {
                    Text("Optional description...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - States List Editor

struct StatesListEditor: View {
    @Binding var states: [StateItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("States")
                    .font(.headline)

                Spacer()

                Button {
                    states.append(StateItem(name: "", type: .inactive))
                } label: {
                    Label("Add State", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                ForEach(states.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        TextField("State name", text: $states[index].name)
                            .textFieldStyle(.roundedBorder)

                        Picker("", selection: $states[index].type) {
                            Text("Inactive").tag(StateType.inactive)
                            Text("Active").tag(StateType.active)
                            Text("In Progress").tag(StateType.inProgress)
                        }
                        .frame(width: 130)

                        Button {
                            states.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(states.count == 1)
                    }
                }
            }

            Text("At least one state is required.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
