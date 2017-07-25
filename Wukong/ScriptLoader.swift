//
//  ScriptLoader.swift
//  Wukong
//
//  Created by Qusic on 7/22/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class ScriptLoader: NSObject {

    private struct Constant {
        static let packageName = "wukong-client"
        static let versionKey = "wukong-client.version"
        static let scriptKey = "wukong-client.script"
        static let registryURL = "https://registry.npmjs.org"
        static let dataURL = "https://unpkg.com"
        static let dataPath = "build/wukong.js"
    }

    private let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    private let defaults = UserDefaults.standard

    private func loadVersion(_ callback: ((_ version: String?) -> Void)? = nil) {
        session.dataTask(with: URL(string: "\(Constant.registryURL)/\(Constant.packageName)")!) { (data, response, error) in
            var version: String? = nil
            defer { callback?(version) }
            guard let data = data else { return }
            guard let info = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else { return }
            guard let tags = info["dist-tags"] as? [String: Any] else { return }
            guard let latest = tags["latest"] as? String else { return }
            version = latest
        }.resume()
    }

    private func loadScript(version: String, _ callback: ((_ script: String?) -> Void)? = nil) {
        session.dataTask(with: URL(string: "\(Constant.dataURL)/\(Constant.packageName)@\(version)/\(Constant.dataPath)")!) { (data, response, error) in
            var script: String? = nil
            defer { callback?(script) }
            guard let data = data else { return }
            guard let string = String(data: data, encoding: .utf8) else { return }
            script = string
        }.resume()
    }

    func load(_ callback: ((_ script: String?) -> Void)? = nil) {
        var loaded = false
        if let script = defaults.string(forKey: Constant.scriptKey) {
            callback?(script)
            loaded = true
        }
        loadVersion { [weak self] (version) in
            guard let wself = self else { return }
            guard let version = version else { return }
            guard version != wself.defaults.string(forKey: Constant.versionKey) else { return }
            wself.loadScript(version: version) { [weak self] (script) in
                guard let wself = self else { return }
                guard let script = script else { return }
                wself.defaults.set(version, forKey: Constant.versionKey)
                wself.defaults.set(script, forKey: Constant.scriptKey)
                if !loaded {
                    OperationQueue.main.addOperation {
                        callback?(script)
                    }
                }
            }
        }
    }

}
