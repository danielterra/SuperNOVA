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
            TextField(label, text: $value, prompt: Text("Enter \(property.name.lowercased())"))

        case .number:
            TextField(label, text: $value, prompt: Text("Enter number"))
                .onChange(of: value) { oldValue, newValue in
                    // Only allow numbers
                    let filtered = newValue.filter { $0.isNumber || $0 == "-" }
                    if filtered != newValue {
                        value = filtered
                    }
                }

        case .currency:
            TextField(label, text: $value, prompt: Text("Enter amount"))
                .onChange(of: value) { oldValue, newValue in
                    // Only allow numbers and decimal point
                    let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "-" }
                    if filtered != newValue {
                        value = filtered
                    }
                }

        case .date:
            DatePicker(label, selection: $dateValue, displayedComponents: [.date])
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

        case .datetime:
            DatePicker(label, selection: $dateValue, displayedComponents: [.date, .hourAndMinute])
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

        case .duration:
            TextField(label, text: $value, prompt: Text("e.g., 2h 30m"))

        case .location:
            TextField(label, text: $value, prompt: Text("Enter location"))

        case .images, .files, .audios:
            TextField(label, text: $value, prompt: Text("Enter file paths"))

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
