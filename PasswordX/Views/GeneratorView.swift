//
//  GeneratorView.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import PasswordCryptor
import SwiftUI

struct GeneratorView: View {

  private enum Field: Hashable {
    case identity
    case masterKey
  }

  private struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
  }

  @ObservedObject private var configService = PasswordConfigService.shared

  @State private var identity = ProcessInfo.processInfo.environment["PX_DEMO_IDENTITY"] ?? ""
  @State private var masterKey = ProcessInfo.processInfo.environment["PX_DEMO_MASTERKEY"] ?? ""
  @State private var isMasterKeyHidden = true
  @State private var showSetting = false
  @State private var showHistory = false
  @State private var showRestoreMasterKey = false
  @State private var toast: String?
  @State private var alertState: AlertState?
  @State private var pendingFocus: Field?
  @State private var lastRestoreMasterKeyDate: Date?

  @FocusState private var focusedField: Field?
  @Environment(\.scenePhase) private var scenePhase

  private static let isSnapshot = ProcessInfo.processInfo.environment["PX_DEMO_SNAPSHOT"] != nil

  var body: some View {
    VStack(spacing: 0) {
      headerView
      identityField
        .padding(.top, Theme.space)
      masterKeyField
        .padding(.top, Theme.space)
      restoreMasterKeyButton
        .padding(.top, 8)
      Spacer()
      settingButton
        .padding(.bottom, 30)
    }
    .background(Color.white)
    .onAppear(perform: autoLoadMasterKeyIfNeed)
    .onChange(of: masterKey) { newValue in
      saveMasterKeyIfNeed(newValue)
    }
    .onChange(of: scenePhase) { phase in
      handleScenePhase(phase)
    }
    .sheet(isPresented: $showSetting) {
      SettingView()
    }
    .sheet(isPresented: $showHistory) {
      NavigationStack {
        HistoryView { id in
          identity = id
          if !masterKey.isEmpty {
            copyPassword()
          }
        }
      }
    }
    .alert(
      alertState?.title ?? "",
      isPresented: Binding(get: { alertState != nil }, set: { if !$0 { alertState = nil } }),
      presenting: alertState
    ) { _ in
      Button("OK", role: .cancel) {
        guard let field = pendingFocus else {
          return
        }
        pendingFocus = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          focusedField = field
        }
      }
    } message: { state in
      Text(state.message)
    }
  }

  // MARK: - Subviews

  private var headerView: some View {
    VStack(spacing: 0) {
      Text("PasswordX")
        .font(.system(size: 30, weight: .bold))
        .foregroundColor(.white)
      Text("Master key + Identity + Configuration = Unique password")
        .font(.system(size: 12))
        .foregroundColor(.white)
        .padding(.top, 6)
      passwordDisplay
        .padding(.top, 20)
      copyButton
        .padding(.top, Theme.space)
    }
    .padding(.top, 100)
    .padding(.bottom, Theme.space)
    .frame(maxWidth: .infinity)
    .background(Theme.header.ignoresSafeArea(edges: .top))
    .overlay {
      toastView
    }
  }

  private var passwordDisplay: some View {
    Group {
      if password.isEmpty {
        Text("PasswordX")
          .foregroundColor(Color(UIColor.placeholderText))
      } else {
        PasswordText.render(password: password)
      }
    }
    .font(.system(size: 18, weight: .bold))
    .lineLimit(1)
    .minimumScaleFactor(0.2)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, minHeight: 54)
    .background(Color.white)
    .cornerRadius(8)
    .padding(.horizontal, Theme.space)
  }

  private var copyButton: some View {
    Button(action: copyPassword) {
      Text("Copy Secure Password")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.white)
        .frame(width: 260, height: 50)
        .background(Theme.copyButton)
        .cornerRadius(25)
    }
  }

  private var identityField: some View {
    VStack(alignment: .leading, spacing: 0) {
      fieldLabel("Password identity")
        .frame(height: 30)
      HStack {
        #if DEBUG
          if Self.isSnapshot {
            Text(identity.isEmpty ? "Password identity" : identity)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .foregroundColor(identity.isEmpty ? Color(UIColor.placeholderText) : Theme.text)
          } else {
            identityInput
          }
        #else
          identityInput
        #endif
        Button {
          showHistory = true
        } label: {
          Image("history")
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 12)
      .frame(height: 54)
      .background(Theme.fieldBackground)
      .cornerRadius(8)
    }
    .padding(.horizontal, Theme.space)
  }

  private var masterKeyField: some View {
    VStack(alignment: .leading, spacing: 0) {
      fieldLabel("Master key")
        .frame(height: 30)
      HStack {
        #if DEBUG
          if Self.isSnapshot {
            Text(
              isMasterKeyHidden ? String(repeating: "●", count: max(masterKey.count, 0)) : masterKey
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .foregroundColor(masterKey.isEmpty ? Color(UIColor.placeholderText) : Theme.text)
          } else {
            masterKeyInput
          }
        #else
          masterKeyInput
        #endif
        Button {
          isMasterKeyHidden.toggle()
        } label: {
          Image(isMasterKeyHidden ? "visibility_on" : "visibility_off")
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 12)
      .frame(height: 54)
      .background(Theme.fieldBackground)
      .cornerRadius(8)
    }
    .padding(.horizontal, Theme.space)
  }

  @ViewBuilder private var restoreMasterKeyButton: some View {
    if showRestoreMasterKey {
      Button("Restore master key") {
        restoreMasterKey()
      }
      .font(.system(size: 10))
      .foregroundColor(Theme.restore)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, Theme.space)
    }
  }

  private var identityInput: some View {
    TextField("Password identity", text: $identity)
      .keyboardType(.URL)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .font(.system(size: 16, weight: .bold))
      .foregroundColor(Theme.text)
      .multilineTextAlignment(.center)
      .focused($focusedField, equals: .identity)
  }

  private var masterKeyInput: some View {
    Group {
      if isMasterKeyHidden {
        SecureField("Master key", text: $masterKey)
      } else {
        TextField("Master key", text: $masterKey)
      }
    }
    .keyboardType(.asciiCapable)
    .textInputAutocapitalization(.never)
    .autocorrectionDisabled()
    .font(.system(size: 16, weight: .bold))
    .foregroundColor(Theme.text)
    .multilineTextAlignment(.center)
    .focused($focusedField, equals: .masterKey)
  }

  private var settingButton: some View {
    Button {
      showSetting = true
    } label: {
      Image("setting")
        .resizable()
        .frame(width: 80, height: 80)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder private var toastView: some View {
    if let toast = toast {
      Text(toast)
        .font(.system(size: 16))
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .transition(.opacity.combined(with: .scale(scale: 1.2)))
    }
  }

  private func fieldLabel(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 12))
      .foregroundColor(Theme.text)
  }

  // MARK: - Logic

  private var password: String {
    let config = configService.configValue
    let cryptor = PasswordCryptorService.buildCryptor(type: config.cryptorType)
    return (try? cryptor.encrypt(masterKey: masterKey, identity: identity, config: config)) ?? ""
  }

  private func copyPassword() {
    if identity.isEmpty {
      alertState = AlertState(title: "Warning", message: "Please enter identity value.")
      pendingFocus = .identity
    } else if masterKey.isEmpty {
      alertState = AlertState(title: "Warning", message: "Please enter master key.")
      pendingFocus = .masterKey
    } else {
      UIPasteboard.general.string = password
      configService.addIdentity(id: identity)
      showToast("Copied!")
    }
  }

  private func showToast(_ text: String) {
    withAnimation(.easeIn(duration: 0.2)) {
      toast = text
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      withAnimation(.easeOut(duration: 0.2)) {
        self.toast = nil
      }
    }
  }

  private func saveMasterKeyIfNeed(_ key: String) {
    guard configService.canSaveMasterKey, key != configService.masterKey else {
      return
    }
    configService.masterKey = key
  }

  private func handleScenePhase(_ phase: ScenePhase) {
    guard phase == .active else {
      return
    }
    if let date = lastRestoreMasterKeyDate, (-date.timeIntervalSinceNow) > 60 * 3 {
      masterKey = ""
      autoLoadMasterKeyIfNeed()
    }
  }

  private func autoLoadMasterKeyIfNeed() {
    guard configService.canSaveMasterKey,
      let key = configService.masterKey,
      !key.isEmpty
    else {
      return
    }
    BiometricAuth.auth(localizedReason: "SaveMasterKey") { isSuccess, _ in
      DispatchQueue.main.async {
        if isSuccess {
          self.lastRestoreMasterKeyDate = Date()
          self.masterKey = key
        } else {
          self.lastRestoreMasterKeyDate = nil
          self.showRestoreMasterKey = true
        }
      }
    }
  }

  private func restoreMasterKey() {
    BiometricAuth.auth(localizedReason: "SaveMasterKey") { isSuccess, error in
      DispatchQueue.main.async {
        if isSuccess {
          self.lastRestoreMasterKeyDate = Date()
          self.masterKey = self.configService.masterKey ?? ""
          self.showRestoreMasterKey = false
        } else {
          self.lastRestoreMasterKeyDate = nil
          let reason = error?.localizedDescription ?? "Unknow reason"
          self.alertState = AlertState(title: "Error", message: reason)
        }
      }
    }
  }
}
