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
    @State private var selection = Set<Log.ID>()

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List(logs, selection: $selection) { log in
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
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .onChange(of: logs.count) { oldValue, newValue in
                    if let firstLog = logs.first {
                        withAnimation {
                            proxy.scrollTo(firstLog.id, anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("Server Logs")
            .toolbarBackground(Color.black, for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if !selection.isEmpty {
                        Button(action: copySelectedLogs) {
                            Label("Copy \(selection.count) log\(selection.count == 1 ? "" : "s")", systemImage: "doc.on.doc")
                        }
                        .keyboardShortcut("c", modifiers: .command)
                    }
                }
            }
        }
    }

    private func copySelectedLogs() {
        let selectedLogs = logs.filter { selection.contains($0.id) }

        // Sort by timestamp (oldest first for readability when pasted)
        let sortedLogs = selectedLogs.sorted { $0.timestamp < $1.timestamp }

        // Format logs as text
        let logText = sortedLogs.map { log in
            let timeString = log.timestamp.formatted(date: .omitted, time: .standard)
            let severityPrefix = log.severity == .error ? "[ERROR] " : ""
            return "\(timeString) \(severityPrefix)\(log.message)"
        }.joined(separator: "\n")

        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logText, forType: .string)
    }
}

#Preview {
    LogsView()
        .modelContainer(for: Log.self, inMemory: true)
}
