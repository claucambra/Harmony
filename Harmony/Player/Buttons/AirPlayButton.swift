//
//  AirPlayButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 19/2/24.
//

import SwiftUI

import AVKit

#if os(macOS)
fileprivate struct InternalMacAirPlayButton: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        let routePickerView = AVRoutePickerView()
        routePickerView.isRoutePickerButtonBordered = false
        PlayerController.shared.configureRoutePickerView(routePickerView)
        return AVRoutePickerView()
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        return
    }
}
#endif

struct AirPlayButton: View {
    #if !os(macOS)
    private let internalButton = AVRoutePickerView()
    #endif

    var body: some View {
        #if os(macOS)
        InternalMacAirPlayButton()
        #else
        Button {
            for view: UIView in internalButton.subviews {
                if let button = view as? UIButton {
                    button.sendActions(for: .touchUpInside)
                    break
                }
            }
        } label: {
            Label("Choose output device", systemImage: "airplayaudio")
        }
        #endif
    }
}
