//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI
import UIKit

extension EnvironmentValues {
  @Entry var isPerformingMutatingAction: Bool = false
}

struct AccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.signOut) private var signOut
  @Environment(\.deleteAccount) private var deleteAccount
  @Environment(\.accountDetails) private var accountDetails

  /// A flag to prevent multiple mutating actions from being performed concurrently.
  @State private var isPerformingMutatingAction = false

  @State private var isEditProfileSheetPresented = false

  var body: some View {
    if let accountDetails {
      NavigationStack {
        Form {
          ProfileSection()
          AccountSection()
          DangerZoneSection()
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }
        }
        .accountDynamicTitle(accountDetails.name)
      }
      .sheet(isPresented: $isEditProfileSheetPresented) {
        EditProfileSheet(accountDetails: accountDetails)
      }
      .environment(\.isPerformingMutatingAction, isPerformingMutatingAction)
      .environment(\.onEditProfile, .init {
        isEditProfileSheetPresented = true
      })
      .environment(\.onSignOut, .init {
        performSignOut()
      })
      .environment(\.onDeleteAccount, .init {
        performDeleteAccount()
      })
    }
  }

  private func performSignOut() {
    guard !isPerformingMutatingAction else { return }
    isPerformingMutatingAction = true
    Task {
      do {
        try await signOut()
      } catch {
        print("🚨 Error signing out: \(error)")
      }
      isPerformingMutatingAction = false
    }
  }

  private func performDeleteAccount() {
    guard !isPerformingMutatingAction else { return }
    isPerformingMutatingAction = true
    Task {
      do {
        try await deleteAccount()
      } catch {
        print("🚨 Error deleting account: \(error)")
      }
      isPerformingMutatingAction = false
    }
  }
}

#Preview {
  AccountView()
    .environment(\.accountDetails, AccountDetails.previewUser)
}
