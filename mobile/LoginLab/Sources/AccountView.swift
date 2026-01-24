//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct AccountView: View {
  var body: some View {
    NavigationStack {
      Form {}
        .navigationTitle("Account")
        .toolbarTitleDisplayMode(.inlineLarge)
    }
  }
}

#Preview {
  AccountView()
}
