//
//  PlayingItemView.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 24/11/2022.
//

import SwiftUI

struct PlayingItemView: View {
    @Binding var track: Track?
    @Binding var currentPosition: Double?

    func artworkImage() -> Image {
        if let trk = track {
            if let art = trk.artwork {
                if let img = NSImage.init(data: art) {
                    return Image(nsImage: img)
                }
            }
        }

        return Image("nocover")
    }

    func formatDuration(_ value: Double) -> String {
        let hours = value / 3600
        let minutes = Int(value.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(value.truncatingRemainder(dividingBy: 60))

        if hours >= 1 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds);
        } else if minutes >= 1 {
            return String(format: "%02d:%02d", minutes, seconds);
        } else {
            return String(format: "00:%02d", seconds);
        }
    }

    let redColor = Color(hue: 0, saturation: 0.70, brightness: 0.75)
    func urlFor(artist: String) -> URL {
        let artist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return URL(string: "https://www.last.fm/music/\(artist)")!
    }

    func urlFor(artist: String, album: String) -> URL {
        let artist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let album = album.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return URL(string: "https://www.last.fm/music/\(artist)/\(album)")!
    }

    var body: some View {
        HStack(alignment: .top) {
            artworkImage()
                .resizable()
                .cornerRadius(3)
                .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: 3) {
                Text(track!.name)
                    .font(.system(size: 18, weight: .bold))
                HStack(spacing: 3) {
                    Text("by")
                    Link(track!.artist, destination: urlFor(artist: track!.artist))
                        .foregroundColor(redColor)
                }
                HStack(spacing: 3) {
                    Text("on")
                    Link(track!.album, destination: urlFor(artist: track!.artist, album: track!.album))
                        .foregroundColor(redColor)
                }
                HStack(spacing: 3) {
                    Text("released")
                    Text("\(String(format: "%04d", track!.year))")
                }
                HStack(spacing: 8) {
                    Text(formatDuration(currentPosition!))
                        .font(.caption)
                    ProgressBar(value: currentPosition!, maxValue: track!.length)
                        .frame(height: 8)
                    Text(formatDuration(track!.length))
                        .font(.caption)
                }
            }
        }.padding()
            .animation(nil)
    }
}

struct PlayingItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlayingItemView(track: .constant(.init(artist: "Alexisonfire", album: "Watch Out!", name: "It Was Fear Of Myself That Made Me Odd", year: 2004, length: 123.10293, artwork: nil, loved: true, startedAt: 0)), currentPosition: .constant(61.5))
    }
}
