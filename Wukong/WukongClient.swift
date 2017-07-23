//
//  WukongClient.swift
//  Wukong
//
//  Created by Qusic on 7/22/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import JavaScriptCore

protocol WukongDelegate {
    func wukongDidLoadScript()
    func wukongDidFailLoadScript()
}

class WukongClient: NSObject {

    static let sharedInstance = WukongClient()

    private let context = JSContext()!
    private let scriptLoader = ScriptLoader()
    private let dataLoader = DataLoader()
    private let audioPlayer = AudioPlayer()
    private let defaults = UserDefaults.standard

    var delegate: WukongDelegate?

    private func entry() {
        context.globalObject.setValue([
            "App": [
                "url": { () in
                    return ""
                } as @convention(block) () -> String,
                "webview": { (url) in

                } as @convention(block) (String) -> Void,
                "reload": { () in

                } as @convention(block) () -> Void
            ],
            "Network": [
                "url": { (scheme, endpoint) in
                    return ""
                } as @convention(block) (String, String) -> String,
                "http": { (method, endpoint, data) in
                    return ""
                } as @convention(block) (String, String, [String: Any]) -> Any,
                "websocket": { (endpoint, handler) in

                } as @convention(block) (String, Any) -> Void,
                "hook": { (callback) in

                } as @convention(block) (Any) -> Void
            ],
            "Database": [
                "get": { (key) in
                    return "133"
                } as @convention(block) (String) -> String,
                "set": { (key, value) in

                } as @convention(block) (String, String) -> Void,
                "remove": { (key) in
                    
                } as @convention(block) (String) -> Void
            ]
        ], forProperty: "Platform")
        print(context.globalObject.forProperty("JSON").invokeMethod("stringify", withArguments: [
            context.globalObject.forProperty("Platform"),
            JSValue(nullIn: context), JSValue(int32: 2, in: context)
        ]))
        print(context.evaluateScript("Platform.Database.get(\"\")").toString())
    }

    func start() {
        scriptLoader.load { [unowned self] (script) in
            guard let script = script else {
                self.delegate?.wukongDidFailLoadScript()
                return
            }
            self.delegate?.wukongDidLoadScript()
            self.context.evaluateScript(script)
            self.entry()
        }
    }
}
