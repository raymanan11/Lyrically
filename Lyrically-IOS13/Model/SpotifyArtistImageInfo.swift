//
//  SpotifyArtistImageInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 7/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct SpotifyArtistImageInfo: Decodable {
    var images: [ArtistImages]
}

struct ArtistImages: Decodable {
    var url: String
}
