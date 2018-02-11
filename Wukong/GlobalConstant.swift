//
//  GlobalConstant.swift
//  Wukong
//
//  Created by Qusic on 7/26/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import SwiftWebSocket

struct Constant {

    struct Identifier {
        static let name = "Wukong"
        static let client = "wukong-client"
        static let app = Bundle.main.bundleIdentifier!
    }

    struct Defaults {
        static let version = "\(Identifier.client).version"
        static let script = "\(Identifier.client).script"
        static let channel = "\(Identifier.name).channel"
    }

    struct Script {
        static let client = "Wukong"
        static let main = "default"
        static let action = "Action"
        static let selector = "Selector"
        static let platform = "Platform"
        static let store = "Store"
    }

    struct URL {
        static let scheme = "wukong"
        static let api = "api5.wukongmusic.us"
        static let web = "https://wukongmusic.us"
        static let registry = "https://registry.npmjs.org"
        static let package = "https://unpkg.com"
        static let bundle = "wukong.js"
    }

    enum State: String {
        case user
        case profile
        case auth
        case preferences

        case channel
        case name
        case members

        case song
        case playlist
        case playing
        case preload

        case player
        case running
        case elapsed
        case duration
        case ended
        case downvote
        case volume
        case reload

        case search
        case keyword
        case results

        case misc
        case notification

        case id
        case nickname
        case avatar

        // case id
        case siteId
        case songId
        case title
        case album
        case artist
        case artwork
        case length
        case bitrate
        case link
        case mvLink
        case files
        case mvFile
        case lyrics

        case url
        case urls
        case format
        case quality
        case level
        case description

        case time
        case text

        case listenOnly
        case connection
        case audioQuality
        case sync
        case cookie
    }

    enum Action: String {
        case User
        case profile
        case auth
        case preferences

        case Channel
        case name
        case members

        case Song
        case add
        case remove
        case move
        case assign
        case shuffle
        case sync
        case play
        case preload

        case Player
        case running
        case elapsed
        case duration
        case ended
        case downvote
        case volume
        case reload
        case reset
        
        case Search
        case keyword
        case results
        
        case Misc
        case notification
    }
    
    enum Selector: String {
        case playingArtwork
        case preloadArtwork
        case playingFile
        case preloadFile
        case playerIndex
        case currentSongs
        case currentLyrics
    }

}

extension UserDefaults {

    static let clientDefaults = UserDefaults(suiteName: Constant.Identifier.client)!
    static let appDefaults = UserDefaults.standard

}

extension URL {

    static let cacheDirectory: URL = {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let directory = URL(fileURLWithPath: paths.first!, isDirectory: true).appendingPathComponent(Constant.Identifier.name, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

}

extension URLSession {

    static let apiSession = URLSession(configuration: URLSessionConfiguration.default)
    static let dataSession = URLSession(configuration: URLSessionConfiguration.default)

}

extension WebSocket {

    static let apiSocket = WebSocket()

}
