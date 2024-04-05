//
//  SyncBackendButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 5/4/24.
//

import Foundation
import HarmonyKit
import SwiftUI

struct SyncBackendButton: View {
    let backendPresentable: BackendPresentable

    var body: some View {
        Button {
            guard let backend = BackendsModel.shared.backends[backendPresentable.backendId] else {
                return
            }
            Task {
                if backendPresentable.scanning {
                    backend.cancelScan()
                } else {
                    await SyncController.shared.syncBackend(backend)
                }
            }
        } label: {
            if backendPresentable.scanning {
                Label("Cancel sync", systemImage: "stop")
            } else {
                Label("Sync", systemImage: "arrow.triangle.2.circlepath")
            }
        }
    }
}
