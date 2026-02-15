//
//  AccountView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI
import UIKit

struct AccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.signOut) private var signOut
  @Environment(\.deleteAccount) private var deleteAccount
  @Environment(\.accountDetails) private var accountDetails
  @Environment(\.profileImage) private var profileImage

  /// A flag to prevent multiple mutating actions from being performed concurrently.
  @State private var isPerformingMutatingAction = false

  /// A flag to show the delete account confirmation dialog.
  @State private var isDeletingAccount = false

  @State private var isEditProfileSheetPresented = false

  var body: some View {
    if let accountDetails {
      NavigationStack {
        Form {
          Section {
            VStack(spacing: 12) {
              ProfileImageView(
                image: profileImage,
                profileImageUrl: accountDetails.profileImageUrl
              )
              .frame(width: 96, height: 96)

              VStack {
                Text(accountDetails.name)
                  .font(.title)
                  .fontWeight(.medium)
                  .multilineTextAlignment(.center)

                Text(accountDetails.displayName)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
              }

              Button {
                isEditProfileSheetPresented = true
              } label: {
                Text("Edit Profile")
              }
              .buttonStyle(.bordered)
              .font(.caption)
              .disabled(isPerformingMutatingAction)
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
              performSignOut()
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
                performDeleteAccount()
              }

              Button("Nevermind", role: .cancel) {
                isDeletingAccount = false
              }
            } message: {
              Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
          }
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }
        }
      }
      .sheet(isPresented: $isEditProfileSheetPresented) {
        EditProfileSheet(accountDetails: accountDetails)
      }
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
    isDeletingAccount = false
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
