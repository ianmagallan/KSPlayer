//
//  PlatformView.swift
//
//
//  Created by Ian Magallan Bosch on 10.03.24.
//

import SwiftUI

@available(iOS 15, tvOS 16, macOS 12, *)
public struct PlatformView<Content: View>: View {
    private let content: () -> Content
    public var body: some View {
        #if os(tvOS)
        ScrollView {
            content()
                .padding()
        }
        .pickerStyle(.navigationLink)
        #else
        Form {
            content()
        }
        #if os(macOS)
        .padding()
        #endif
        #endif
    }

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
}
