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
                    Image(systemName: "x.circle.fill")
                }
                #if !os(tvOS) && !os(xrOS)
                if config.playerLayer?.player.allowsExternalPlayback == true {
                    AirPlayView().fixedSize()
                }
                #endif
                Spacer()
                if let audioTracks = config.playerLayer?.player.tracks(mediaType: .audio), !audioTracks.isEmpty {
                    audioButton(audioTracks: audioTracks)
                }
                muteButton
                contentModeButton
                subtitleButton
            }
            Spacer()
            HStack {
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
                    Image(systemName: config.state == .error ? "play.slash.fill" : (config.state.isPlaying ? "pause.circle.fill" : "play.circle.fill"))
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
            Spacer()
            HStack {
                Text(title)
                    .font(.title3)
                ProgressView()
                    .opacity(config.state == .buffering ? 1 : 0)
                Spacer()
                playbackRateButton
                #if !os(xrOS)
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
        Button {
            config.isMuted.toggle()
        } label: {
            Image(systemName: config.isMuted ? "speaker.slash.circle.fill" : "speaker.wave.2.circle.fill")
        }
        .shadow(color: .black, radius: 1)
    }

    private var contentModeButton: some View {
        Button {
            config.isScaleAspectFill.toggle()
        } label: {
            Image(systemName: config.isScaleAspectFill ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
        }
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
        }
    }

    private var subtitleButton: some View {
        MenuView(selection: Binding {
            subtitleModel.selectedSubtitleInfo?.subtitleID
        } set: { value in
            let info = subtitleModel.subtitleInfos.first { $0.subtitleID == value }
            subtitleModel.selectedSubtitleInfo = info
            if let info = info as? MediaPlayerTrack {
                // 因为图片字幕想要实时的显示，那就需要seek。所以需要走select track
                config.playerLayer?.player.select(track: info)
            }
        }) {
            Text("Off").tag(nil as String?)
            ForEach(subtitleModel.subtitleInfos, id: \.subtitleID) { track in
                Text(track.name).tag(track.subtitleID as String?)
            }
        } label: {
            Image(systemName: "text.bubble.fill")
        }
    }

    private var playbackRateButton: some View {
        MenuView(selection: $config.playbackRate) {
            ForEach([0.5, 1.0, 1.25, 1.5, 2.0] as [Float]) { value in
                // 需要有一个变量text。不然会自动帮忙加很多0
                let text = "\(value) x"
                Text(text).tag(value)
            }
        } label: {
            Image(systemName: "gauge.with.dots.needle.67percent")
        }
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
