//
//  ActivityIndicator.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import Cocoa
import AppKit
import SwiftUI

public struct ActivityIndicator {
    public enum Style {
        case medium
        case large
    }

    private var isAnimated: Bool = true
    private var style: Style? = Style.medium

    public init() {

    }
}

extension ActivityIndicator: NSViewRepresentable {
    public typealias Context = NSViewRepresentableContext<Self>
    public typealias NSViewType = NSProgressIndicator

    public func makeNSView(context: Context) -> NSViewType {
        let nsView = NSProgressIndicator()
        nsView.isIndeterminate = true
        nsView.style = .spinning
        nsView.sizeToFit()
        nsView.layer?.transform = CATransform3DMakeScale(1.0, 0.6, 0.0);
        nsView.controlSize = .small
        return nsView
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        isAnimated ? nsView.startAnimation(self) : nsView.stopAnimation(self)
    }
}

