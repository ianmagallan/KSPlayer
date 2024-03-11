//
//  VideoControllerView.swift
//
//
//  Created by Ian Magallan on 10.03.24.
//

import SwiftUI

@available(iOS 16, tvOS 16, macOS 13, *)
struct VideoControllerView: View {
    @ObservedObject
    var config: KSVideoPlayer.Coordinator
    @ObservedObject
    var subtitleModel: SubtitleModel
    @Binding
    var title: String
    var volumeSliderSize: Double?
    
    @State
    private var showVideoSetting = false
    @Environment(\.dismiss)
    private var dismiss
    
    public var body: some View {
        VStack {
            #if os(tvOS)
            Spacer()
            HStack {
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "x.circle.fill")
//                }
                Text(title)
                    .lineLimit(2)
                    .layoutPriority(2)
                Spacer()
                    .layoutPriority(1)
                ProgressView()
                    .opacity(config.state == .buffering ? 1 : 0)
                Spacer()
                    .layoutPriority(1)
                if let audioTracks = config.playerLayer?.player.tracks(mediaType: .audio), !audioTracks.isEmpty {
                    audioButton(audioTracks: audioTracks)
                }
                muteButton
                contentModeButton
                subtitleButton
                playbackRateButton
//                pipButton
                infoButton
            }
            #else
            HStack {
                Button {
                    dismiss()
                } label: {
                    #if os(xrOS)
                    Image(systemName: "xmark")
                    #else
                    Image(systemName: "x.circle.fill")
                    #endif
                }
                #if os(xrOS)
                .frame(width: 35, height: 35)
                .padding(8)
                .glassBackgroundEffect()
                #endif
                #if !os(tvOS) && !os(xrOS)
                if config.playerLayer?.player.allowsExternalPlayback == true {
                    AirPlayView().fixedSize()
                }
                #endif
                Spacer()
                if let audioTracks = config.playerLayer?.player.tracks(mediaType: .audio), !audioTracks.isEmpty {
                    audioButton(audioTracks: audioTracks)
                    #if os(xrOS)
                        .aspectRatio(1, contentMode: .fit)
                        .glassBackgroundEffect()
                    #endif
                }
                muteButton
                #if !os(xrOS)
                contentModeButton
                subtitleButton
                #endif
            }
            #if !os(xrOS)
            Spacer()
            KSVideoPlayerViewBuilder.playbackControlView(config: config)
            Spacer()
            #endif
            HStack {
            #if !os(xrOS)
                KSVideoPlayerViewBuilder.titleView(title: title, config: config)
                Spacer()
                playbackRateButton
                pipButton
                infoButton
                // iOS 模拟器加keyboardShortcut会导致KSVideoPlayer.Coordinator无法释放。真机不会有这个问题
                #if !os(tvOS)
                .keyboardShortcut("i", modifiers: [.command])
                #endif
                #endif
            }
            #endif
        }
        #if !os(tvOS)
        .font(.title)
        .buttonStyle(.borderless)
        #endif
        .sheet(isPresented: $showVideoSetting) {
            VideoSettingView(config: config, subtitleModel: config.subtitleModel, subtitleTitle: title)
        }
    }

    private var muteButton: some View {
        #if os(xrOS)
        HStack {
            Slider(value: $config.playbackVolume, in: 0...1)
                .onChange(of: config.playbackVolume, { _, newValue in
                config.isMuted = newValue == 0
            })
            .frame(width: volumeSliderSize ?? 100)
            .tint(.white.opacity(0.8))
            KSVideoPlayerViewBuilder.muteButton(config: config)
        }
        .padding(16)
        .glassBackgroundEffect()
        #else
        KSVideoPlayerViewBuilder.muteButton(config: config)
        #endif
    }

    private var contentModeButton: some View {
        KSVideoPlayerViewBuilder.contentModeButton(config: config)
    }

    private func audioButton(audioTracks: [MediaPlayerTrack]) -> some View {
        MenuView(selection: Binding {
            audioTracks.first { $0.isEnabled }?.trackID
        } set: { value in
            if let track = audioTracks.first(where: { $0.trackID == value }) {
                config.playerLayer?.player.select(track: track)
            }
        }) {
            ForEach(audioTracks, id: \.trackID) { track in
                Text(track.description).tag(track.trackID as Int32?)
            }
        } label: {
            Image(systemName: "waveform.circle.fill")
            #if os(xrOS)
                .padding()
                .clipShape(Circle())
            #endif
        }
    }

    private var subtitleButton: some View {
        KSVideoPlayerViewBuilder.subtitleButton(config: config)
    }

    private var playbackRateButton: some View {
        KSVideoPlayerViewBuilder.playbackRateButton(playbackRate: $config.playbackRate)
    }

    private var pipButton: some View {
        Button {
            config.playerLayer?.isPipActive.toggle()
        } label: {
            Image(systemName: "rectangle.on.rectangle.circle.fill")
        }
    }

    private var infoButton: some View {
        Button {
            showVideoSetting.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
    }
}

private extension EventModifiers {
    static let none = Self()
}
