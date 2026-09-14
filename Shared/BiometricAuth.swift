//
//  BiometricAuth.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/12.
//  Copyright © 2019 TBXark. All rights reserved.
//

import Foundation
import LocalAuthentication

class BiometricAuth {
  typealias BiometricAuthType = LABiometryType

  static func biometricAuthType() -> BiometricAuthType {
    return LAContext().biometryType
  }

  static func isBiometricAuthenticationAvailable() -> Bool {
    var error: NSError?
    if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      return error == nil
    } else {
      return false
    }
  }

  static func auth(localizedReason: String, completion: @escaping (Bool, Error?) -> Void) {
    LAContext().evaluatePolicy(
      LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason,
      reply: completion)
  }
}
