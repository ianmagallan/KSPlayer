//
//  KSVideoPlayerViewBuilder.swift
//
//
//  Created by Ian Magallan on 10.03.24.
//

import SwiftUI

enum KSVideoPlayerViewBuilder {
    
    static func playbackControlView(config: KSVideoPlayer.Coordinator) -> some View {
        #if os(xrOS)
        let spacing: CGFloat = 8
        #else
        let spacing: CGFloat = 0
        #endif
        
        return HStack(spacing: spacing) {
            Spacer()
            if config.playerLayer?.player.seekable ?? false {
                Button {
                    config.skip(interval: -15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.largeTitle)
                }
                #if !os(tvOS)
                .keyboardShortcut(.leftArrow, modifiers: .none)
                #endif
            }
            Spacer()
            Button {
                if config.state.isPlaying {
                    config.playerLayer?.pause()
                } else {
                    config.playerLayer?.play()
                }
            } label: {
                Image(systemName: config.state == .error ? playSlashSystemName : (config.state.isPlaying ? pauseSystemName : playSystemName))
                    .font(.largeTitle)
            }
            #if !os(tvOS)
            .keyboardShortcut(.space, modifiers: .none)
            #endif
            Spacer()
            if config.playerLayer?.player.seekable ?? false {
                Button {
                    config.skip(interval: 15)
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.largeTitle)
                }
                #if !os(tvOS)
                .keyboardShortcut(.rightArrow, modifiers: .none)
                #endif
            }
            Spacer()
        }
    }
    
    static func contentModeButton(config: KSVideoPlayer.Coordinator) -> some View {
        Button {
            config.isScaleAspectFill.toggle()
        } label: {
            Image(systemName: config.isScaleAspectFill ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
        }
    }
    
    static func subtitleButton(config: KSVideoPlayer.Coordinator) -> some View {
        MenuView(selection: Binding {
            config.subtitleModel.selectedSubtitleInfo?.subtitleID
        } set: { value in
            let info = config.subtitleModel.subtitleInfos.first { $0.subtitleID == value }
            config.subtitleModel.selectedSubtitleInfo = info
            if let info = info as? MediaPlayerTrack {
                // 因为图片字幕想要实时的显示，那就需要seek。所以需要走select track
                config.playerLayer?.player.select(track: info)
            }
        }) {
            Text("Off").tag(nil as String?)
            ForEach(config.subtitleModel.subtitleInfos, id: \.subtitleID) { track in
                Text(track.name).tag(track.subtitleID as String?)
            }
        } label: {
            Image(systemName: "text.bubble.fill")
        }
    }
}

// MARK: - Private functions

private extension KSVideoPlayerViewBuilder {
    
    static var playSlashSystemName: String {
        "play.slash.fill"
    }
    
    static var playSystemName: String {
        #if os(xrOS)
        "play.fill"
        #else
        "play.circle.fill"
        #endif
    }
    
    static var pauseSystemName: String {
        #if os(xrOS)
        "pause"
        #else
        "pause.circle.fill"
        #endif
    }
}


// MARK: - EventModifiers

private extension EventModifiers {
    static let none = Self()
}
