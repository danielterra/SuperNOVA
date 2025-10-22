//
//  TextFieldStyles.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

// MARK: - Pill TextField Style

struct PillTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - View Extension

extension View {
    func pillTextFieldStyle() -> some View {
        self.textFieldStyle(PillTextFieldStyle())
    }

    func pillTextEditorStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    func pillPickerStyle() -> some View {
        self
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)
    }
}
