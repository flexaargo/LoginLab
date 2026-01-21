//
//  AppleAuthenticationButtonConfig.swift
//
//  Copyright © 2026 Alex Fargo.
//

import Foundation
import SwiftUI

enum AppleAuthorizationButtonAppearance {
  /// The button will be white with black text.
  case white
  /// The button will be black with white text.
  case black
  /// The button will automatically determine the appearance based on the system appearance.
  case automatic
}

struct AppleAuthenticationButtonConfig {
  /// The appearance of the button. Defaults to automatic.
  var appearance: AppleAuthorizationButtonAppearance = .automatic
  /// Whether to show a progress indicator when the button is loading. Defaults to true.
  var showsProgressIndiciator = true
  /// Whether to force the progress indicator to be shown. Defaults to false.
  var forceShowProgressIndiciator = false
}

extension EnvironmentValues {
  @Entry var appleAuthorizationButtonConfig = AppleAuthenticationButtonConfig()
}

extension View {
  func appleAuthenticationButtonForceShowProgressIndiciator(_ force: Bool) -> some View {
    environment(\.appleAuthorizationButtonConfig.forceShowProgressIndiciator, force)
  }
}
