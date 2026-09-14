//
//  PasswordCryptor.swift
//  password
//
//  Created by TBXark on 2019/10/9.
//  Copyright © 2019 TBXark. All rights reserved.
//

import CryptoSwift
import Foundation

public struct PasswordConfig: Codable, Hashable {
  public var characterType: Set<PasswordCharacterType>
  public var style: PasswordStyle
  public var cryptorType: PasswordCryptorType
  public var length: Int

  public init(
    characterType: Set<PasswordCharacterType>,
    style: PasswordStyle,
    cryptorType: PasswordCryptorType,
    length: Int
  ) {
    self.characterType = characterType
    self.style = style
    self.cryptorType = cryptorType
    self.length = length
  }
}

public enum PasswordCharacterType: Int, Hashable, CaseIterable, Codable {

  private static let digitsList = "0123456789".map({ $0 })
  private static let digitsSet = Set(digitsList)
  case digits = 0

  private static let lowercaseLettersList = "abcdefghijklmnopqrstuvwxyz".map({ $0 })
  private static let lowercaseLettersSet = Set(lowercaseLettersList)
  case lowercaseLetters = 1

  private static let uppercaseLettersList = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map({ $0 })
  private static let uppercaseLettersSet = Set(uppercaseLettersList)
  case uppercaseLetters = 2

  private static let symbolsList = "!\"#$%&'()*+/:;<=>?@[\\]^`{|}~-,._".map({ $0 })
  private static let symbolsSet = Set(symbolsList)
  case symbols = 3

  public var characterarList: [Character] {
    switch self {
    case .digits:
      return PasswordCharacterType.digitsList
    case .lowercaseLetters:
      return PasswordCharacterType.lowercaseLettersList
    case .uppercaseLetters:
      return PasswordCharacterType.uppercaseLettersList
    case .symbols:
      return PasswordCharacterType.symbolsList
    }
  }

  var characterarSet: Set<Character> {
    switch self {
    case .digits:
      return PasswordCharacterType.digitsSet
    case .lowercaseLetters:
      return PasswordCharacterType.lowercaseLettersSet
    case .uppercaseLetters:
      return PasswordCharacterType.uppercaseLettersSet
    case .symbols:
      return PasswordCharacterType.symbolsSet
    }
  }

  public var title: String {
    switch self {
    case .digits:
      return "digits"
    case .lowercaseLetters:
      return "lowercaseLetters"
    case .uppercaseLetters:
      return "uppercaseLetters"
    case .symbols:
      return "symbols"
    }
  }

  public static func build(_ char: Character) -> PasswordCharacterType? {
    for t in PasswordCharacterType.allCases {
      if t.characterarSet.contains(char) {
        return t
      }
    }
    return nil
  }

  static func characterSet(from types: [PasswordCharacterType]) -> [Character] {
    var temp = [Character]()
    for t in PasswordCharacterType.allCases {
      if types.contains(t) {
        temp.append(contentsOf: t.characterarList)
      }
    }
    return temp
  }
}

public enum PasswordStyle: Hashable, Codable {

  public enum Separator: String, Hashable, Codable, CaseIterable {
    case hyphen
    case period
    case comma
    case underscore

    public var char: String {
      switch self {
      case .hyphen: return "-"
      case .period: return ","
      case .comma: return "."
      case .underscore: return "_"
      }
    }

  }

  case character
  case word(separator: Separator, length: Int)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawString = try container.decode(String.self)
    if rawString == "character" {
      self = .character
    } else {
      let items = rawString.split(separator: ",")
      if items.count == 3,
        items[0] == "word",
        let separator = Separator(rawValue: String(items[1])),
        let length = Int(items[2])
      {
        self = .word(separator: separator, length: length)
      } else {
        throw NSError(
          domain: "com.tbxark.passwordCryptor", code: 0,
          userInfo: [NSLocalizedFailureErrorKey: "Unknow PasswordStyle"])
      }
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .character:
      try container.encode("character")
    case .word(let separator, let length):
      try container.encode("word,\(separator.rawValue),\(length)")
    }
  }

}

public enum PasswordCryptorType: String, CaseIterable, Codable {
  // Raw values are the on-disk representation used by `PasswordConfig`;
  // keep them stable so previously saved configurations keep decoding.
  case md5 = "MD5"
  case sha1 = "SHA1"
  case sha224 = "SHA224"
  case sha256 = "SHA256"
  case sha384 = "SHA384"
  case sha512 = "SHA512"
  case crc32 = "CRC32"
  case crc32c = "CRC32C"
  case crc16 = "CRC16"
  case aes128 = "AES128"
  case aes192 = "AES192"
  case aes256 = "AES256"
  case chaCha20 = "ChaCha20"
  case rabbit = "Rabbit"
  case blowfish = "Blowfish"
}

public struct PasswordCryptorService {

  public static func buildCryptor(type: PasswordCryptorType) -> PasswordCryptor {
    switch type {
    case .md5:
      return MD5PasswordCryptor()
    case .sha1:
      return SHA1PasswordCryptor()
    case .sha224:
      return SHA224PasswordCryptor()
    case .sha256:
      return SHA256PasswordCryptor()
    case .sha384:
      return SHA384PasswordCryptor()
    case .sha512:
      return SHA512PasswordCryptor()
    case .crc16:
      return Crc16PasswordCryptor()
    case .crc32:
      return Crc32PasswordCryptor()
    case .crc32c:
      return Crc32cPasswordCryptor()
    case .aes128:
      return AES128PasswordCryptor()
    case .aes192:
      return AES192PasswordCryptor()
    case .aes256:
      return AES256PasswordCryptor()
    case .chaCha20:
      return ChaCha20PasswordCryptor()
    case .rabbit:
      return RabbitPasswordCryptor()
    case .blowfish:
      return BlowfishPasswordCryptor()
    }
  }

  static func encrypt(
    rawPassword: String, passwordCharacterSet: [PasswordCharacterType],
    passwordStyle: PasswordStyle, length: Int
  ) -> String {
    var raw = rawPassword
    guard raw.count > 0, length > 0, passwordCharacterSet.count > 0 else {
      return raw
    }
    var realPasswordCharacterSet = passwordCharacterSet
    var realPasswordStyle = passwordStyle
    switch realPasswordStyle {
    case .character:
      break
    case .word(separator: _, let separatorLength):
      if separatorLength == 0 || separatorLength >= (length - 1) {
        realPasswordStyle = .character
        break
      }
      if passwordCharacterSet.contains(.symbols) {
        realPasswordCharacterSet.removeAll(where: { $0 == .symbols })
      }

    }
    raw = filterInvalidCharacter(password: raw, passwordCharacterSet: realPasswordCharacterSet)
    raw = adjustPasswordLength(password: raw, length: length)
    switch realPasswordStyle {
    case .character:
      break
    case .word(let separator, _):
      raw = formatPassword(password: raw, style: realPasswordStyle)
      let lastChar = raw.last
      raw = String(raw.prefix(length))
      if let last = raw.last.map({ String($0) }),
        last == separator.char,
        let trailingChar = lastChar
      {
        raw = String(raw.prefix(length - 1))
        raw.append(trailingChar)
      }
    }
    raw = addMissingCharacterType(password: raw, passwordCharacterSet: realPasswordCharacterSet)
    return raw
  }

  private static func addMissingCharacterType(
    password: String, passwordCharacterSet: [PasswordCharacterType]
  ) -> String {
    var outputPassword = password.map({ $0 })
    let needCharTypes = Set(passwordCharacterSet)
    while true {
      let chars = outputPassword.map({ PasswordCharacterType.build($0) })
      let needAddTypes = Set(needCharTypes).subtracting(Set(chars.compactMap({ $0 })))
      if needCharTypes.count > chars.filter({ $0 != nil }).count {
        break
      }
      guard let replaceCharSet = needAddTypes.first?.characterarList else {
        break
      }
      let charTypeCount = chars.reduce(into: [PasswordCharacterType: Int]()) { (res, type) in
        guard let t = type else {
          return
        }
        res[t] = (res[t] ?? 0) + 1
      }
      var mostNumerousChar: (key: PasswordCharacterType, value: Int)?
      for (k, v) in charTypeCount {
        guard let last = mostNumerousChar else {
          mostNumerousChar = (key: k, value: v)
          continue
        }
        if last.value < v {
          mostNumerousChar = (key: k, value: v)
        }
      }
      guard let most = mostNumerousChar,
        most.value > 1,
        let replaceIndex = chars.firstIndex(of: most.key)
      else {
        break
      }
      let asciiValue = outputPassword[replaceIndex].asciiValue ?? 0
      outputPassword[replaceIndex] = replaceCharSet[Int(asciiValue) % replaceCharSet.count]
    }
    return String(outputPassword)
  }

  private static func adjustPasswordLength(password: String, length: Int) -> String {
    guard password.count != length else {
      return password
    }
    var outputPassword = ""
    if password.count > length {
      var chars = password.map({ $0 })
      for i in 0..<length {
        outputPassword.append(chars.remove(at: (length * i) % chars.count))
      }
    } else {
      outputPassword = password
      var chars = password.map({ $0 })
      for i in 0..<(length - password.count) {
        if chars.count == 0 {
          chars = password.map({ $0 }).reversed()
        }
        outputPassword.append(chars.remove(at: (length * i) % chars.count))
      }
    }
    return outputPassword
  }

  private static func filterInvalidCharacter(
    password: String, passwordCharacterSet: [PasswordCharacterType]
  ) -> String {
    var outputPassword = ""
    let characters = PasswordCharacterType.characterSet(from: passwordCharacterSet)
    let characterSet = Set(characters)
    for (i, c) in password.enumerated() {
      if characterSet.contains(c), i % 3 != 0 {
        outputPassword.append(c)
      } else {
        let idx = Int(c.asciiValue ?? 0)
        outputPassword.append(characters[idx % characters.count])
      }
    }
    return outputPassword
  }

  private static func formatPassword(password: String, style: PasswordStyle) -> String {
    switch style {
    case .character:
      return password
    case .word(let separator, let length):
      guard length > 0 && length < password.count else {
        return password
      }
      let raw = password.map({ $0 })
      var outputPasswordItemArray = [String]()
      let group = (password.count / length + (password.count % length > 0 ? 1 : 0))
      for i in 0..<group {
        let minIndex = (i * length)
        let maxIndex = min(((i + 1) * length), raw.count)
        outputPasswordItemArray.append(String(raw[minIndex..<maxIndex]))
      }
      return outputPasswordItemArray.joined(separator: separator.char)
    }
  }
}

public protocol PasswordCryptor {
  func generateRawPassword(masterKey: String, identity: String) throws -> String
  func encrypt(
    masterKey: String, identity: String, passwordCharacterSet: [PasswordCharacterType],
    passwordStyle: PasswordStyle, length: Int
  ) throws -> String
}

extension PasswordCryptor {

  public func encrypt(masterKey: String, identity: String, config: PasswordConfig) throws -> String
  {
    return try encrypt(
      masterKey: masterKey, identity: identity, passwordCharacterSet: Array(config.characterType),
      passwordStyle: config.style, length: config.length)
  }

  public func encrypt(
    masterKey: String, identity: String, passwordCharacterSet: [PasswordCharacterType],
    passwordStyle: PasswordStyle, length: Int
  ) throws -> String {
    guard !masterKey.isEmpty, !identity.isEmpty else {
      return ""
    }
    let raw = try generateRawPassword(masterKey: masterKey, identity: identity)
    return PasswordCryptorService.encrypt(
      rawPassword: raw, passwordCharacterSet: passwordCharacterSet, passwordStyle: passwordStyle,
      length: length)
  }

}

// MARK: - Hash (Digest)
// MD5 | SHA1 | SHA224 | SHA256 | SHA384 | SHA512 | SHA3

private protocol HashPasswordCryptor: PasswordCryptor {
  func hash(input: Data) -> Data
}

extension HashPasswordCryptor {
  func generateRawPassword(masterKey: String, identity: String) throws -> String {
    var raw = identity.count > masterKey.count ? (masterKey + identity) : (identity + masterKey)
    if let checkSum = raw.data(using: .utf8)?.checksum() {
      raw = "\(checkSum % 99)\(raw)"
    }
    let data = try JSONEncoder().encode(raw)
    let encryptString = hash(input: data).base64EncodedString()
    return encryptString
  }
}

private struct MD5PasswordCryptor: HashPasswordCryptor {
  func hash(input: Data) -> Data {
    return input.md5()
  }
}

private struct SHA1PasswordCryptor: HashPasswordCryptor {
  func hash(input: Data) -> Data {
    return input.sha1()
  }
}

private struct SHA224PasswordCryptor: HashPasswordCryptor {
  func hash(input: Data) -> Data {
    return input.sha224()
  }
}

private struct SHA256PasswordCryptor: HashPasswordCryptor {
  func hash(input: Data) -> Data {
    return input.sha256()
  }
}

private struct SHA384PasswordCryptor: HashPasswordCryptor {
  func hash(input: Data) -> Data {
    return input.sha384()
  }
}

private struct SHA512PasswordCryptor: HashPasswordCryptor {
  func hash(input: Data) -> Data {
    return input.sha512()
  }
}

// MARK: - Cyclic Redundancy Check (CRC)
// CRC32 | CRC32C | CRC16
private protocol CrcPasswordCryptor: PasswordCryptor {
  func crc(input: Data) -> Data
}

extension CrcPasswordCryptor {
  fileprivate func generateRawPassword(masterKey: String, identity: String) throws -> String {
    var raw = identity.count > masterKey.count ? (masterKey + identity) : (identity + masterKey)
    if let checkSum = raw.data(using: .utf8)?.checksum() {
      raw = "\(checkSum % 99)\(raw)"
    }
    let data = try JSONEncoder().encode(raw)
    let encryptString = crc(input: data).base64EncodedString()
    return encryptString
  }
}

private struct Crc16PasswordCryptor: CrcPasswordCryptor {
  func crc(input: Data) -> Data {
    return input.crc16()
  }
}

private struct Crc32PasswordCryptor: CrcPasswordCryptor {
  func crc(input: Data) -> Data {
    return input.crc32()
  }
}

private struct Crc32cPasswordCryptor: CrcPasswordCryptor {
  func crc(input: Data) -> Data {
    return input.crc32c()
  }
}

// MARK: - Cipher
// AES-128, AES-192, AES-256 | ChaCha20 | Rabbit | Blowfish
private protocol CipherPasswordCryptor: PasswordCryptor {
  var keyLength: Int { get }
  var ivLength: Int { get }
  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8]
}

extension CipherPasswordCryptor {
  func generateRawPassword(masterKey: String, identity: String) throws -> String {
    var keyRaw = masterKey
    var iv = [UInt8](repeating: 0, count: ivLength)

    if let checkSum = (masterKey + identity).data(using: .utf8)?.checksum() {
      keyRaw = "\(checkSum % 99)\(keyRaw)"
      if iv.count > 0 {
        iv[0] = UInt8(checkSum & 0x00ff)
      }
      if iv.count > 1 {
        iv[1] = UInt8(checkSum >> 8)
      }
    }

    var key = try JSONEncoder().encode(keyRaw).base64EncodedData().prefix(keyLength)
    if key.count < keyLength {
      key.append(contentsOf: [UInt8](repeating: 0, count: keyLength - key.count))
    }

    let identityData = Array((try JSONEncoder().encode(identity)).base64EncodedData())
    let passwordData = try encrypt(key: Array(key), iv: iv, data: identityData)

    return Data(passwordData).base64EncodedString()
  }

}

private struct ChaCha20PasswordCryptor: CipherPasswordCryptor {

  var keyLength: Int {
    return 32
  }
  var ivLength: Int {
    return 12
  }

  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
    let chacha = try ChaCha20(key: key, iv: iv)
    return try chacha.encrypt(data)
  }
}

private struct RabbitPasswordCryptor: CipherPasswordCryptor {

  var keyLength: Int {
    return Rabbit.keySize
  }
  var ivLength: Int {
    return Rabbit.ivSize
  }

  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
    let rabbit = try Rabbit(key: key, iv: iv)
    return try rabbit.encrypt(data)
  }
}

private struct BlowfishPasswordCryptor: CipherPasswordCryptor {

  var keyLength: Int {
    return 65
  }
  var ivLength: Int {
    return Blowfish.blockSize
  }

  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
    let blowfish = try Blowfish(key: key, padding: Padding.noPadding)
    return try blowfish.encrypt(data)
  }

}

private struct AES128PasswordCryptor: CipherPasswordCryptor {
  var keyLength: Int {
    return 16
  }
  var ivLength: Int {
    return AES.blockSize
  }

  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
    let aes = try AES(key: key, blockMode: CBC(iv: iv))
    return try aes.encrypt(data)
  }

}

private struct AES192PasswordCryptor: CipherPasswordCryptor {
  var keyLength: Int {
    return 24
  }
  var ivLength: Int {
    return AES.blockSize
  }

  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
    let aes = try AES(key: key, blockMode: CBC(iv: iv))
    return try aes.encrypt(data)
  }
}

private struct AES256PasswordCryptor: CipherPasswordCryptor {
  var keyLength: Int {
    return 32
  }
  var ivLength: Int {
    return AES.blockSize
  }

  func encrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
    let aes = try AES(key: key, blockMode: CBC(iv: iv))
    return try aes.encrypt(data)
  }
}
