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
//        "App": [
//        "url": { () in },
//        "webview": { (url) in },
//        "reload": { () in }
//        ],
//        "Network": [
//        "url": { (scheme, endpoint) in }
//        "http": { (method, endpoint, data) in }
//        "websocket": { (endpoint, handler) in }
//        "hook": { (callback) in }
//        ],
//        "Database": [
//        "get": { (key) in },
//        "set": { (key, value) in },
//        "remove": { (key) in }
//        ]
        context.globalObject.setValue(JSValue(object: [

        ], in: context), forProperty: "platform")

        print(context.globalObject.forProperty("JSON").invokeMethod("stringify", withArguments: [
            context.globalObject.forProperty("platform"), JSValue(nullIn: context), JSValue(int32: 2, in: context)
        ]))
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
