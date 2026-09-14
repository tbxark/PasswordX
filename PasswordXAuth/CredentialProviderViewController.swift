//
//  CredentialProviderViewController.swift
//  PasswordXAuth
//
//  Created by TBXark on 2019/10/11.
//  Copyright © 2019 TBXark. All rights reserved.
//

import AuthenticationServices
import SwiftUI

class CredentialProviderViewController: ASCredentialProviderViewController {

  private let viewModel = CredentialViewModel()
  private var hostingController: UIHostingController<CredentialProviderView>?

  override func viewDidLoad() {
    super.viewDidLoad()
    overrideUserInterfaceStyle = .light

    let providerView = CredentialProviderView(
      viewModel: viewModel,
      onCancel: { [weak self] in self?.cancelRequest() },
      onComplete: { [weak self] in self?.completeRequest(password: $0) })
    let controller = UIHostingController(rootView: providerView)
    controller.view.backgroundColor = .white
    addChild(controller)
    view.addSubview(controller.view)
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      controller.view.topAnchor.constraint(equalTo: view.topAnchor),
      controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    controller.didMove(toParent: self)
    hostingController = controller
  }

  override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    let host = serviceIdentifiers.compactMap { (id) -> String? in
      switch id.type {
      case .domain:
        return id.identifier
      case .URL:
        return URLComponents(string: id.identifier)?.host
      @unknown default:
        return id.identifier
      }
    }.first
    if let host = host {
      viewModel.identity = host
    }
  }

  private func cancelRequest() {
    extensionContext.cancelRequest(
      withError: NSError(
        domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
  }

  private func completeRequest(password: String) {
    let passwordCredential = ASPasswordCredential(user: "", password: password)
    extensionContext.completeRequest(
      withSelectedCredential: passwordCredential, completionHandler: nil)
  }
}
