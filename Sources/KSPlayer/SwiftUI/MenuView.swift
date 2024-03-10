//
//  MenuView.swift
//
//
//  Created by Ian Magallan on 10.03.24.
//

import SwiftUI

@available(iOS 15, tvOS 16, macOS 12, *)
public struct MenuView<Label, SelectionValue, Content>: View where Label: View, SelectionValue: Hashable, Content: View {
    public let selection: Binding<SelectionValue>
    @ViewBuilder
    public let content: () -> Content
    @ViewBuilder
    public let label: () -> Label
    @State
    private var showMenu = false
    
    public var body: some View {
        #if os(tvOS)
        Picker(selection: selection, content: content, label: label)
            .pickerStyle(.navigationLink)
            .frame(height: 50)
        #else
        Menu {
            Picker(selection: selection) {
                content()
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            // menu 里面的label无法调整大小
            label()
        }
        .menuIndicator(.hidden)
        #endif
    }
}
