//
//  CameraCaptureSheet.swift
//
//  Copyright © 2026 Alex Fargo.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

struct CameraCaptureSheet: View {
  private let onCapture: (UIImage) -> Void
  private let onError: (String) -> Void

  @Environment(\.dismiss) private var dismiss
  @StateObject private var cameraModel = CameraCaptureModel()

  private let cameraPreviewSize: CGFloat = 300

  init(
    onCapture: @escaping (UIImage) -> Void,
    onError: @escaping (String) -> Void
  ) {
    self.onCapture = onCapture
    self.onError = onError
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        Spacer()

        VStack(spacing: 16) {
          CameraPreviewContainer(
            session: cameraModel.session,
            previewSize: cameraPreviewSize,
            isCameraUnavailable: cameraModel.isCameraUnavailable
          )

          Text("Position your face inside the circle and capture.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Spacer()

        CameraShutterButton {
          cameraModel.capturePhoto()
        }
        .disabled(cameraModel.isCaptureButtonDisabled)
        .padding(.bottom, 24)
      }
      .padding(.top, 16)
      .padding(.horizontal, 20)
      .navigationTitle("Take Photo")
      .navigationBarTitleDisplayMode(.inline)
      .interactiveDismissDisabled(true)
      .presentationDetents([.large])
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .onAppear {
      cameraModel.onCapture = { image in
        dismiss()
        Task { @MainActor in
          onCapture(image)
        }
      }
      cameraModel.onError = onError
      cameraModel.startSession()
    }
    .onDisappear {
      cameraModel.stopSession()
    }
  }
}

private struct CameraPreviewContainer: View {
  let session: AVCaptureSession
  let previewSize: CGFloat
  let isCameraUnavailable: Bool

  var body: some View {
    Group {
      if isCameraUnavailable {
        Circle()
          .fill(.black.opacity(0.92))
          .overlay {
            ContentUnavailableView(
              "Camera Unavailable",
              systemImage: "camera.slash",
              description: Text("Allow camera access in Settings and try again.")
            )
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 20)
          }
      } else {
        CameraPreviewView(session: session)
          .clipShape(Circle())
          .overlay {
            Circle()
              .strokeBorder(.white.opacity(0.95), lineWidth: 2)
              .allowsHitTesting(false)
          }
      }
    }
    .frame(width: previewSize, height: previewSize)
    .frame(maxWidth: .infinity)
  }
}

private struct CameraShutterButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(.white)
          .frame(width: 76, height: 76)

        Circle()
          .strokeBorder(.white.opacity(0.65), lineWidth: 4)
          .frame(width: 90, height: 90)
      }
      .frame(width: 90, height: 90)
    }
    .accessibilityLabel("Capture")
    .contentShape(Circle())
  }
}

private struct CameraPreviewView: UIViewRepresentable {
  let session: AVCaptureSession

  func makeUIView(context: Context) -> CameraPreviewUIView {
    let view = CameraPreviewUIView()
    view.previewLayer.session = session
    return view
  }

  func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
    uiView.previewLayer.session = session
  }
}

private final class CameraPreviewUIView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    guard let layer = layer as? AVCaptureVideoPreviewLayer else {
      fatalError("Expected AVCaptureVideoPreviewLayer backing layer")
    }
    return layer
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    previewLayer.videoGravity = .resizeAspectFill
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class CameraCaptureModel: NSObject, ObservableObject {
  let session = AVCaptureSession()

  @Published private(set) var isCameraUnavailable = false
  @Published private(set) var isCaptureButtonDisabled = true

  var onCapture: ((UIImage) -> Void)?
  var onError: ((String) -> Void)?

  private let sessionQueue = DispatchQueue(label: "CameraCaptureSessionQueue")
  private let photoOutput = AVCapturePhotoOutput()
  private var isSessionConfigured = false
  private var isCaptureInProgress = false
  private var hasDeliveredCapture = false

  func startSession() {
    hasDeliveredCapture = false
    isCaptureInProgress = false

    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      configureAndStartSessionIfNeeded()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        guard let self else { return }
        if granted {
          self.configureAndStartSessionIfNeeded()
        } else {
          self.publishCameraUnavailable(message: "Camera access is required to take a profile photo.")
        }
      }
    case .denied, .restricted:
      publishCameraUnavailable(message: "Camera access is required to take a profile photo.")
    @unknown default:
      publishCameraUnavailable(message: "Camera access is unavailable on this device.")
    }
  }

  func stopSession() {
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning else { return }
      self.session.stopRunning()
    }
  }

  func capturePhoto() {
    guard isSessionConfigured, !isCaptureInProgress, !hasDeliveredCapture else { return }

    isCaptureInProgress = true
    publishCaptureButtonState(disabled: true)

    let settings = AVCapturePhotoSettings()
    settings.photoQualityPrioritization = .balanced

    if let connection = photoOutput.connection(with: .video),
       connection.isVideoMirroringSupported
    {
      connection.isVideoMirrored = true
    }

    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  private func configureAndStartSessionIfNeeded() {
    sessionQueue.async { [weak self] in
      guard let self else { return }

      if !self.isSessionConfigured {
        guard self.configureSession() else {
          self.publishCameraUnavailable(message: "Unable to start the camera. Please try again.")
          return
        }
        self.isSessionConfigured = true
      }

      guard !self.session.isRunning else {
        self.publishCaptureButtonState(disabled: false)
        return
      }

      self.session.startRunning()
      self.publishCaptureButtonState(disabled: false)
    }
  }

  private func configureSession() -> Bool {
    session.beginConfiguration()
    session.sessionPreset = .photo

    defer {
      session.commitConfiguration()
    }

    guard
      let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
      let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
      session.canAddInput(videoInput)
    else {
      return false
    }

    session.addInput(videoInput)

    guard session.canAddOutput(photoOutput) else {
      return false
    }

    session.addOutput(photoOutput)
    photoOutput.maxPhotoQualityPrioritization = .balanced

    return true
  }

  private func publishCameraUnavailable(message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      self.isCameraUnavailable = true
      self.isCaptureButtonDisabled = true
      self.onError?(message)
    }
  }

  private func publishCaptureButtonState(disabled: Bool) {
    Task { @MainActor [weak self] in
      self?.isCaptureButtonDisabled = disabled
    }
  }
}

extension CameraCaptureModel: AVCapturePhotoCaptureDelegate {
  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    if error != nil {
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.isCaptureInProgress = false
        self.publishCaptureButtonState(disabled: false)
        self.onError?("Unable to capture photo. Please try again.")
      }
      return
    }

    guard
      let photoData = photo.fileDataRepresentation(),
      let capturedImage = UIImage(data: photoData)
    else {
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.isCaptureInProgress = false
        self.publishCaptureButtonState(disabled: false)
        self.onError?("Unable to process captured photo. Please try again.")
      }
      return
    }

    Task { @MainActor [weak self] in
      guard let self, !self.hasDeliveredCapture else { return }
      self.hasDeliveredCapture = true
      self.isCaptureInProgress = false
      self.onCapture?(capturedImage)
    }
  }
}
