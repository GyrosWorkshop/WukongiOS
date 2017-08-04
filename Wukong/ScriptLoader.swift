//
//  ScriptLoader.swift
//  Wukong
//
//  Created by Qusic on 7/22/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class ScriptLoader: NSObject {

    static let sharedInstance = ScriptLoader()

    private func loadVersion(_ callback: ((_ version: String?) -> Void)? = nil) {
        let url = "\(Constant.URL.registry)/\(Constant.Identifier.client)"
        URLSession.dataSession.dataTask(with: URL(string: url)!) { (data, response, error) in
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
        let url = "\(Constant.URL.package)/\(Constant.Identifier.client)@\(version)/\(Constant.URL.bundle)"
        URLSession.dataSession.dataTask(with: URL(string: url)!) { (data, response, error) in
            var script: String? = nil
            defer { callback?(script) }
            guard let data = data else { return }
            guard let string = String(data: data, encoding: .utf8) else { return }
            script = string
        }.resume()
    }

    func load(online: Bool, _ callback: ((_ script: String?) -> Void)? = nil) {
        var loaded = false
        if let script = UserDefaults.appDefaults.string(forKey: Constant.Defaults.script) {
            callback?(script)
            loaded = true
        }
        guard online else {
            if !loaded {
                callback?(nil)
            }
            return
        }
        loadVersion { [weak self] (version) in
            guard let wself = self else { return }
            guard let version = version else { return }
            guard version != UserDefaults.appDefaults.string(forKey: Constant.Defaults.version) else { return }
            wself.loadScript(version: version) { (script) in
                guard let script = script else { return }
                UserDefaults.appDefaults.set(version, forKey: Constant.Defaults.version)
                UserDefaults.appDefaults.set(script, forKey: Constant.Defaults.script)
                if !loaded {
                    DispatchQueue.main.async {
                        callback?(script)
                    }
                }
            }
        }
    }

}
