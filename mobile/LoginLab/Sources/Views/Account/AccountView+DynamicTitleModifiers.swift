//
//  AccountView+DynamicTitleModifiers.swift
//
//  Copyright © 2026 Alex Fargo.
//

import SwiftUI

private struct AccountDynamicTitleModifier: ViewModifier {
  let title: String
  @State private var shouldShowTitle = false

  func body(content: Content) -> some View {
    content
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .title) {
          Text(title)
            .hidden()
            .lineLimit(1)
            .overlay {
              if shouldShowTitle {
                Text(title)
              }
            }
        }
      }
      .animation(.bouncy, value: shouldShowTitle)
      .overlayPreferenceValue(BoundsPreferenceKey.self) { anchor in
        GeometryReader { proxy in
          if let anchor {
            let visibleRect = proxy.frame(in: .local)
            let value = proxy[anchor]
            let newShouldShowTitle = value.maxY < visibleRect.minY
            Color.clear
              .onChange(of: newShouldShowTitle) {
                shouldShowTitle = newShouldShowTitle
              }
          } else {
            Color.clear
          }
        }
      }
  }
}

struct BoundsPreferenceKey: PreferenceKey {
  static var defaultValue: Anchor<CGRect>? = nil

  static func reduce(
    value: inout Anchor<CGRect>?,
    nextValue: () -> Anchor<CGRect>?
  ) {
    value = nextValue() ?? value
  }
}

extension View {
  func accountDynamicTitle(_ title: String) -> some View {
    modifier(AccountDynamicTitleModifier(title: title))
  }
}
