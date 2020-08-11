//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire

protocol LyricManagerDelegate : class {
    func updateLyrics(_ fullLyrics: String)
}

class LyricManager {
    var songName = ""
    var songArtist = ""
    
    var delegate: LyricManagerDelegate?
    
    var triedOnce: Bool = false
    static var triedMultipleArtists: Bool = false
    var triedSingleArtist: Bool = false
    
    let canarado = "https://api.canarado.xyz/lyrics/"
    
    var dataTask: URLSessionDataTask?
    
    var previousSong: String?
    
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        self.songName = songName
        self.songArtist = songArtist

        let songURL = songAndArtist.replacingOccurrences(of: "’", with: "'").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
//        if songName != previousSong {
//            previousSong = songName
//            if let safeStringURL = songURL {
//                print("Getting lyrics for URL")
//                getLyrics(URL: "\(canarado)\(safeStringURL)")
//            }
//            else {
//                delegate?.updateLyrics(Constants.noLyrics)
//            }
//        }
        
        if songName != previousSong {
            previousSong = songName
            if let safeStringURL = songURL, let url = NSURL(string: "\(canarado)\(safeStringURL)") {
                getLyrics(url)
            }
            else {
                delegate?.updateLyrics(Constants.noLyrics)
            }
        }
        
    }
    
//    // Alamofire (Correct but slow)
//    func getLyrics(URL: String) {
//        let songAndSingleArtist = "\(songName) \(songArtist)"
//        AF.request(URL, method: .get).responseJSON { response in
//            if let safeData = response.data {
//                print("got json data")
//                if let lyrics = self.parseJson(safeData) {
//                    print("got some lyric data")
//                    // the triedOnce variable ensures that "no lyrics found" is showed after trying an alternate method of looking for lyrics from lyric API
//                    if lyrics == Constants.noLyrics && !LyricManager.triedMultipleArtists {
//                        LyricManager.triedMultipleArtists = true
//                        // another way of getting lyrics if not found is trying just one artist instead of all
//                        print("No lyrics found for multiple artists, trying again")
//                        self.previousSong = nil
//                        self.triedSingleArtist = true
//                        self.fetchData(songAndArtist: songAndSingleArtist, songName: self.songName, songArtist: self.songArtist)
//                    }
//                    else {
//                        self.delegate?.updateLyrics(lyrics)
//                        self.triedSingleArtist = false
//                        self.triedOnce = false
//                    }
//                }
//                else {
//                    self.delegate?.updateLyrics(Constants.noLyrics)
//                }
//            }
//        }
//    }
    
    func getLyrics(_ url: NSURL) {
        let request = NSMutableURLRequest(url: url as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))
        dataTask.resume()
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        let songAndSingleArtist = "\(songName) \(songArtist)"
        if error != nil {
            print("Problem with Lyric API, calling again")
            fetchData(songAndArtist: songAndSingleArtist, songName: songName, songArtist: songArtist)
        }
        if let safeData = data {
            if let lyrics = self.parseJson(safeData) {
                if lyrics == Constants.noLyrics && !LyricManager.triedMultipleArtists {
                    LyricManager.triedMultipleArtists = true
                    // another way of getting lyrics if not found is trying just one artist instead of all
                    self.previousSong = nil
                    self.triedSingleArtist = true
                    self.fetchData(songAndArtist: songAndSingleArtist, songName: self.songName, songArtist: self.songArtist)
                }
                else {
                    self.delegate?.updateLyrics(lyrics)
                    self.triedSingleArtist = false
                    self.triedOnce = false
                    previousSong = nil
                }
            }
        }
    }
    
    func parseJson(_ safeData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let songInfo = try decoder.decode(CanaradoSongInfo.self, from: safeData)
            let spotifySongName = parseWord(songName.lowercased())
            let spotifySongArtist = parseWord(songArtist.lowercased())
            if let lyricsOptionOne = getLyrics(songInfo, spotifySongName, spotifySongArtist) {
                return lyricsOptionOne
            }
            else if triedSingleArtist {
                if let lyricsOptionTwo = getLyrics(songInfo, spotifySongName, nil) {
                    return lyricsOptionTwo
                }
            }
            else {
                print("unable to find lyrics")
            }
            // if it reaches this point then that means it is not able to find lyrics
            return Constants.noLyrics
        }
        catch {
            print(error)
            return Constants.noLyrics
        }
    }
    
    func getLyrics(_ songInfo: CanaradoSongInfo, _ spotifySongName: String, _ spotifySongArtist: String?) -> String? {
        for(_, value) in songInfo.content.enumerated() {
            let potentialSongName = value.title.lowercased()
            let canaradoSongName = parseWord(potentialSongName)
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
    
    func parseWord(_ word: String) -> String {
        return word.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: .current).filter { !$0.isWhitespace && !"/-.,'’".contains($0) }
    }

}


