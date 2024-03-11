//
//  File.swift
//  KSPlayer
//
//  Created by kintan on 2022/1/29.
//
import AVFoundation
import MediaPlayer
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
public struct KSVideoPlayerView: View {
    private let subtitleDataSouce: SubtitleDataSouce?
    @Binding
    private var title: String
    @StateObject
    private var playerCoordinator: KSVideoPlayer.Coordinator
    @Environment(\.dismiss)
    private var dismiss
    @FocusState
    private var focusableField: FocusableField?
    public let options: KSOptions
    @Binding
    public var url: URL?

    public init(
        coordinator: KSVideoPlayer.Coordinator = KSVideoPlayer.Coordinator(),
        url: Binding<URL?>,
        options: KSOptions = .init(),
        title: Binding<String>? = nil,
        subtitleDataSouce: SubtitleDataSouce? = nil
    ) {
        _url = url
        _playerCoordinator = .init(wrappedValue: coordinator)
        _title = title ?? .constant(url.wrappedValue?.lastPathComponent ?? "")
        #if os(macOS)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        #endif
        self.options = options
        self.subtitleDataSouce = subtitleDataSouce
    }

    public var body: some View {
        ZStack {
            GeometryReader { proxy in
                if let url {
                    playView(url: url)
                }
                #if os(xrOS)
                HStack {
                    Spacer()
                    VideoSubtitleView(model: playerCoordinator.subtitleModel)
                    Spacer()
                }
                .padding([.bottom], 24)
                #else
                VideoSubtitleView(model: playerCoordinator.subtitleModel)
                #endif
                #if os(macOS)
                controllerView.opacity(playerCoordinator.isMaskShow ? 1 : 0)
                #else
                if playerCoordinator.isMaskShow {
                    controllerView(playerWidth: proxy.size.width)
                }
                #endif
            }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .automatic)
        #if os(tvOS)
            .onPlayPauseCommand {
                if playerCoordinator.state.isPlaying {
                    playerCoordinator.playerLayer?.pause()
                } else {
                    playerCoordinator.playerLayer?.play()
                }
            }
            .onExitCommand {
                if playerCoordinator.isMaskShow {
                    playerCoordinator.isMaskShow = false
                } else {
                    dismiss()
                }
            }
        #endif
    }

    private func playView(url: URL) -> some View {
        KSVideoPlayer(coordinator: playerCoordinator, url: url, options: options)
            .onStateChanged { playerLayer, state in
                if state == .readyToPlay {
                    if let movieTitle = playerLayer.player.dynamicInfo?.metadata["title"] {
                        title = movieTitle
                    }
                }
            }
            .onBufferChanged { bufferedCount, consumeTime in
                print("bufferedCount \(bufferedCount), consumeTime \(consumeTime)")
            }
        #if canImport(UIKit)
            .onSwipe { _ in
                playerCoordinator.isMaskShow = true
            }
        #endif
            .ignoresSafeArea()
            .onAppear {
                focusableField = .play
                if let subtitleDataSouce {
                    playerCoordinator.subtitleModel.addSubtitle(dataSouce: subtitleDataSouce)
                }
                // 不要加这个，不然playerCoordinator无法释放，也可以在onDisappear调用removeMonitor释放
                //                    #if os(macOS)
                //                    NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
                //                        isMaskShow = overView
                //                        return $0
                //                    }
                //                    #endif
            }

        #if os(iOS) || os(xrOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        #if !os(iOS)
            .focusable(!playerCoordinator.isMaskShow)
        .focused($focusableField, equals: .play)
        #endif
        #if !os(xrOS)
            .onKeyPressLeftArrow {
            playerCoordinator.skip(interval: -15)
        }
        .onKeyPressRightArrow {
            playerCoordinator.skip(interval: 15)
        }
        .onKeyPressSapce {
            if playerCoordinator.state.isPlaying {
                playerCoordinator.playerLayer?.pause()
            } else {
                playerCoordinator.playerLayer?.play()
            }
        }
        #endif
        #if os(macOS)
            .onTapGesture(count: 2) {
                guard let view = playerCoordinator.playerLayer else {
                    return
                }
                view.window?.toggleFullScreen(nil)
                view.needsLayout = true
                view.layoutSubtreeIfNeeded()
        }
        .onExitCommand {
            playerCoordinator.playerLayer?.exitFullScreenMode()
        }
        .onMoveCommand { direction in
            switch direction {
            case .left:
                playerCoordinator.skip(interval: -15)
            case .right:
                playerCoordinator.skip(interval: 15)
            case .up:
                playerCoordinator.playerLayer?.player.playbackVolume += 0.2
            case .down:
                playerCoordinator.playerLayer?.player.playbackVolume -= 0.2
            @unknown default:
                break
            }
        }
        #else
        .onTapGesture {
                playerCoordinator.isMaskShow.toggle()
            }
        #endif
        #if os(tvOS)
            .onMoveCommand { direction in
            switch direction {
            case .left:
                playerCoordinator.skip(interval: -15)
            case .right:
                playerCoordinator.skip(interval: 15)
            case .up, .down:
                playerCoordinator.isMaskShow.toggle()
            @unknown default:
                break
            }
        }
        #else
        .onHover { _ in
                playerCoordinator.isMaskShow = true
            }
            .onDrop(of: ["public.file-url"], isTargeted: nil) { providers -> Bool in
                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, _ in
                    if let data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                        openURL(url)
                    }
                }
                return true
            }
        #endif
    }

    private func controllerView(playerWidth: Double) -> some View {
        VStack {
            // 设置opacity为0，还是会去更新View。所以只能这样了
            VideoControllerView(
                config: playerCoordinator,
                subtitleModel: playerCoordinator.subtitleModel,
                title: $title,
                volumeSliderSize: playerWidth / 6
            )
            #if !os(xrOS)
            VideoTimeShowView(config: playerCoordinator, model: playerCoordinator.timemodel)
            #endif
        }
        #if os(xrOS)
        .ornament(attachmentAnchor: .scene(.bottom)) {
            bottomOrnamentView(playerWidth: playerWidth)
        }
        #endif
        .focused($focusableField, equals: .controller)
        .onAppear {
            focusableField = .controller
        }
        .onDisappear {
            focusableField = .play
        }
        .padding()
    }
    
    private func bottomOrnamentView(playerWidth: Double) -> some View {
        VStack(alignment: .center) {
            KSVideoPlayerViewBuilder.titleView(title: title, config: playerCoordinator)
            playerControlsView(playerWidth: playerWidth)
        }
        .buttonStyle(.plain)
            .padding([.all], 24)
            .glassBackgroundEffect()
    }
    
    private func playerControlsView(playerWidth: Double) -> some View {
        HStack(spacing: 16) {
            KSVideoPlayerViewBuilder.playbackControlView(config: playerCoordinator)
            VideoTimeShowView(
                config: playerCoordinator,
                model: playerCoordinator.timemodel,
                timeFont: .title3.monospacedDigit()
            )
                .frame(width: playerWidth / 2)
            HStack {
                Spacer()
                KSVideoPlayerViewBuilder.contentModeButton(config: playerCoordinator)
                KSVideoPlayerViewBuilder.subtitleButton(config: playerCoordinator)
                KSVideoPlayerViewBuilder.playbackRateButton(playbackRate: $playerCoordinator.playbackRate)
                Spacer()
            }
            .font(.largeTitle)
        }
    }
    
    fileprivate enum FocusableField {
        case play, controller
    }

    public func openURL(_ url: URL) {
        runInMainqueue {
            if url.isAudio || url.isMovie {
                self.url = url
            } else {
                let info = URLSubtitleInfo(url: url)
                playerCoordinator.subtitleModel.selectedSubtitleInfo = info
            }
        }
    }
}

extension View {
    func onKeyPressLeftArrow(action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
            return onKeyPress(.leftArrow) {
                action()
                return .handled
            }
        } else {
            return self
        }
    }

    func onKeyPressRightArrow(action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
            return onKeyPress(.rightArrow) {
                action()
                return .handled
            }
        } else {
            return self
        }
    }

    func onKeyPressSapce(action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
            return onKeyPress(.space) {
                action()
                return .handled
            }
        } else {
            return self
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct KSVideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!
        KSVideoPlayerView(url: .constant(url), options: KSOptions())
    }
}

// struct AVContentView: View {
//    var body: some View {
//        StructAVPlayerView().frame(width: UIScene.main.bounds.width, height: 400, alignment: .center)
//    }
// }
//
// struct StructAVPlayerView: UIViewRepresentable {
//    let playerVC = AVPlayerViewController()
//    typealias UIViewType = UIView
//    func makeUIView(context _: Context) -> UIView {
//        playerVC.view
//    }
//
//    func updateUIView(_: UIView, context _: Context) {
//        playerVC.player = AVPlayer(url: URL(string: "https://bitmovin-a.akamaihd.net/content/dataset/multi-codec/hevc/stream_fmp4.m3u8")!)
//    }
// }
