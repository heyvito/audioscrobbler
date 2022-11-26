//
//  Link.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import SwiftUI

struct Link: View {
    var destination: URL
    var text: any StringProtocol

    init(_ text: any StringProtocol, destination: URL) {
        self.destination = destination
        self.text = text
    }

    var body: some View {
        Button(text) {
            NSWorkspace.shared.open(self.destination)
        }
            .buttonStyle(.link)
    }
}

struct Link_Previews: PreviewProvider {
    static var previews: some View {
        Link("Hello", destination: URL(string: "https://vito.io")!)
    }
}
