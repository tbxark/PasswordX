//
//  DemoSnapshot.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import ImageIO
import SwiftUI
import UniformTypeIdentifiers

#if DEBUG
  // Renders the generator UI to a PNG file without showing a window.
  // Enabled only when PX_DEMO_SNAPSHOT (output path) is set.
  // ImageRenderer cannot draw live text fields, so GeneratorView swaps them
  // for styled text while this mode is active.
  enum DemoSnapshot {

    static var isActive: Bool {
      ProcessInfo.processInfo.environment["PX_DEMO_SNAPSHOT"] != nil
    }

    static func renderIfNeeded() {
      guard isActive, let path = ProcessInfo.processInfo.environment["PX_DEMO_SNAPSHOT"] else {
        return
      }
      Task { @MainActor in
        render(path: path)
      }
    }

    @MainActor
    private static func render(path: String) {
      let view = GeneratorView()
        .frame(width: 1000, height: 750)
      let renderer = ImageRenderer(content: view)
      renderer.scale = 2
      renderer.proposedSize = ProposedViewSize(width: 1000, height: 750)
      guard let image = renderer.cgImage else {
        FileHandle.standardError.write("DemoSnapshot: render failed\n".data(using: .utf8)!)
        exit(3)
      }
      let url = URL(fileURLWithPath: path)
      guard
        let dest = CGImageDestinationCreateWithURL(
          url as CFURL, UTType.png.identifier as CFString, 1, nil)
      else {
        exit(4)
      }
      CGImageDestinationAddImage(dest, image, nil)
      CGImageDestinationFinalize(dest)
      print("DemoSnapshot saved to \(url.path)")
      exit(0)
    }
  }
#endif
