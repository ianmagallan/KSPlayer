//
//  DynamicInfoView.swift
//
//
//  Created by Ian Magallan on 10.03.24.
//

import SwiftUI

@available(iOS 16, tvOS 16, macOS 13, *)
public struct DynamicInfoView: View {
    @ObservedObject
    var dynamicInfo: DynamicInfo
    public var body: some View {
        LabeledContent("Display FPS", value: dynamicInfo.displayFPS, format: .number)
        LabeledContent("Audio Video sync", value: dynamicInfo.audioVideoSyncDiff, format: .number)
        LabeledContent("Dropped Frames", value: dynamicInfo.droppedVideoFrameCount + dynamicInfo.droppedVideoPacketCount, format: .number)
        LabeledContent("Bytes Read", value: dynamicInfo.bytesRead.kmFormatted + "B")
        LabeledContent("Audio bitrate", value: dynamicInfo.audioBitrate.kmFormatted + "bps")
        LabeledContent("Video bitrate", value: dynamicInfo.videoBitrate.kmFormatted + "bps")
    }
}
