//
//  ProfilePhotoPickerModifier.swift
//
//  Copyright © 2026 Alex Fargo.
//

import PhotosUI
import SwiftUI
import UIKit

private struct ProfilePhotoPickerModifier: ViewModifier {
  @Binding var isPresented: Bool
  let onImageCropped: (Data, String) -> Void
  let onError: (String) -> Void

  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var cropImage: UIImage?
  @State private var initialCropPhotoItem: PhotosPickerItem?

  func body(content: Content) -> some View {
    content
      .photosPicker(
        isPresented: $isPresented,
        selection: $selectedPhotoItem,
        matching: .images,
        photoLibrary: .shared()
      )
      .onChange(of: isPresented) { _, isNowPresented in
        if isNowPresented {
          // Fresh edit flow should not inherit previous picker selection.
          selectedPhotoItem = nil
          initialCropPhotoItem = nil
        }
      }
      .onChange(of: selectedPhotoItem) { _, _ in
        guard cropImage == nil else { return }
        loadSelectedPhoto()
      }
      .sheet(
        isPresented: Binding(
          get: { cropImage != nil },
          set: { isPresented in
            if !isPresented {
              cropImage = nil
              initialCropPhotoItem = nil
            }
          }
        )
      ) {
        if let cropImageBinding {
          CircularImageCropSheet(
            image: cropImageBinding,
            initialPhotoItem: initialCropPhotoItem,
            onConfirm: { imageData, mimeType in
              onImageCropped(imageData, mimeType)
            },
            onError: onError
          )
        }
      }
  }

  private var cropImageBinding: Binding<UIImage>? {
    guard cropImage != nil else { return nil }
    return Binding(
      get: { cropImage ?? UIImage() },
      set: { cropImage = $0 }
    )
  }

  private func loadSelectedPhoto() {
    guard let selectedPhotoItem else { return }

    Task {
      do {
        guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self),
              let image = UIImage(data: imageData)
        else {
          throw URLError(.cannotDecodeRawData)
        }

        await MainActor.run {
          cropImage = image
          initialCropPhotoItem = selectedPhotoItem
        }
      } catch {
        await MainActor.run {
          onError("Please choose a valid image and try again.")
        }
      }

      await MainActor.run {
        // Keep initial picker item transient in the modifier.
        self.selectedPhotoItem = nil
      }
    }
  }
}

extension View {
  func profilePhotoPicker(
    isPresented: Binding<Bool>,
    onImageCropped: @escaping (Data, String) -> Void,
    onError: @escaping (String) -> Void
  ) -> some View {
    modifier(
      ProfilePhotoPickerModifier(
        isPresented: isPresented,
        onImageCropped: onImageCropped,
        onError: onError
      )
    )
  }
}
