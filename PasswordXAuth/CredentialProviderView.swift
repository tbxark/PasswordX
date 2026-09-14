//
//  CredentialProviderView.swift
//  PasswordXAuth
//
//  Created by TBXark on 2019/10/11.
//  Copyright © 2019 TBXark. All rights reserved.
//

import PasswordCryptor
import SwiftUI

final class CredentialViewModel: ObservableObject {
  @Published var identity = ""
  @Published var masterKey = ""
}

struct CredentialProviderView: View {

  @ObservedObject var viewModel: CredentialViewModel
  var onCancel: () -> Void
  var onComplete: (String) -> Void

  @ObservedObject private var configService = PasswordConfigService.shared
  @State private var isMasterKeyHidden = true

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        passwordDisplay
          .padding(.top, 16)
        identityField
          .padding(.top, 16)
        masterKeyField
          .padding(.top, 16)
        historyList
          .padding(.top, 8)
      }
      .padding(.horizontal, 16)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("OK") {
            complete()
          }
        }
      }
      .onAppear(perform: autoLoadMasterKeyIfNeed)
    }
  }

  // MARK: - Subviews

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
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.fieldBackground, lineWidth: 1))
  }

  private var identityField: some View {
    TextField("Password identity", text: $viewModel.identity)
      .keyboardType(.URL)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .font(.system(size: 16, weight: .bold))
      .foregroundColor(Theme.text)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 12)
      .frame(height: 54)
      .background(Theme.fieldBackground)
      .cornerRadius(8)
  }

  private var masterKeyField: some View {
    HStack {
      Group {
        if isMasterKeyHidden {
          SecureField("Master key", text: $viewModel.masterKey)
        } else {
          TextField("Master key", text: $viewModel.masterKey)
        }
      }
      .keyboardType(.asciiCapable)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .font(.system(size: 16, weight: .bold))
      .foregroundColor(Theme.text)
      .multilineTextAlignment(.center)
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

  private var historyList: some View {
    List {
      Section("History") {
        ForEach(configService.identityHistory, id: \.self) { id in
          Button(id) {
            viewModel.identity = id
          }
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Theme.text)
        }
        .onDelete(perform: delete)
      }
    }
    .listStyle(.plain)
  }

  // MARK: - Logic

  private var password: String {
    let config = configService.configValue
    let cryptor = PasswordCryptorService.buildCryptor(type: config.cryptorType)
    return
      (try? cryptor.encrypt(
        masterKey: viewModel.masterKey, identity: viewModel.identity, config: config)) ?? ""
  }

  private func complete() {
    if !viewModel.identity.isEmpty {
      configService.addIdentity(id: viewModel.identity)
    }
    onComplete(password)
  }

  private func delete(at offsets: IndexSet) {
    for index in offsets {
      configService.removeIdentity(id: configService.identityHistory[index])
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
          self.viewModel.masterKey = key
        }
      }
    }
  }
}
