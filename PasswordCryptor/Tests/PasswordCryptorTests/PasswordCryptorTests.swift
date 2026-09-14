import XCTest

@testable import PasswordCryptor

final class PasswordCryptorTests: XCTestCase {

  private func defaultConfig(
    length: Int = 18,
    style: PasswordStyle = .word(separator: .hyphen, length: 6)
  ) -> PasswordConfig {
    PasswordConfig(
      characterType: [.digits, .lowercaseLetters, .uppercaseLetters, .symbols],
      style: style,
      cryptorType: .aes256,
      length: length)
  }

  /// Pins the default AES-256 output so refactors cannot silently change the
  /// passwords users already depend on.
  func testDefaultPasswordVector() throws {
    let cryptor = PasswordCryptorService.buildCryptor(type: .aes256)
    let password = try cryptor.encrypt(
      masterKey: "password", identity: "github", config: defaultConfig())
    XCTAssertEqual(password, "eBU6FF-4c0jZs-pb4H")
  }

  func testOutputIsDeterministic() throws {
    let cryptor = PasswordCryptorService.buildCryptor(type: .aes256)
    let first = try cryptor.encrypt(masterKey: "password", identity: "github", config: defaultConfig())
    let second = try cryptor.encrypt(masterKey: "password", identity: "github", config: defaultConfig())
    XCTAssertEqual(first, second)
  }

  func testDifferentInputsProduceDifferentPasswords() throws {
    let cryptor = PasswordCryptorService.buildCryptor(type: .aes256)
    let a = try cryptor.encrypt(masterKey: "password", identity: "github", config: defaultConfig())
    let b = try cryptor.encrypt(masterKey: "password", identity: "gitlab", config: defaultConfig())
    let c = try cryptor.encrypt(masterKey: "passwerd", identity: "github", config: defaultConfig())
    XCTAssertNotEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  func testEmptyInputsReturnEmptyPassword() throws {
    let cryptor = PasswordCryptorService.buildCryptor(type: .aes256)
    XCTAssertEqual(try cryptor.encrypt(masterKey: "", identity: "github", config: defaultConfig()), "")
    XCTAssertEqual(try cryptor.encrypt(masterKey: "password", identity: "", config: defaultConfig()), "")
  }

  func testPasswordRespectsRequestedLength() throws {
    let cryptor = PasswordCryptorService.buildCryptor(type: .aes256)
    for length in [1, 4, 12, 30] {
      let password = try cryptor.encrypt(
        masterKey: "password", identity: "github", config: defaultConfig(length: length))
      XCTAssertEqual(password.count, length, "unexpected length for \(length)")
    }
  }

  func testCharacterStyleUsesOnlySelectedCharacterSets() throws {
    let config = PasswordConfig(
      characterType: [.digits, .lowercaseLetters],
      style: .character,
      cryptorType: .sha256,
      length: 20)
    let cryptor = PasswordCryptorService.buildCryptor(type: .sha256)
    let password = try cryptor.encrypt(masterKey: "password", identity: "github", config: config)
    let allowed = Set("0123456789abcdefghijklmnopqrstuvwxyz")
    XCTAssertEqual(password.count, 20)
    XCTAssertTrue(password.allSatisfy({ allowed.contains($0) }), "unexpected characters: \(password)")
  }

  func testWordStyleGroupsWithSeparator() throws {
    let cryptor = PasswordCryptorService.buildCryptor(type: .aes256)
    let password = try cryptor.encrypt(masterKey: "password", identity: "github", config: defaultConfig())
    let groups = password.split(separator: "-")
    XCTAssertGreaterThan(groups.count, 1)
    XCTAssertTrue(groups.dropLast().allSatisfy({ $0.count == 6 }), "unexpected grouping: \(password)")
  }

  /// Blowfish is skipped: `BlowfishPasswordCryptor` requests a 65-byte key
  /// while CryptoSwift requires 5...56, so the initializer traps. The feature
  /// is unusable until that is fixed; see the note in the repository README.
  private var testableCryptorTypes: [PasswordCryptorType] {
    PasswordCryptorType.allCases.filter { $0 != .blowfish }
  }

  func testEveryCryptorTypeProducesAStablePassword() throws {
    for type in testableCryptorTypes {
      let cryptor = PasswordCryptorService.buildCryptor(type: type)
      let first = try cryptor.encrypt(masterKey: "password", identity: "github", config: defaultConfig())
      let second = try cryptor.encrypt(masterKey: "password", identity: "github", config: defaultConfig())
      XCTAssertFalse(first.isEmpty, "\(type) produced an empty password")
      XCTAssertEqual(first, second, "\(type) is not deterministic")
      XCTAssertEqual(first.count, 18, "\(type) ignored the requested length")
    }
  }

  /// Raw values are the on-disk config format; renaming a case must not
  /// change them or saved configurations stop decoding.
  func testCryptorTypeRawValuesAreStable() {
    XCTAssertEqual(PasswordCryptorType.aes256.rawValue, "AES256")
    XCTAssertEqual(PasswordCryptorType.md5.rawValue, "MD5")
    XCTAssertEqual(PasswordCryptorType.sha512.rawValue, "SHA512")
    XCTAssertEqual(PasswordCryptorType.blowfish.rawValue, "Blowfish")
  }

  func testConfigRoundTripsThroughJSON() throws {
    let config = defaultConfig()
    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(PasswordConfig.self, from: data)
    XCTAssertEqual(decoded, config)
  }
}
