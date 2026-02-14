//
//  EditProfileSheetViews.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI
import UIKit

struct EditProfileSheetForm: View {
  let pendingProfileImage: UIImage?
  let cachedProfileImage: UIImage?
  let profileImageUrl: String?
  let isPerformingMutatingAction: Bool
  let initialName: String
  @Binding var name: String
  let initialDisplayName: String
  @Binding var displayName: String
  let onEditImageTapped: () -> Void

  var body: some View {
    Form {
      EditProfileImageSection(
        pendingProfileImage: pendingProfileImage,
        cachedProfileImage: cachedProfileImage,
        profileImageUrl: profileImageUrl,
        isPerformingMutatingAction: isPerformingMutatingAction,
        onEditImageTapped: onEditImageTapped
      )

      EditProfileTextSection(
        initialName: initialName,
        name: $name,
        initialDisplayName: initialDisplayName,
        displayName: $displayName
      )
    }
    .listSectionSpacing(.compact)
  }
}

private struct EditProfileImageSection: View {
  let pendingProfileImage: UIImage?
  let cachedProfileImage: UIImage?
  let profileImageUrl: String?
  let isPerformingMutatingAction: Bool
  let onEditImageTapped: () -> Void

  private enum Constants {
    static let profileImageDiameter: CGFloat = 128
    static let profileImageRadius: CGFloat = profileImageDiameter / 2
    static let editButtonSize: CGFloat = 28
    static let editButtonMaskBorderWidth: CGFloat = 8
  }

  var body: some View {
    Section {
      VStack(spacing: 16) {
        ProfileImageView(
          image: pendingProfileImage ?? cachedProfileImage,
          profileImageUrl: profileImageUrl
        )
        .frame(
          width: Constants.profileImageDiameter,
          height: Constants.profileImageDiameter
        )
        .overlay {
          ZStack {
            Circle()
              .frame(
                width: Constants.editButtonSize + Constants.editButtonMaskBorderWidth,
                height: Constants.editButtonSize + Constants.editButtonMaskBorderWidth
              )
              .blendMode(.destinationOut)

            Button(action: onEditImageTapped) {
              Image(systemName: "camera")
                .font(.system(size: 12, weight: .medium))
                .frame(
                  width: Constants.editButtonSize,
                  height: Constants.editButtonSize
                )
                .background(.tint.quinary, in: .circle)
            }
            .disabled(isPerformingMutatingAction)
          }
          .offset(
            x: Constants.profileImageRadius * cos(.pi / 4),
            y: Constants.profileImageRadius * sin(.pi / 4)
          )
        }
        .compositingGroup()
      }
      .frame(maxWidth: .infinity, alignment: .center)
      .listRowInsets(.init())
      .listRowBackground(Color.clear)
    }
  }
}

private struct EditProfileTextSection: View {
  let initialName: String
  @Binding var name: String
  let initialDisplayName: String
  @Binding var displayName: String

  var body: some View {
    Section("Name") {
      TextField(initialName, text: $name)
        .textContentType(.name)
        .autocorrectionDisabled()
    }

    Section("Display Name") {
      TextField(initialDisplayName, text: $displayName)
        .textContentType(.username)
        .autocapitalization(.none)
        .autocorrectionDisabled()
    }
  }
}

#Preview("Profile Image Section") {
  EditProfileImageSection(
    pendingProfileImage: nil,
    cachedProfileImage: nil,
    profileImageUrl: nil,
    isPerformingMutatingAction: false
  ) {}
}
