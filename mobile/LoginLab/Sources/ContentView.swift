//
//  ContentView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

enum LoginLabTab: Hashable {
  case home
  case acccount
}

struct ContentView: View {
  @State private var selectedTab = LoginLabTab.home

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(value: .home) {
        HomeView()
      } label: {
        Label("Home", systemImage: "house")
      }

      Tab(value: .acccount) {
        AccountView()
      } label: {
        Label("Account", systemImage: "person")
      }
    }
  }
}

#Preview {
  ContentView()
}
