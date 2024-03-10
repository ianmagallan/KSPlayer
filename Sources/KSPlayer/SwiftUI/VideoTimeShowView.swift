//
//  VideoTimeShowView.swift
//
//
//  Created by Ian Magallan on 10.03.24.
//

import SwiftUI

@available(iOS 15, tvOS 15, macOS 12, *)
struct VideoTimeShowView: View {
    @ObservedObject
    var config: KSVideoPlayer.Coordinator
    @ObservedObject
    var model: ControllerTimeModel
    public var body: some View {
        if config.timemodel.totalTime == 0 {
            Text("Live Streaming")
        } else {
            HStack {
                Text(model.currentTime.toString(for: .minOrHour)).font(.caption2.monospacedDigit())
                Slider(value: Binding {
                    Double(model.currentTime)
                } set: { newValue, _ in
                    model.currentTime = Int(newValue)
                }, in: 0 ... Double(model.totalTime)) { onEditingChanged in
                    if onEditingChanged {
                        config.playerLayer?.pause()
                    } else {
                        config.seek(time: TimeInterval(model.currentTime))
                    }
                }
                .frame(maxHeight: 20)
                Text((model.totalTime).toString(for: .minOrHour)).font(.caption2.monospacedDigit())
            }
            .font(.system(.title2))
        }
    }
}
