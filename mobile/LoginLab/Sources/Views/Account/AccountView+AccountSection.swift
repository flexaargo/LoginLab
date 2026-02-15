//
//  AccountView+AccountSection.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

extension AccountView {
  struct AccountSection: View {
    @Environment(\.accountDetails) private var accountDetails

    var body: some View {
      if let accountDetails {
        Section("Account") {
          Label {
            VStack(alignment: .leading) {
              Text("Email")
              Text(accountDetails.email)
                .foregroundStyle(.secondary)
            }
          } icon: {
            Image(systemName: "envelope")
              .imageScale(.medium)
          }
        }
      }
    }
  }
}

#Preview {
  Form {
    AccountView.AccountSection()
      .environment(\.accountDetails, .previewUser)
  }
}
