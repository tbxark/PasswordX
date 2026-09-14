//
//  PasswordConfigService.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import Foundation
import PasswordCryptor

extension UserDefaults {
  static var passwordGroup: UserDefaults {
    return UserDefaults(suiteName: "group.tbxark.passwordx") ?? UserDefaults.standard
  }
}

class PasswordConfigService: ObservableObject {

  static let shared = PasswordConfigService()

  private struct Config {
    static let configCacheKey = "cache.config"
    static let masterKeyCachekey = "master.key"
    static let identityHistoryKey = "identity.history.key"
    static let canSaveMasterKeyCachekey = "can.save.master.key"
  }

  @Published private(set) var configValue: PasswordConfig

  @Published private(set) var identityHistory: [String]

  @Published var canSaveMasterKey: Bool {
    didSet {
      if !canSaveMasterKey {
        masterKey = nil
      }
      UserDefaults.passwordGroup.set(canSaveMasterKey, forKey: Config.canSaveMasterKeyCachekey)
    }
  }

  @Published var masterKey: String? {
    didSet {
      guard canSaveMasterKey else {
        return
      }
      UserDefaults.passwordGroup.set(masterKey, forKey: Config.masterKeyCachekey)
    }
  }

  private init() {
    let defaults = UserDefaults.passwordGroup
    let canSave = defaults.bool(forKey: Config.canSaveMasterKeyCachekey)
    let key = canSave ? defaults.string(forKey: Config.masterKeyCachekey) : nil
    self.canSaveMasterKey = canSave
    self.masterKey = key
    self.identityHistory = defaults.stringArray(forKey: Config.identityHistoryKey) ?? []
    if let json = defaults.data(forKey: Config.configCacheKey),
      let model = try? JSONDecoder().decode(PasswordConfig.self, from: json)
    {
      self.configValue = model
    } else {
      self.configValue = PasswordConfig(
        characterType: [.digits, .lowercaseLetters, .uppercaseLetters, .symbols],
        style: .word(separator: .hyphen, length: 6),
        cryptorType: .aes256,
        length: 18)
    }
  }

  func update(config: PasswordConfig) throws {
    self.configValue = config
    let json = try JSONEncoder().encode(config)
    UserDefaults.passwordGroup.set(json, forKey: Config.configCacheKey)
    UserDefaults.passwordGroup.synchronize()
  }

  func addIdentity(id: String) {
    var temp = identityHistory
    temp.removeAll(where: { $0 == id })
    temp.insert(id, at: 0)
    identityHistory = temp
    UserDefaults.passwordGroup.set(identityHistory, forKey: Config.identityHistoryKey)
  }

  func removeIdentity(id: String) {
    identityHistory = identityHistory.filter({ $0 != id })
    UserDefaults.passwordGroup.set(identityHistory, forKey: Config.identityHistoryKey)
  }

  func reloadConfig() throws {
    guard let json = UserDefaults.passwordGroup.data(forKey: Config.configCacheKey) else {
      return
    }
    let model = try JSONDecoder().decode(PasswordConfig.self, from: json)
    try update(config: model)
  }
}
