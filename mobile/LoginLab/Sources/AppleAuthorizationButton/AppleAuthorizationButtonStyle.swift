//
//  AppleAuthorizationButtonStyle.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

struct AppleAuthorizationButtonStyle: ButtonStyle {
  @Environment(\.colorScheme) private var colorScheme

  private var foregroundStyle: some ShapeStyle {
    if colorScheme == .dark { return .black }
    return .white
  }

  private var backgroundColor: Color {
    if colorScheme == .dark { return .white }
    return .black
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(foregroundStyle)
      .tint(foregroundStyle)
      .frame(maxWidth: .infinity, alignment: .center)
      .padding()
      .contentShape(.capsule)
      .glassEffect(.regular.interactive().tint(backgroundColor))
  }
}

extension ButtonStyle where Self == AppleAuthorizationButtonStyle {
  static var appleAuthentication: AppleAuthorizationButtonStyle {
    AppleAuthorizationButtonStyle()
  }
}
