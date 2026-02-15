//
//  AccountView+DangerZoneSection.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

extension AccountView {
  struct DangerZoneSection: View {
    @Environment(\.onSignOut) private var onSignOut
    @Environment(\.onDeleteAccount) private var onDeleteAccount
    @Environment(\.isPerformingMutatingAction) private var isPerformingMutatingAction
    @State private var isDeletingAccount = false

    var body: some View {
      Section {
        Button(role: .destructive) {
          onSignOut()
        } label: {
          Label {
            Text("Log out")
          } icon: {
            Image(systemName: "rectangle.portrait.and.arrow.forward")
              .imageScale(.medium)
          }
          .foregroundStyle(.red)
        }
        .disabled(isPerformingMutatingAction)

        Button(role: .destructive) {
          isDeletingAccount = true
        } label: {
          Label {
            Text("Delete account")
          } icon: {
            Image(systemName: "trash")
              .imageScale(.medium)
          }
          .foregroundStyle(.red)
        }
        .disabled(isPerformingMutatingAction)
        .alert("Delete account", isPresented: $isDeletingAccount) {
          Button("Delete", role: .destructive) {
            onDeleteAccount()
          }

          Button("Nevermind", role: .cancel) {
            isDeletingAccount = false
          }
        } message: {
          Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
      }
    }
  }
}

struct OnSignOutAction {
  var onSignOut: () -> Void = {}

  func callAsFunction() {
    onSignOut()
  }
}

struct OnDeleteAccountAction {
  var onDeleteAccount: () -> Void = {}

  func callAsFunction() {
    onDeleteAccount()
  }
}

extension EnvironmentValues {
  @Entry var onSignOut: OnSignOutAction = .init()
  @Entry var onDeleteAccount: OnDeleteAccountAction = .init()
}

#Preview {
  Form {
    AccountView.DangerZoneSection()
  }
}
