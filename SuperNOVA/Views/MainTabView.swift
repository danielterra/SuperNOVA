//
//  MainTabView.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI

enum NavigationItem: String, CaseIterable {
    case logs = "Logs"
    case classes = "Classes"

    var icon: String {
        switch self {
        case .logs: return "list.bullet.rectangle"
        case .classes: return "square.grid.2x2"
        }
    }
}

struct MainTabView: View {
    @State private var selectedItem: NavigationItem? = .classes

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, id: \.self, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("SuperNOVA")
            .frame(minWidth: 200)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        } detail: {
            switch selectedItem {
            case .logs:
                LogsView()
            case .classes, .none:
                ClassesListView()
            }
        }
        .background(Color.black)
    }
}

#Preview {
    MainTabView()
}
