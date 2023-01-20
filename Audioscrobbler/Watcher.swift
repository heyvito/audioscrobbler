//
//  State.swift
//  Scrobbler
//
//  Created by Victor Gama on 24/11/2022.
//

import Foundation
import AppKit
import OSAKit

enum PlayerState {
    case unknown
    case stopped
    case ‌playing
    case ‌paused
    case seeking
}

class Track {
    var artist: String
    var album: String
    var name: String
    var length: Double
    var artwork: Data?
    var year: Int32
    var scrobbled: Bool
    var loved: Bool
    var startedAt: Int32
    
    init(artist: String, album: String, name: String, year: Int32, length: Double, artwork: Data?, loved: Bool, startedAt: Int32) {
        self.artist = artist
        self.album = album
        self.name = name
        self.length = length
        self.artwork = artwork
        self.year = year
        self.scrobbled = false
        self.loved = loved
        self.startedAt = startedAt
    }

    var description: String {
        get {
            "\(name) - \(artist) on \(album) (\(year))"
        }
    }
}

enum ScriptError: Error {
    case InitializationError
    case InternalError(String)
}

class Watcher: ObservableObject {
    let MUSIC_STATE_SCRIPT = """
        tell application "Music" to get player state
    """
    let MUSIC_PLAYER_POSITION_SCRIPT = """
        tell application "Music" to get the player position
    """
    let MUSIC_TRACK_NAME_SCRIPT = """
        tell application "Music" to get the name of the current track
    """
    let MUSIC_TRACK_ARTIST_SCRIPT = """
        tell application "Music" to get the artist of the current track
    """
    let MUSIC_TRACK_ALBUM_SCRIPT = """
        tell application "Music" to get the album of the current track
    """
    let MUSIC_TRACK_DB_ID_SCRIPT = """
        tell application "Music" to get the database ID of the current track
    """
    let MUSIC_TRACK_ARTWORK_SCRIPT = """
        tell application "Music" to get the data of the first artwork of the current track
    """
    let MUSIC_TRACK_DURATION_SCRIPT = """
        tell application "Music" to get the duration of the current track
    """
    let MUSIC_TRACK_DATABASE_ID_SCRIPT = """
        tell application "Music" to get the database ID of the current track
    """
    let MUSIC_TRACK_YEAR_SCRIPT = """
        tell application "Music" to get the year of the current track
    """
    let MUSIC_TRACK_LOVED_SCRIPT = """
        tell application "Music" to get loved of the current track
    """
    
    @Published var currentTrackID: Int32?
    @Published var currentTrack: Track?
    @Published var currentPosition: Double?
    @Published var maxPosition: Double?
    @Published var musicRunning: Bool = false
    @Published var playerState: PlayerState = .unknown
    @Published var running: Bool = true
    var debug = false
    var onTrackChanged: ((Track) -> ())? = nil
    var onScrobbleWanted: ((Track) -> ())? = nil

    init(debug: Bool = false) {
        self.debug = debug
    }
    
    func start() {
        Task {
            while running {
                try? update()
                sleep(1)
            }
        }
    }
    
    func stop() { running = false }
    
    func log(_ what: String) {
        guard debug else { return }
        Swift.print(what)
    }
    
    func dump<T>(_ what: T) {
        guard debug else { return }
        Swift.dump(what)
    }


    func runScript<T>(_ script: String) throws -> T {
        try autoreleasepool {
            var error: NSDictionary?
            let scriptObject = OSAScript(source: script)
            let output = scriptObject.executeAndReturnError(&error)
            if error != nil {
                throw ScriptError.InternalError(String(describing: error))
            }

            switch (T.self) {
            case is String.Type:
                return "\(output!.stringValue!)" as! T
            case is Bool.Type:
                return output!.booleanValue as! T
            case is Int32.Type:
                return output!.int32Value as! T
            case is Double.Type:
                return output!.doubleValue as! T
            case is Data.Type:
                let oneData = output!.data
                return NSData(data: oneData) as! T
            default:
                throw ScriptError.InitializationError
            }
        }
    }
    
    func getPlayerPosition() throws -> Double {
        return try runScript(MUSIC_PLAYER_POSITION_SCRIPT)
    }
    
    func getPlayerTrack() throws -> Track {
        let name: String = try runScript(MUSIC_TRACK_NAME_SCRIPT)
        let artist: String = try runScript(MUSIC_TRACK_ARTIST_SCRIPT)
        let album: String = try runScript(MUSIC_TRACK_ALBUM_SCRIPT)
        let artwork: Data = try runScript(MUSIC_TRACK_ARTWORK_SCRIPT)
        let length: Double = try runScript(MUSIC_TRACK_DURATION_SCRIPT)
        let year: Int32 = try runScript(MUSIC_TRACK_YEAR_SCRIPT)
        let loved: Bool = try runScript(MUSIC_TRACK_LOVED_SCRIPT)
    
        return Track.init(artist: artist, album: album, name: name, year: year, length: length, artwork: artwork, loved: loved, startedAt: Int32((NSDate().timeIntervalSince1970 - (currentPosition ?? 0))))
    }
    
    func isMusicRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in app.bundleIdentifier != nil && app.bundleIdentifier! == "com.apple.Music" }
    }

    func setState(_ changes: () -> ()) {
        DispatchQueue.main.sync {
            changes()
        }
    }

    func reset() {
        DispatchQueue.main.sync {
            if currentTrackID != nil {
                currentTrackID = nil
            }

            if currentTrack != nil {
                currentTrack = nil
            }

            if currentPosition != nil {
                currentPosition = nil
            }

            if maxPosition != nil {
                maxPosition = nil
            }
        }
    }
    
    func update() throws {
        let isRunning = isMusicRunning()
        setState { musicRunning = isRunning }
        log("musicRunning = \(musicRunning)")
        if !musicRunning {
            reset()
            return
        }
        
        let newState: PlayerState
        let stringState: String = try runScript(MUSIC_STATE_SCRIPT)
        switch stringState {
        case "kPSP":
            newState = .‌playing
        case "kPSp":
            newState = .‌paused
        case "kPSS":
            newState = .stopped
            reset()
        case "kPSF", "kPSR":
            newState = .seeking
        default:
            newState = .unknown
        }
        
        if newState != playerState {
            setState { playerState = newState }
        }

        log("playerState = \(playerState)")
        
        let rawCurrentPosition: Data = try runScript(MUSIC_PLAYER_POSITION_SCRIPT)
        if rawCurrentPosition.count == 4 && rawCurrentPosition.starts(with: [103, 110, 115, 109]) {
            reset()
            return
        }

        setState { currentPosition = rawCurrentPosition.withUnsafeBytes { $0.load(as: Double.self) } }
        log("currentPosition = \(currentPosition!)")
        if maxPosition == nil || currentPosition! > maxPosition! {
            setState { maxPosition = currentPosition }
        }

        let trackID: Int32 = try runScript(MUSIC_TRACK_DATABASE_ID_SCRIPT)
        
        guard self.currentTrackID != trackID else { return }
        
        // At this point, the track has changed. Is our max position enough to scrobble it?
        if let maxPos = maxPosition {
            if currentTrack != nil && (maxPos / currentTrack!.length) * 100 >= 95 && !currentTrack!.scrobbled && currentTrack!.length >= 30 {
                if let fn = onScrobbleWanted {
                    DispatchQueue.main.async {
                        fn(self.currentTrack!)
                    }
                }
                log("Scrobble: \(currentTrack!)")
                currentTrack!.scrobbled = true
            }
        }

        setState { maxPosition = 0 }
        
        setState { currentTrackID = trackID }
        let track = try getPlayerTrack()
        setState { currentTrack = track }
        log("current track is")
        dump(track)
        if let fn = onTrackChanged {
            DispatchQueue.main.async {
                fn(track)
            }
        }
    }
}
