//
//  GlobalConstant.swift
//  Wukong
//
//  Created by Qusic on 7/26/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

struct Constant {

    struct Identifier {
        static let name = "Wukong"
        static let client = "wukong-client"
        static let app = Bundle.main.bundleIdentifier!
    }

    struct Defaults {
        static let version = "\(Identifier.client).version"
        static let script = "\(Identifier.client).script"
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
        static let api = "api.wukongmusic.us"
        static let web = "https://wukongmusic.us"
        static let registry = "https://registry.npmjs.org"
        static let package = "https://unpkg.com"
        static let bundle = "build/wukong.js"
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

    static let apiSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()

    static let dataSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

}
