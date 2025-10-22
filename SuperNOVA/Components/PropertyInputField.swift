//
//  PropertyInputField.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct PropertyInputField: View {
    let property: PropertyModel
    @Binding var value: String
    @State private var dateValue: Date = Date()

    private var label: String {
        var label = property.name
        if property.isRequired {
            label += " *"
        }
        return label
    }

    var body: some View {
        switch property.type {
        case .text:
            if property.isLongText {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $value)
                        .frame(minHeight: 100)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .pillTextEditorStyle()
                }
            } else {
                TextField(label, text: $value, prompt: Text("Enter \(property.name.lowercased())"))
                    .pillTextFieldStyle()
            }

        case .number:
            TextField(label, text: $value, prompt: Text("Enter number"))
                .pillTextFieldStyle()
                .onChange(of: value) { oldValue, newValue in
                    // Only allow numbers
                    let filtered = newValue.filter { $0.isNumber || $0 == "-" }
                    if filtered != newValue {
                        value = filtered
                    }
                }

        case .currency:
            TextField(label, text: $value, prompt: Text("Enter amount"))
                .pillTextFieldStyle()
                .onChange(of: value) { oldValue, newValue in
                    // Only allow numbers and decimal point
                    let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "-" }
                    if filtered != newValue {
                        value = filtered
                    }
                }

        case .date:
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.headline)
                DatePicker("", selection: $dateValue, displayedComponents: [.date])
                    .labelsHidden()
                    .pillPickerStyle()
                    .onChange(of: dateValue) { oldValue, newValue in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        value = formatter.string(from: newValue)
                    }
                    .onAppear {
                        if !value.isEmpty, let date = parseDate(value) {
                            dateValue = date
                        }
                    }
            }

        case .datetime:
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.headline)
                DatePicker("", selection: $dateValue, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .pillPickerStyle()
                    .onChange(of: dateValue) { oldValue, newValue in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm"
                        value = formatter.string(from: newValue)
                    }
                    .onAppear {
                        if !value.isEmpty, let date = parseDateTime(value) {
                            dateValue = date
                        }
                    }
            }

        case .duration:
            TextField(label, text: $value, prompt: Text("e.g., 2h 30m"))
                .pillTextFieldStyle()

        case .location:
            TextField(label, text: $value, prompt: Text("Enter location"))
                .pillTextFieldStyle()

        case .images, .files, .audios:
            TextField(label, text: $value, prompt: Text("Enter file paths"))
                .pillTextFieldStyle()

        case .referenceUnique, .referenceMultiple:
            ReferenceFieldPicker(property: property, selectedId: $value)
        }
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    private func parseDateTime(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)
    }
}
