//
//  PasswordXApp.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import SwiftUI

@main
struct PasswordXApp: App {

  init() {
    #if DEBUG
      DemoSnapshot.renderIfNeeded()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      GeneratorView()
        .preferredColorScheme(.light)
    }
  }
}
