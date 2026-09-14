//
//  SettingView.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import PasswordCryptor
import SwiftUI

struct SettingView: View {

  private enum ActiveAlert: Identifiable {
    case chooseOne
    case biometricError(String)
    case saveConfirm
    case saveSuccess
    case restoreConfirm(PasswordConfig)
    case restoreFailed

    var id: String {
      switch self {
      case .chooseOne: return "chooseOne"
      case .biometricError: return "biometricError"
      case .saveConfirm: return "saveConfirm"
      case .saveSuccess: return "saveSuccess"
      case .restoreConfirm: return "restoreConfirm"
      case .restoreFailed: return "restoreFailed"
      }
    }

    var title: String {
      switch self {
      case .chooseOne: return "Warning"
      case .biometricError: return "Error"
      case .saveConfirm: return "Warning"
      case .saveSuccess: return "Success"
      case .restoreConfirm: return "Warning"
      case .restoreFailed: return "Alert"
      }
    }

    var message: String {
      switch self {
      case .chooseOne:
        return "Choose at least one character set"
      case .biometricError(let reason):
        return reason
      case .saveConfirm:
        return
          "The current configuration is different from the saved configuration. If you save it, export the configuration."
      case .saveSuccess:
        return
          "The configuration information has been saved on the clipboard, please keep it in a safe place."
      case .restoreConfirm:
        return "Replace the current configuration with the configuration in the clipboard?"
      case .restoreFailed:
        return "Failed to get configuration information from clipboard."
      }
    }
  }

  @ObservedObject private var configService = PasswordConfigService.shared
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var config = PasswordConfigService.shared.configValue
  @State private var activeAlert: ActiveAlert?
  private let biometricAvailable = BiometricAuth.isBiometricAuthenticationAvailable()

  var body: some View {
    NavigationStack {
      Form {
        lengthSection
        characterTypeSection
        styleSection
        cryptorTypeSection
        if biometricAvailable {
          saveMasterKeySection
        }
        saveConfigSection
        restoreConfigSection
        aboutSection
      }
      .navigationTitle("Setting")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            try? configService.update(config: config)
            dismiss()
          }
        }
      }
      .alert(
        activeAlert?.title ?? "",
        isPresented: Binding(get: { activeAlert != nil }, set: { if !$0 { activeAlert = nil } }),
        presenting: activeAlert
      ) { alert in
        switch alert {
        case .saveConfirm:
          Button("Save") {
            try? configService.update(config: config)
          }
          Button("Don't Save", role: .cancel) {}
        case .restoreConfirm(let restored):
          Button("Replace", role: .destructive) {
            config = restored
          }
          Button("Cancel", role: .cancel) {}
        default:
          Button("OK", role: .cancel) {}
        }
      } message: { alert in
        Text(alert.message)
      }
    }
  }

  // MARK: - Sections

  private var lengthSection: some View {
    Section("Password length") {
      HStack {
        Text("Password length:")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Theme.text)
        Text("\(config.length)")
          .font(.system(size: 14))
          .foregroundColor(.gray)
        Slider(
          value: Binding(get: { Double(config.length) }, set: { config.length = Int($0) }),
          in: 1...30, step: 1)
      }
    }
  }

  private var characterTypeSection: some View {
    Section("Character Type") {
      ForEach(PasswordCharacterType.allCases, id: \.self) { type in
        Button {
          toggleCharacterType(type)
        } label: {
          CheckRow(
            title: type.title,
            subtitle: String(type.characterarList),
            isSelected: config.characterType.contains(type))
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var styleSection: some View {
    Section("Style") {
      ForEach(styleRows, id: \.self) { style in
        Button {
          config.style = style
        } label: {
          CheckRow(
            title: style.title,
            subtitle: style.example,
            isSelected: config.style == style)
        }
        .buttonStyle(.plain)
      }
      if case .word = config.style {
        HStack {
          Text("Pattern length:")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Theme.text)
          Text("\(config.style.patternLength)")
            .font(.system(size: 14))
            .foregroundColor(.gray)
          Slider(
            value: Binding(
              get: { Double(config.style.patternLength) },
              set: { newValue in
                if case .word(let separator, _) = config.style {
                  config.style = .word(separator: separator, length: Int(newValue))
                }
              }), in: 4...10, step: 1)
        }
      }
    }
  }

  private var cryptorTypeSection: some View {
    Section("Cryptor Type") {
      ForEach(PasswordCryptorType.allCases, id: \.self) { type in
        Button {
          config.cryptorType = type
        } label: {
          CheckRow(title: type.rawValue, isSelected: config.cryptorType == type)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var saveMasterKeySection: some View {
    Section("Auto Save MasterKey") {
      Button {
        selectSaveMasterKey(true)
      } label: {
        CheckRow(title: "Yes", isSelected: configService.canSaveMasterKey)
      }
      .buttonStyle(.plain)
      Button {
        selectSaveMasterKey(false)
      } label: {
        CheckRow(title: "No", isSelected: !configService.canSaveMasterKey)
      }
      .buttonStyle(.plain)
    }
  }

  private var saveConfigSection: some View {
    Section("Save Config") {
      Button {
        saveConfigToPasteboard()
      } label: {
        CheckRow(title: "Save config to pasteboard")
      }
      .buttonStyle(.plain)
    }
  }

  private var restoreConfigSection: some View {
    Section("Restore Config") {
      Button {
        restoreConfigFromPasteboard()
      } label: {
        CheckRow(title: "Restore config by pasteboard")
      }
      .buttonStyle(.plain)
    }
  }

  private var aboutSection: some View {
    Section("About") {
      Button {
        openURL(URL(string: "https://github.com/TBXark/PasswordX")!)
      } label: {
        CheckRow(
          title: "About",
          subtitle: "https://github.com/TBXark/PasswordX",
          isSelected: false)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Logic

  private var styleRows: [PasswordStyle] {
    var rows = [PasswordStyle.character]
    for separator in PasswordStyle.Separator.allCases {
      rows.append(.word(separator: separator, length: config.style.patternLength))
    }
    return rows
  }

  private func toggleCharacterType(_ type: PasswordCharacterType) {
    if config.characterType.contains(type) {
      guard config.characterType.count > 1 else {
        activeAlert = .chooseOne
        return
      }
      config.characterType.remove(type)
    } else {
      config.characterType.insert(type)
    }
  }

  private func selectSaveMasterKey(_ enable: Bool) {
    if enable, !configService.canSaveMasterKey {
      BiometricAuth.auth(localizedReason: "SaveMasterKey") { isSuccess, error in
        DispatchQueue.main.async {
          if isSuccess {
            self.configService.canSaveMasterKey = true
          } else {
            let reason = error?.localizedDescription ?? "Unknow reason"
            self.activeAlert = .biometricError(reason)
          }
        }
      }
    } else {
      configService.canSaveMasterKey = enable
      try? configService.update(config: configService.configValue)
    }
  }

  private func saveConfigToPasteboard() {
    if config != configService.configValue {
      activeAlert = .saveConfirm
    } else {
      UIPasteboard.general.string = (try? JSONEncoder().encode(config))?.base64EncodedString() ?? ""
      activeAlert = .saveSuccess
    }
  }

  private func restoreConfigFromPasteboard() {
    if let text = UIPasteboard.general.string,
      let data = Data(base64Encoded: text),
      let restored = try? JSONDecoder().decode(PasswordConfig.self, from: data)
    {
      activeAlert = .restoreConfirm(restored)
    } else {
      activeAlert = .restoreFailed
    }
  }
}

extension PasswordStyle {
  var patternLength: Int {
    switch self {
    case .character:
      return 4
    case .word(separator: _, let length):
      return length
    }
  }

  var example: String {
    switch self {
    case .character:
      return "xxxxxxxxxx"
    case .word(let separator, let length):
      return [String](repeating: [String](repeating: "x", count: length).joined(), count: 3).joined(
        separator: separator.char)
    }
  }

  var title: String {
    switch self {
    case .character:
      return "character"
    case .word(let separator, length: _):
      return separator.rawValue
    }
  }
}
