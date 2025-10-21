//
//  EmojiPicker.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Character Extension

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

// MARK: - Emoji Capture Helper

class EmojiCaptureHelper: ObservableObject {
    @Published var isCapturing = false
    var onEmojiCaptured: ((String) -> Void)?

    func startCapturing() {
        isCapturing = true
    }

    func captureEmoji(_ emoji: String) {
        onEmojiCaptured?(emoji)
        isCapturing = false
    }
}

// MARK: - Emoji Capture View

struct EmojiCaptureView: NSViewRepresentable {
    @Binding var capturedEmoji: String
    @ObservedObject var helper: EmojiCaptureHelper

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if helper.isCapturing {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: EmojiCaptureView

        init(_ parent: EmojiCaptureView) {
            self.parent = parent
            super.init()
            self.parent.helper.onEmojiCaptured = { [weak self] emoji in
                self?.parent.capturedEmoji = emoji
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                let stringValue = textField.stringValue

                if let text = stringValue.last, text.isEmoji {
                    parent.helper.captureEmoji(String(text))
                    textField.stringValue = ""
                }
            }
        }
    }
}
