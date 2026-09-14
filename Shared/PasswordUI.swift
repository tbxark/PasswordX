//
//  Theme.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import PasswordCryptor
import SwiftUI

enum Theme {
  static let space: CGFloat = 50
  static let header = Color(red: 0.03, green: 0.56, blue: 0.75)
  static let copyButton = Color(red: 0.00, green: 0.77, blue: 0.42)
  static let restore = Color(red: 0.71, green: 0.24, blue: 0.40)
  static let symbol = Color(red: 0.89, green: 0.26, blue: 0.20)
  static let letter = Color(UIColor.darkGray)
  static let digit = Color(red: 0.11, green: 0.55, blue: 1.00)
  static let fieldBackground = Color(UIColor(white: 0.9, alpha: 1))
  static let text = Color(UIColor.darkGray)
}

extension PasswordCharacterType {
  var displayColor: Color {
    switch self {
    case .symbols:
      return Theme.symbol
    case .lowercaseLetters, .uppercaseLetters:
      return Theme.letter
    case .digits:
      return Theme.digit
    }
  }
}

struct PasswordText {
  static func render(password: String) -> Text {
    var output = Text("")
    for c in password {
      let color = PasswordCharacterType.build(c)?.displayColor ?? Theme.symbol
      output = output + Text(String(c)).foregroundColor(color)
    }
    return output
  }
}

struct CheckRow: View {
  let title: String
  var subtitle: String = ""
  var isSelected = false

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Theme.text)
        if !subtitle.isEmpty {
          Text(subtitle)
            .font(.system(size: 10))
            .foregroundColor(.gray)
        }
      }
      Spacer()
      if isSelected {
        Image(systemName: "checkmark")
      }
    }
    .contentShape(Rectangle())
  }
}
