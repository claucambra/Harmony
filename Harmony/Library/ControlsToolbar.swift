//
//  ControlsToolbar.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/2/24.
//

import SwiftUI

struct ControlsToolbar: ToolbarContent {
    @Binding var queueVisible: Bool

    #if os(macOS)
    let buttonStackInToolbar = true
    let displayVolumeSlider = true
    #else
    let buttonStackInToolbar = UIDevice.current.userInterfaceIdiom != .phone
    let displayVolumeSlider = false
    #endif

    var body: some ToolbarContent {
        if buttonStackInToolbar {
            ToolbarItemGroup {
                ShuffleButton()
                ChangeSongButton(buttonChangeType: .previous)
                PlayButton()
                ChangeSongButton(buttonChangeType: .next)
                RepeatButton()
            }

            ToolbarItem {
                Spacer()
            }
        }

        #if os(macOS)
        ToolbarItem {
            ToolbarCurrentSongView()
        }
        #endif

        if displayVolumeSlider {
            ToolbarItem {
                Spacer()
            }
            
            ToolbarItem {
                ToolbarVolumeSliderView()
            }
        }

        #if !os(macOS)
        if UIDevice.current.userInterfaceIdiom != .phone {
            ToolbarItem {
                AirPlayButton()
            }
            inspectorToolbarItem
        }
        #endif
    }
}
