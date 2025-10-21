//
//  LogsView.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI
import SwiftData

struct LogsView: View {
    @Query(sort: \Log.timestamp, order: .reverse) private var logs: [Log]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List(logs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)

                            Spacer()

                            if log.severity == .error {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption2)
                            }
                        }

                        Text(log.message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(log.severity == .error ? .red : .primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 2)
                    .id(log.id)
                }
                .listStyle(.plain)
                .onChange(of: logs.count) { oldValue, newValue in
                    if let firstLog = logs.first {
                        withAnimation {
                            proxy.scrollTo(firstLog.id, anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("Server Logs")
        }
    }
}

#Preview {
    LogsView()
        .modelContainer(for: Log.self, inMemory: true)
}
