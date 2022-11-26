//
//  MainView.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 24/11/2022.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var watcher: Watcher
    @EnvironmentObject var defaults: Defaults
    @State var privateSession: Bool = false
    @State var showPrivateSessionPopover: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if watcher.currentTrack != nil {
                PlayingItemView(track: $watcher.currentTrack, currentPosition: $watcher.currentPosition)
                    .opacity(defaults.privateSession ? 0.6 : 1)
                    .scaleEffect(defaults.privateSession ? 0.9 : 1)
                    .animation(.easeOut)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    Image("nocover")
                        .resizable()
                        .cornerRadius(6)
                        .frame(width: 92, height: 92)
                    VStack(alignment: .leading) {
                        Text("It's silent here... There's nothing playing.")
                    }
                }
            }
            Divider()
            HStack {
                Toggle("", isOn: $defaults.privateSession)
                    .toggleStyle(.switch)
                Text("Private Session")
                Button(action: { showPrivateSessionPopover = true }) {
                    Image(nsImage: NSImage(named: NSImage.Name("NSTouchBarGetInfoTemplate"))!)
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showPrivateSessionPopover) {
                    Text("A private session will prevent tracks from being scrobbled as long as it is turned on")
                        .padding()
                }
            }.padding()
            Divider()
            HeaderView()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
