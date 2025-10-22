//
//  ContentView.swift
//  SuperNOVA
//
//  Created by Daniel on 20/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
