//
//  ProfileImageView.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI
import UIKit

/// Renders a profile image in a circle, or a placeholder when no image is provided.
struct ProfileImageView: View {
  private let image: UIImage?
  private let profileImageUrl: String?

  init(image: UIImage?) {
    self.image = image
    self.profileImageUrl = nil
  }

  init(image: UIImage?, profileImageUrl: String?) {
    self.image = image
    self.profileImageUrl = profileImageUrl
  }

  /// Convenience initializer for profile image source (remote HTTP(S) URL).
  init(profileImageUrl: String?) {
    self.image = nil
    self.profileImageUrl = profileImageUrl
  }

  var body: some View {
    if let image {
      profileImage(from: image)
    } else if let remoteUrl = remoteURL(from: profileImageUrl) {
      AsyncImage(url: remoteUrl) { phase in
        switch phase {
        case let .success(loadedImage):
          loadedImage
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
        default:
          placeholder
        }
      }
    } else {
      placeholder
    }
  }

  @ViewBuilder
  private var placeholder: some View {
    Circle()
      .foregroundStyle(.gray.quinary)
      .overlay {
        GeometryReader { proxy in
          ZStack {
            Image(systemName: "person.fill")
              .resizable()
              .scaledToFit()
              .font(.title2)
              .foregroundStyle(.secondary)
              .frame(
                width: max(proxy.size.width * 0.5, 0),
                height: max(proxy.size.height * 0.5, 0)
              )
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipShape(.circle)
        }
      }
  }

  private func profileImage(from image: UIImage) -> some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .clipShape(Circle())
  }

  private func remoteURL(from value: String?) -> URL? {
    guard let value,
          let url = URL(string: value),
          let scheme = url.scheme?.lowercased(),
          scheme == "http" || scheme == "https"
    else {
      return nil
    }
    return url
  }
}

#Preview {
  ProfileImageView(image: nil)
}
