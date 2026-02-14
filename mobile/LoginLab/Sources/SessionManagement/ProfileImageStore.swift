//
//  ProfileImageStore.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import UIKit

actor ProfileImageStore {
  private let fileManager = FileManager.default
  private let directoryURL: URL

  init() {
    let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    self.directoryURL = baseDirectory.appendingPathComponent("profile-images", isDirectory: true)

    do {
      try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    } catch {
      print("⚠️ Failed creating profile image cache directory: \(error)")
    }
  }

  func loadImage(for userID: String) -> UIImage? {
    guard let data = try? Data(contentsOf: fileURL(for: userID)) else {
      return nil
    }
    return UIImage(data: data)
  }

  func store(_ imageData: Data, for userID: String) {
    do {
      try imageData.write(to: fileURL(for: userID), options: .atomic)
    } catch {
      print("⚠️ Failed storing cached profile image: \(error)")
    }
  }

  func removeImage(for userID: String) {
    do {
      try fileManager.removeItem(at: fileURL(for: userID))
    } catch {
      // Ignore if the cache file does not exist.
      if (error as NSError).code != NSFileNoSuchFileError {
        print("⚠️ Failed removing cached profile image: \(error)")
      }
    }
  }

  func fetchAndCacheImage(from profileImageUrl: String?, for userID: String) async -> UIImage? {
    guard let profileImageUrl,
          let url = URL(string: profileImageUrl),
          let scheme = url.scheme?.lowercased(),
          scheme == "http" || scheme == "https"
    else {
      return nil
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      guard let httpResponse = response as? HTTPURLResponse,
            (200 ... 299).contains(httpResponse.statusCode),
            let image = UIImage(data: data)
      else {
        return nil
      }
      store(data, for: userID)
      return image
    } catch {
      return nil
    }
  }

  private func fileURL(for userID: String) -> URL {
    directoryURL.appendingPathComponent("\(userID).img", isDirectory: false)
  }
}
