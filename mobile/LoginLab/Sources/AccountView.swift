//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct AccountView: View {
  @Environment(\.accountDetails) private var accountDetails
  @Environment(SessionManager.self) private var sessionManager

  @State private var isSigningOut = false

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

          Section {
            Button(role: .destructive) {
              guard !isSigningOut else { return }
              isSigningOut = true
              Task {
                do {
                  try await sessionManager.signOut()
                } catch {
                  print("🚨 Error signing out: \(error)")
                }
                isSigningOut = false
              }
            } label: {
              Text("Sign Out")
            }
          }
        }
        .navigationTitle("Account")
        .toolbarTitleDisplayMode(.inlineLarge)
      }
    }
  }
}

#Preview {
  AccountView()
}
