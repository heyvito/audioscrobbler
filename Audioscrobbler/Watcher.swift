//
//  State.swift
//  Scrobbler
//
//  Created by Victor Gama on 24/11/2022.
//

import Foundation
import AppKit

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


    func runScript(_ script: String) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            throw ScriptError.InitializationError
        }
        
        let output = scriptObject.executeAndReturnError(&error)
        if error != nil {
            throw ScriptError.InternalError(String(describing: error))
        }
        return output
    }
    
    func getPlayerPosition() throws -> Double {
        return try runScript(MUSIC_PLAYER_POSITION_SCRIPT).doubleValue
    }
    
    func getPlayerTrack() throws -> Track {
        let name = try runScript(MUSIC_TRACK_NAME_SCRIPT).stringValue!
        let artist = try runScript(MUSIC_TRACK_ARTIST_SCRIPT).stringValue!
        let album = try runScript(MUSIC_TRACK_ALBUM_SCRIPT).stringValue!
        let artwork = try? runScript(MUSIC_TRACK_ARTWORK_SCRIPT).data
        let length = try runScript(MUSIC_TRACK_DURATION_SCRIPT).doubleValue
        let year = try runScript(MUSIC_TRACK_YEAR_SCRIPT).int32Value
        let loved = try runScript(MUSIC_TRACK_LOVED_SCRIPT).booleanValue
    
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
    
    func update() throws {
        let isRunning = isMusicRunning()
        setState { musicRunning = isRunning }
        log("musicRunning = \(musicRunning)")
        if !musicRunning {
            return
        }
        
        let newState: PlayerState
        switch try runScript(MUSIC_STATE_SCRIPT).stringValue {
        case .some("kPSP"):
            newState = .‌playing
        case .some("kPSp"):
            newState = .‌paused
        case .some("kPSS"):
            newState = .stopped
        case .some("kPSF"), .some("kPSR"):
            newState = .seeking
        default:
            newState = .unknown
        }
        
        if newState != playerState {
            setState { playerState = newState }
        }

        log("playerState = \(playerState)")
        
        let rawCurrentPosition = try runScript(MUSIC_PLAYER_POSITION_SCRIPT)
        let currentPositionData = rawCurrentPosition.data
        if currentPositionData.count == 4 && currentPositionData.starts(with: [103, 110, 115, 109]) {
            return
        }
        
        setState { currentPosition = rawCurrentPosition.doubleValue }
        log("currentPosition = \(currentPosition!)")
        if maxPosition == nil || currentPosition! > maxPosition! {
            setState { maxPosition = currentPosition }
        }

        let trackID = try runScript(MUSIC_TRACK_DATABASE_ID_SCRIPT).int32Value
        
        guard self.currentTrackID == nil || self.currentTrackID! != trackID else { return }
        
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
