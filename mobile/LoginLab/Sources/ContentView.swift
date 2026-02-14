//
//  ContentView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct ContentView: View {
  @Environment(SessionManager.self) private var sessionManager
  @State private var isAccountSheetPresented = false

  var body: some View {
    HomeView {
      isAccountSheetPresented = true
    }
    .sheet(isPresented: $isAccountSheetPresented) {
      AccountView()
    }
    .onChange(of: sessionManager.isAuthenticated) { _, isAuthenticated in
      if !isAuthenticated {
        isAccountSheetPresented = false
      }
    }
  }
}

#Preview {
  ContentView()
}
