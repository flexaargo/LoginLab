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
  @Environment(\.userSession) private var userSession
  @State private var selectedTab = LoginLabTab.home

  private var isSignInPresented: Binding<Bool> {
    .init {
      userSession == nil
    } set: { _ in
      // NO OP
    }
  }

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
    .fullScreenCover(isPresented: isSignInPresented) {
      SignInView()
    }
  }
}

#Preview {
  ContentView()
}
