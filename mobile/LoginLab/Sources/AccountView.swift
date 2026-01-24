//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct AccountView: View {
  @Environment(\.accountDetails) private var accountDetails

  var body: some View {
    if let accountDetails {
      NavigationStack {
        Form {
          Section("Name") {
            Text(accountDetails.name)
          }

          Section("Email") {
            Text(accountDetails.email)
          }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("Account")
        .toolbarTitleDisplayMode(.inlineLarge)
      }
    }
  }
}

#Preview {
  AccountView()
}
