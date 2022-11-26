//
//  ProgressBar.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import SwiftUI
import AppKit
import Combine

struct ProgressBar: View {
    private let value: Double
    private let maxValue: Double
    private let backgroundEnabled: Bool
    private let backgroundColor: Color
    private let foregroundColor: Color
    @State private var animationMode: Animation?

    private var popoverWillHidePublisher: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: NSNotification.Name("AudioscrobblerWillHide"))
            .eraseToAnyPublisher()
    }

    init(value: Double,
         maxValue: Double,
         backgroundEnabled: Bool = true,
         backgroundColor: Color = Color(.red),
         foregroundColor: Color = Color.red.opacity(0.3)) {
        self.value = value
        self.maxValue = maxValue
        self.backgroundEnabled = backgroundEnabled
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        ZStack {
            GeometryReader { geometryReader in
                if self.backgroundEnabled {
                    Capsule()
                        .foregroundColor(self.backgroundColor)
                        .opacity(0.3)
                }

                Capsule()
                    .frame(width: self.progress(value: self.value,
                                                maxValue: self.maxValue,
                                                width: geometryReader.size.width))
                    .foregroundColor(self.foregroundColor)
                    .animation(animationMode)
            }
        }
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                animationMode = .easeIn
            }
        }
        .onReceive(popoverWillHidePublisher, perform: { _ in
            animationMode = nil
        })
    }

    private func progress(value: Double,
                          maxValue: Double,
                          width: CGFloat) -> CGFloat {
        let percentage = value / maxValue
        return width * CGFloat(percentage)
    }
}
