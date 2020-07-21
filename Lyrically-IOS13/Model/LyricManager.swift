//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import NaturalLanguage

protocol LyricManagerDelegate : class {
    func updateLyrics(_ fullLyrics: String)
}

class LyricManager {
    var songName = ""
    var songArtist = ""
    
    var delegate: LyricManagerDelegate?
    
    static var triedOnce: Bool = false
    
    let headers = [
        "x-rapidapi-host": "canarado-lyrics.p.rapidapi.com",
        "x-rapidapi-key": Constants.rapidAPIKey
    ]
    
    func getLyrics(_ URL: NSURL) {
        let request = NSMutableURLRequest(url: URL as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))

        dataTask.resume()
    }
    // (' or ’)
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        self.songName = songName
        self.songArtist = songArtist
        let songURL = songAndArtist.replacingOccurrences(of: " ", with: "%2520").replacingOccurrences(of: "’", with: "'")
        let urlOptionOne = songURL.folding(options: .diacriticInsensitive, locale: .current)
        let urlOptionTwo = songURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        if let urlOne = NSURL(string: "https://canarado-lyrics.p.rapidapi.com/lyrics/\(urlOptionOne)") {
            getLyrics(urlOne)
        }
        else if let safeStringURL = urlOptionTwo, let urlTwo = NSURL(string: "https://canarado-lyrics.p.rapidapi.com/lyrics/\(safeStringURL)") {
            getLyrics(urlTwo)
        }
        else {
            print("unable to get")
        }
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        let songAndArtist = "\(songName) \(songArtist)"
        if (error != nil) {
            print(error!)
            print("Problem with Lyric API, calling again")
            fetchData(songAndArtist: songAndArtist, songName: self.songName, songArtist: self.songArtist)
            return
        }
        if let safeData = data {
            if let lyrics = self.parseJson(safeData) {
                // the triedOnce variable ensures that "no lyrics found" is showed after trying an alternate method of looking for lyrics from lyric API
                if lyrics == Constants.noLyrics && LyricManager.triedOnce == false {
                    LyricManager.triedOnce = true
                    // another way of getting lyrics if not found is trying just one artist instead of all
                    print("No lyrics found for singleArtist, trying again")
                    fetchData(songAndArtist: songAndArtist, songName: self.songName, songArtist: self.songArtist)
                }
                else {
                    delegate?.updateLyrics(lyrics)
                }
            }
        }
    }
    
    fileprivate func getLyrics(_ songInfo: CanaradoSongInfo, _ spotifySongName: String, _ spotifySongArtist: String?) -> String? {
        for(index, value) in songInfo.content.enumerated() {
            let potentialSongName = value.title.lowercased()
            let canaradoSongName = potentialSongName.replacingOccurrences(of: "&", with: "and").filter { !$0.isWhitespace && !"/-.,'".contains($0)}
            print("Potential song name: \(canaradoSongName)")
            if let safeSongArtist = spotifySongArtist {
                if canaradoSongName.contains(spotifySongName) && canaradoSongName.contains(safeSongArtist) {
                    return value.lyrics
                }
            }
            else {
                if canaradoSongName.contains(spotifySongName) {
                    return value.lyrics
                }
            }
        }
        return nil
    }
    
    func parseJson(_ safeData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let songInfo = try decoder.decode(CanaradoSongInfo.self, from: safeData)
            let spotifySongName = songName.lowercased().filter { !" /-.,'".contains($0) }
            let spotifySongArtist = songArtist.lowercased().replacingOccurrences(of: "&", with: "and").filter { !" /-.,'".contains($0) }
            print("Spotify song name: \(spotifySongName)")
            print("Spotify song artist: \(spotifySongArtist)")
            if let lyricsOptionOne = getLyrics(songInfo, spotifySongName, spotifySongArtist) {
                print("Lyrics Option One")
                return lyricsOptionOne
            }
            else {
                if let lyricsOptionTwo = getLyrics(songInfo, spotifySongName, nil) {
                    print("Lyrics Option Two")
                    return lyricsOptionTwo
                }
            }
            // if it reaches this point then that means it is not able to find lyrics
            return Constants.noLyrics
        }
        catch {
            print(error)
            return Constants.noLyrics
        }
    }
    
    func detectedLanguage(for string: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        guard let languageCode = recognizer.dominantLanguage?.rawValue else { return nil }
        let detectedLanguage = Locale.current.localizedString(forIdentifier: languageCode)
        return detectedLanguage
    }
    
}


