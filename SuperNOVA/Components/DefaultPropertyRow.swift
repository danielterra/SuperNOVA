//
//  DefaultPropertyRow.swift
//  SuperNOVA
//
//  Created by Daniel on 21/10/25.
//

import SwiftUI

struct DefaultPropertyRow: View {
    let name: String
    let type: String
    let required: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .cornerRadius(6)

            Text(type)
                .frame(width: 180, alignment: .leading)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .cornerRadius(6)

            if required {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("Required")
                }
                .font(.caption)
                .frame(width: 90, alignment: .leading)
            } else {
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
            }

            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
                .frame(width: 30)
        }
        .opacity(0.7)
    }
}
