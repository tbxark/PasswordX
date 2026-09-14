//
//  HistoryView.swift
//  PasswordX
//
//  Created by TBXark on 2019/10/10.
//  Copyright © 2019 TBXark. All rights reserved.
//

import SwiftUI

struct HistoryView: View {

  var onSelect: ((String) -> Void)?

  @ObservedObject private var configService = PasswordConfigService.shared
  @Environment(\.dismiss) private var dismiss
  @State private var editMode: EditMode = .inactive

  var body: some View {
    List {
      ForEach(configService.identityHistory, id: \.self) { id in
        Button {
          onSelect?(id)
          dismiss()
        } label: {
          Text(id)
            .font(.system(size: 14))
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
      .onDelete(perform: delete)
    }
    .navigationTitle("History")
    .navigationBarTitleDisplayMode(.inline)
    .environment(\.editMode, $editMode)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close") {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button(editMode == .active ? "Done" : "Edit") {
          editMode = editMode == .active ? .inactive : .active
        }
      }
    }
  }

  private func delete(at offsets: IndexSet) {
    for index in offsets {
      configService.removeIdentity(id: configService.identityHistory[index])
    }
  }
}
