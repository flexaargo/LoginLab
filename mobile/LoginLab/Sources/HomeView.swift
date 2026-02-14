//
//  HomeView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct HomeView: View {
  @Environment(\.accountDetails) private var accountDetails
  @Environment(\.profileImage) private var profileImage
  let onProfileTapped: () -> Void

  private enum Constants {
    static let profileImageSize: CGFloat = 38
  }

  init(onProfileTapped: @escaping () -> Void = {}) {
    self.onProfileTapped = onProfileTapped
  }

  var body: some View {
    NavigationStack {
      List {}
        .navigationTitle("Home")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button(action: onProfileTapped) {
              ProfileImageView(
                image: profileImage,
                profileImageUrl: accountDetails?.profileImageUrl
              )
              .frame(width: Constants.profileImageSize, height: Constants.profileImageSize)
            }
            .frame(width: Constants.profileImageSize, height: Constants.profileImageSize)
          }
          .sharedBackgroundVisibility(.hidden)
        }
    }
  }
}

#Preview {
  HomeView()
}
