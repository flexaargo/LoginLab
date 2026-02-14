//
//  EditProfileSheet.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI
import UIKit

struct EditProfileSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accountDetails) private var accountDetails
  @Environment(\.profileImage) private var cachedProfileImage
  @Environment(\.updateProfile) private var updateProfile

  private let initialName: String
  private let initialDisplayName: String

  @State private var name: String
  @State private var displayName: String
  @State private var isPhotoPickerPresented = false
  @State private var isPerformingMutatingAction = false
  @State private var pendingProfileImageData: Data?
  @State private var pendingProfileImageMimeType: String?
  @State private var pendingProfileImage: UIImage?
  @State private var errorMessage: String?

  init(accountDetails: AccountDetails) {
    self.initialName = accountDetails.name
    self.initialDisplayName = accountDetails.displayName
    self._name = State(initialValue: accountDetails.name)
    self._displayName = State(initialValue: accountDetails.displayName)
  }

  var body: some View {
    NavigationStack {
      EditProfileSheetForm(
        pendingProfileImage: pendingProfileImage,
        cachedProfileImage: cachedProfileImage,
        profileImageUrl: accountDetails?.profileImageUrl,
        isPerformingMutatingAction: isPerformingMutatingAction,
        initialName: initialName,
        name: $name,
        initialDisplayName: initialDisplayName,
        displayName: $displayName,
        onEditImageTapped: {
          isPhotoPickerPresented = true
        }
      )
      .scrollBounceBehavior(.basedOnSize)
      .navigationTitle("Edit Profile")
      .navigationBarTitleDisplayMode(.inline)
      .interactiveDismissDisabled(true)
      .presentationDetents([.fraction(3 / 5)])
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .disabled(isPerformingMutatingAction)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            performSave()
          }
        }
      }
    }
    .profilePhotoPicker(
      isPresented: $isPhotoPickerPresented,
      onImageCropped: { imageData, mimeType in
        pendingProfileImageData = imageData
        pendingProfileImageMimeType = mimeType
        pendingProfileImage = UIImage(data: imageData)
      },
      onError: { message in
        errorMessage = message
      }
    )
    .alert(
      "Unable to update profile",
      isPresented: Binding(
        get: { errorMessage != nil },
        set: { isPresented in
          if !isPresented {
            errorMessage = nil
          }
        }
      ),
      actions: {
        Button("OK", role: .cancel) {
          errorMessage = nil
        }
      },
      message: {
        Text(errorMessage ?? "Unknown error")
      }
    )
  }

  private func performSave() {
    guard !isPerformingMutatingAction else { return }

    let nameToSave = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let displayNameToSave = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !nameToSave.isEmpty, !displayNameToSave.isEmpty else {
      errorMessage = "Name and display name are required."
      return
    }

    let nameChanged = nameToSave != initialName
    let displayNameChanged = displayNameToSave != initialDisplayName
    let imageChanged = pendingProfileImageData != nil

    guard nameChanged || displayNameChanged || imageChanged else {
      dismiss()
      return
    }

    isPerformingMutatingAction = true
    Task {
      do {
        try await updateProfile(
          fullName: nameChanged ? nameToSave : nil,
          displayName: displayNameChanged ? displayNameToSave : nil,
          imageData: pendingProfileImageData,
          mimeType: pendingProfileImageMimeType
        )
        await MainActor.run {
          dismiss()
        }
      } catch {
        await MainActor.run {
          errorMessage = "Profile update failed. Please try again."
        }
        print("🚨 Error updating profile: \(error)")
      }
      isPerformingMutatingAction = false
    }
  }
}

#Preview {
  EditProfileSheet(accountDetails: .previewUser)
    .environment(\.accountDetails, AccountDetails.previewUser)
}
