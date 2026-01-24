//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct AccountView: View {
  @Environment(\.signOut) private var signOut
  @Environment(\.accountDetails) private var accountDetails

  @State private var isSigningOut = false

  var body: some View {
    if let accountDetails {
      NavigationStack {
        Form {
          Section {
            VStack {
              Circle()
                .frame(width: 96, height: 96)
                .foregroundStyle(.gray.quinary)

              Text(accountDetails.name)
                .font(.title)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

              Text(accountDetails.displayName)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
          }
          .listRowInsets(.init())
          .listRowBackground(Color.clear)

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

          Section {
            Button(role: .destructive) {
              guard !isSigningOut else { return }
              isSigningOut = true
              Task {
                do {
                  try await signOut()
                } catch {
                  print("🚨 Error signing out: \(error)")
                }
                isSigningOut = false
              }
            } label: {
              Text("Log out")
            }
          }
        }
      }
    }
  }
}

#Preview {
  AccountView()
    .environment(\.accountDetails, AccountDetails.previewUser)
}
