//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct AccountView: View {
  @Environment(\.userSession) private var userSession

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
