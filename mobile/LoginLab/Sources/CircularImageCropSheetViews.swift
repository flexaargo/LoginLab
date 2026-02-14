//
//  CircularImageCropSheetViews.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI
import UIKit

struct CropCanvasView: View {
  let image: UIImage
  let displayedImageSize: CGSize
  let offset: CGSize
  let cropCanvasSize: CGFloat
  let onPanDelta: (CGSize) -> Void
  let onPinchScaleDelta: (CGFloat) -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.92)

      Image(uiImage: image)
        .resizable()
        .frame(
          width: displayedImageSize.width,
          height: displayedImageSize.height
        )
        .offset(offset)

      CropMaskOverlay(size: cropCanvasSize)
        .allowsHitTesting(false)

      Circle()
        .strokeBorder(.white.opacity(0.95), lineWidth: 2)
        .frame(width: cropCanvasSize, height: cropCanvasSize)
        .allowsHitTesting(false)

      CropGridOverlay(size: cropCanvasSize)
        .allowsHitTesting(false)

      CropGestureSurface(
        onPanDelta: onPanDelta,
        onPinchScaleDelta: onPinchScaleDelta
      )
      .frame(width: cropCanvasSize, height: cropCanvasSize)
    }
    .frame(width: cropCanvasSize, height: cropCanvasSize)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .frame(maxWidth: .infinity)
  }
}

struct CropSheetControlsView: View {
  let onTryAnotherTapped: () -> Void

  var body: some View {
    Group {
      Text("Drag and pinch to crop your image.")
        .font(.footnote)
        .foregroundStyle(.secondary)

      Button("Try another", action: onTryAnotherTapped)
        .buttonStyle(.bordered)
    }
  }
}

private struct CropMaskOverlay: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(.black.opacity(0.5))
      .frame(width: size, height: size)
      .overlay {
        Circle()
          .fill(.black)
          .frame(width: size, height: size)
          .blendMode(.destinationOut)
      }
      .compositingGroup()
  }
}

private struct CropGridOverlay: View {
  let size: CGFloat

  var body: some View {
    Canvas { context, canvasSize in
      let thirdX = canvasSize.width / 3
      let thirdY = canvasSize.height / 3

      var path = Path()
      path.move(to: CGPoint(x: thirdX, y: 0))
      path.addLine(to: CGPoint(x: thirdX, y: canvasSize.height))
      path.move(to: CGPoint(x: thirdX * 2, y: 0))
      path.addLine(to: CGPoint(x: thirdX * 2, y: canvasSize.height))

      path.move(to: CGPoint(x: 0, y: thirdY))
      path.addLine(to: CGPoint(x: canvasSize.width, y: thirdY))
      path.move(to: CGPoint(x: 0, y: thirdY * 2))
      path.addLine(to: CGPoint(x: canvasSize.width, y: thirdY * 2))

      context.stroke(path, with: .color(.white.opacity(0.35)), lineWidth: 0.75)
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
  }
}

private struct CropGestureSurface: UIViewRepresentable {
  let onPanDelta: (CGSize) -> Void
  let onPinchScaleDelta: (CGFloat) -> Void

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear

    let panGesture = UIPanGestureRecognizer(
      target: context.coordinator,
      action: #selector(Coordinator.handlePan(_:))
    )
    panGesture.minimumNumberOfTouches = 1
    panGesture.maximumNumberOfTouches = 2
    panGesture.delegate = context.coordinator

    let pinchGesture = UIPinchGestureRecognizer(
      target: context.coordinator,
      action: #selector(Coordinator.handlePinch(_:))
    )
    pinchGesture.delegate = context.coordinator
    pinchGesture.cancelsTouchesInView = true

    view.addGestureRecognizer(panGesture)
    view.addGestureRecognizer(pinchGesture)

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onPanDelta: onPanDelta, onPinchScaleDelta: onPinchScaleDelta)
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    private let onPanDelta: (CGSize) -> Void
    private let onPinchScaleDelta: (CGFloat) -> Void

    init(
      onPanDelta: @escaping (CGSize) -> Void,
      onPinchScaleDelta: @escaping (CGFloat) -> Void
    ) {
      self.onPanDelta = onPanDelta
      self.onPinchScaleDelta = onPinchScaleDelta
    }

    @objc
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
      guard let view = recognizer.view else { return }
      let translation = recognizer.translation(in: view)
      if translation != .zero {
        onPanDelta(CGSize(width: translation.x, height: translation.y))
        recognizer.setTranslation(.zero, in: view)
      }
    }

    @objc
    func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
      let scaleDelta = recognizer.scale
      if scaleDelta != 1 {
        onPinchScaleDelta(scaleDelta)
        recognizer.scale = 1
      }
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) ||
        (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer)
    }
  }
}

enum CropGeometryCalculator {
  static func baseDisplayedImageSize(image: UIImage, cropCanvasSize: CGFloat) -> CGSize {
    let imageSize = image.size
    guard imageSize.width > 0, imageSize.height > 0 else {
      return CGSize(width: cropCanvasSize, height: cropCanvasSize)
    }

    let aspectFillScale = max(
      cropCanvasSize / imageSize.width,
      cropCanvasSize / imageSize.height
    )

    return CGSize(
      width: imageSize.width * aspectFillScale,
      height: imageSize.height * aspectFillScale
    )
  }

  static func displayedImageSize(image: UIImage, cropCanvasSize: CGFloat, zoomScale: CGFloat) -> CGSize {
    let baseSize = baseDisplayedImageSize(image: image, cropCanvasSize: cropCanvasSize)
    return CGSize(
      width: baseSize.width * zoomScale,
      height: baseSize.height * zoomScale
    )
  }

  static func clampedOffset(
    proposedOffset: CGSize,
    image: UIImage,
    cropCanvasSize: CGFloat,
    zoomScale: CGFloat
  ) -> CGSize {
    let imageSize = displayedImageSize(image: image, cropCanvasSize: cropCanvasSize, zoomScale: zoomScale)
    let xLimit = max((imageSize.width - cropCanvasSize) / 2, 0)
    let yLimit = max((imageSize.height - cropCanvasSize) / 2, 0)

    return CGSize(
      width: min(max(proposedOffset.width, -xLimit), xLimit),
      height: min(max(proposedOffset.height, -yLimit), yLimit)
    )
  }
}

enum CropImagePayloadRenderer {
  static func makePayload(
    image: UIImage,
    zoomScale: CGFloat,
    offset: CGSize,
    cropCanvasSize: CGFloat
  ) -> (data: Data, mimeType: String)? {
    let outputDimension: CGFloat = 512
    let rendererSize = CGSize(width: outputDimension, height: outputDimension)
    let imageSize = CropGeometryCalculator.displayedImageSize(
      image: image,
      cropCanvasSize: cropCanvasSize,
      zoomScale: zoomScale
    )
    let viewToOutputScale = outputDimension / cropCanvasSize

    let drawRect = CGRect(
      x: ((cropCanvasSize - imageSize.width) / 2 + offset.width) * viewToOutputScale,
      y: ((cropCanvasSize - imageSize.height) / 2 + offset.height) * viewToOutputScale,
      width: imageSize.width * viewToOutputScale,
      height: imageSize.height * viewToOutputScale
    )

    let renderer = UIGraphicsImageRenderer(size: rendererSize)
    let renderedImage = renderer.image { context in
      context.cgContext.addEllipse(in: CGRect(origin: .zero, size: rendererSize))
      context.cgContext.clip()
      image.draw(in: drawRect)
    }

    if let jpegData = renderedImage.jpegData(compressionQuality: 0.85) {
      return (jpegData, "image/jpeg")
    }
    if let pngData = renderedImage.pngData() {
      return (pngData, "image/png")
    }
    return nil
  }
}
