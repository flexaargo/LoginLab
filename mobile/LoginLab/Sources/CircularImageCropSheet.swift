//
//  CircularImageCropSheet.swift
//
//  Copyright © 2026 Alex Fargo.
//

import PhotosUI
import SwiftUI
import UIKit

struct CircularImageCropSheet: View {
  @Binding var image: UIImage
  private let onConfirm: (Data, String) -> Void
  private let onError: (String) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isPhotoPickerPresented = false

  @State private var zoomScale: CGFloat = 1
  @State private var offset: CGSize = .zero

  private let cropCanvasSize: CGFloat = 300
  private let minimumZoomScale: CGFloat = 1
  private let maximumZoomScale: CGFloat = 4

  init(
    image: Binding<UIImage>,
    initialPhotoItem: PhotosPickerItem?,
    onConfirm: @escaping (Data, String) -> Void,
    onError: @escaping (String) -> Void
  ) {
    self._image = image
    self._selectedPhotoItem = State(initialValue: initialPhotoItem)
    self.onConfirm = onConfirm
    self.onError = onError
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        CropCanvasView(
          image: image,
          displayedImageSize: displayedImageSize(for: zoomScale),
          offset: offset,
          cropCanvasSize: cropCanvasSize,
          onPanDelta: applyPan,
          onPinchScaleDelta: applyPinch
        )

        CropSheetControlsView(
          onTryAnotherTapped: {
            isPhotoPickerPresented = true
          }
        )

        Spacer()
      }
      .padding(.top, 16)
      .navigationTitle("Crop Photo")
      .navigationBarTitleDisplayMode(.inline)
      .interactiveDismissDisabled(true)
      .presentationDetents([.fraction(3 / 5)])
      .photosPicker(
        isPresented: $isPhotoPickerPresented,
        selection: $selectedPhotoItem,
        matching: .images,
        photoLibrary: .shared()
      )
      .onChange(of: selectedPhotoItem) { _, _ in
        loadSelectedPhoto()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Use Photo") {
            guard let croppedImagePayload = CropImagePayloadRenderer.makePayload(
              image: image,
              zoomScale: zoomScale,
              offset: offset,
              cropCanvasSize: cropCanvasSize
            ) else { return }
            onConfirm(croppedImagePayload.data, croppedImagePayload.mimeType)
            dismiss()
          }
        }
      }
    }
  }

  private func applyPan(translation: CGSize) {
    let proposedOffset = CGSize(
      width: offset.width + translation.width,
      height: offset.height + translation.height
    )
    offset = clampedOffset(for: proposedOffset, zoomScale: zoomScale)
  }

  private func applyPinch(scaleDelta: CGFloat) {
    let proposedScale = min(
      max(zoomScale * scaleDelta, minimumZoomScale),
      maximumZoomScale
    )

    zoomScale = proposedScale
    offset = clampedOffset(for: offset, zoomScale: proposedScale)
  }

  private func displayedImageSize(for zoomScale: CGFloat) -> CGSize {
    CropGeometryCalculator.displayedImageSize(
      image: image,
      cropCanvasSize: cropCanvasSize,
      zoomScale: zoomScale
    )
  }

  private func clampedOffset(for proposedOffset: CGSize, zoomScale: CGFloat) -> CGSize {
    CropGeometryCalculator.clampedOffset(
      proposedOffset: proposedOffset,
      image: image,
      cropCanvasSize: cropCanvasSize,
      zoomScale: zoomScale
    )
  }

  private func loadSelectedPhoto() {
    guard let selectedPhotoItem else { return }

    Task {
      do {
        guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self),
              let selectedImage = UIImage(data: imageData)
        else {
          throw URLError(.cannotDecodeRawData)
        }

        await MainActor.run {
          image = selectedImage
          zoomScale = 1
          offset = .zero
        }
      } catch {
        await MainActor.run {
          onError("Please choose a valid image and try again.")
        }
      }
    }
  }
}
