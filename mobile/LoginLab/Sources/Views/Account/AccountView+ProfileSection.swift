//
//  AccountView+ProfileSection.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

extension AccountView {
  struct ProfileSection: View {
    @Environment(\.onEditProfile) private var onEditProfile
    @Environment(\.accountDetails) private var accountDetails
    @Environment(\.profileImage) private var profileImage
    @Environment(\.isPerformingMutatingAction) private var isPerformingMutatingAction

    var body: some View {
      if let accountDetails {
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
              onEditProfile()
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
      }
    }
  }
}

struct OnEditProfileAction {
  var onEditProfile: () -> Void = {}

  func callAsFunction() {
    onEditProfile()
  }
}

extension EnvironmentValues {
  @Entry var onEditProfile: OnEditProfileAction = .init()
}

#Preview {
  Form {
    AccountView.ProfileSection()
      .environment(\.accountDetails, .previewUser)
  }
}
