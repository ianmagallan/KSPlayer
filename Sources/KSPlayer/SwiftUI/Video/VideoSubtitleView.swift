//
//  VideoSubtitleView.swift
//
//
//  Created by Ian Magallan on 10.03.24.
//

import SwiftUI

@available(iOS 16, tvOS 16, macOS 13, *)
struct VideoSubtitleView: View {
    @ObservedObject
    var model: SubtitleModel
    var body: some View {
        ZStack {
            ForEach(model.parts) { part in
                part.subtitleView
            }
        }
    }

    static func imageView(_ image: UIImage) -> some View {
        #if enableFeatureLiveText && canImport(VisionKit) && !targetEnvironment(simulator)
        if #available(macCatalyst 17.0, *) {
            return LiveTextImage(uiImage: image)
        } else {
            return Image(uiImage: image)
                .resizable()
        }
        #else
        return Image(uiImage: image)
            .resizable()
        #endif
    }
}

private extension SubtitlePart {
    @available(iOS 16, tvOS 16, macOS 13, *)
    @MainActor
    var subtitleView: some View {
        VStack {
            if let image {
                Spacer()
                GeometryReader { geometry in
                    let fitRect = image.fitRect(geometry.size)
                    VideoSubtitleView.imageView(image)
                        .offset(CGSize(width: fitRect.origin.x, height: fitRect.origin.y))
                        .frame(width: fitRect.size.width, height: fitRect.size.height)
                }
                // 不能加scaledToFit。不然的话图片的缩放比率会有问题。
//                .scaledToFit()
                .padding()
            } else if let text {
                let textPosition = textPosition ?? SubtitleModel.textPosition
                if textPosition.verticalAlign == .bottom || textPosition.verticalAlign == .center {
                    Spacer()
                }
                Text(AttributedString(text))
                    .font(Font(SubtitleModel.textFont))
                    .shadow(color: .black.opacity(0.9), radius: 1, x: 1, y: 1)
                    .foregroundColor(SubtitleModel.textColor)
                    .italic(SubtitleModel.textItalic)
                    .background(SubtitleModel.textBackgroundColor)
                    .multilineTextAlignment(.center)
                    .alignmentGuide(textPosition.horizontalAlign) {
                        $0[.leading]
                    }
                    .padding(textPosition.edgeInsets)
                #if !os(tvOS)
                    .textSelection(.enabled)
                #endif
                if textPosition.verticalAlign == .top || textPosition.verticalAlign == .center {
                    Spacer()
                }
            }
        }
    }
}
