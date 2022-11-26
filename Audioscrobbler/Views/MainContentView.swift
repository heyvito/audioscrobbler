//
//  MainContentView.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 25/11/2022.
//

import SwiftUI

struct MainContentView: View {
    @StateObject var watcher = Watcher()
    @StateObject var webService = WebService()
    @StateObject var defaults = Defaults.shared

    var body: some View {
        VStack {
            if defaults.token == nil {
                LoginView()
                    .environmentObject(watcher)
                    .environmentObject(webService)
                    .environmentObject(defaults)
                    .onAppear { watcher.start() }
            } else {
                MainView()
                    .environmentObject(watcher)
                    .environmentObject(webService)
                    .environmentObject(defaults)
            }
        }.onLoad {
            if defaults.token != nil {
                watcher.onTrackChanged = { track in
                    if let token = defaults.token {
                        Task {
                            print("Updating nowPlaying: \(track.description)")
                            try await webService.updateNowListening(token: token, track: track)
                        }
                    }
                }
                watcher.onScrobbleWanted = { track in
                    if let token = defaults.token {
                        Task {
                            print("Scrobbling: \(track.description)")
                            try await webService.doScrobble(token: token, track: track)
                        }
                    }
                }
                watcher.start()
            }
        }
    }
}

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
