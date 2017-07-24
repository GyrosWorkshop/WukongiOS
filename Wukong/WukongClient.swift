//
//  WukongClient.swift
//  Wukong
//
//  Created by Qusic on 7/22/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import JavaScriptCore

protocol WukongDelegate: class {
    func wukongDidLoadScript()
    func wukongDidFailLoadScript()
    func wukongDidThrowException(_ exception: String)
}

class WukongClient: NSObject {

    static let sharedInstance = WukongClient()

    private let context = JSContext()!
    private let scriptLoader = ScriptLoader()
    private let dataLoader = DataLoader()
    private let audioPlayer = AudioPlayer()

    weak var delegate: WukongDelegate?

    private var platform: [String: [String: AnyObject]] { return [
        "App": [
            "url": unsafeBitCast({ () in
                return ""
            } as @convention(block) () -> String, to: AnyObject.self),
            "webview": unsafeBitCast({ (url) in

            } as @convention(block) (String) -> Void, to: AnyObject.self),
            "reload": unsafeBitCast({ () in

            } as @convention(block) () -> Void, to: AnyObject.self)
        ],
        "Network": [
            "url": unsafeBitCast({ (scheme, endpoint) in
                return ""
            } as @convention(block) (String, String) -> String, to: AnyObject.self),
            "http": unsafeBitCast({ (method, endpoint, data) in
                return ""
            } as @convention(block) (String, String, [String: Any]) -> Any, to: AnyObject.self),
            "websocket": unsafeBitCast({ (endpoint, handler) in

            } as @convention(block) (String, Any) -> Void, to: AnyObject.self),
            "hook": unsafeBitCast({ (callback) in

            } as @convention(block) (Any) -> Void, to: AnyObject.self)
        ],
        "Database": [
            "get": unsafeBitCast({ [unowned self] (key) in
                guard key.isString else { return nil }
                return self.defaults.string(forKey: key.toString())
            } as @convention(block) (JSValue) -> String?, to: AnyObject.self),
            "set": unsafeBitCast({ [unowned self] (key, value) in
                guard key.isString else { return }
                self.defaults.set(value.toString(), forKey: key.toString())
            } as @convention(block) (JSValue, JSValue) -> Void, to: AnyObject.self),
            "remove": unsafeBitCast({ [unowned self] (key) in
                guard key.isString else { return }
                self.defaults.removeObject(forKey: key.toString())
            } as @convention(block) (JSValue) -> Void, to: AnyObject.self)
        ]
    ]}

    private func entry() {
        context.globalObject.setValue(platform, forProperty: "Platform")
        print(context.evaluateScript("Platform.Database.get(\"me.qusic.wukong.version\")").toString())
    }

    func run() {
        scriptLoader.load { [unowned self] (script) in
            guard let script = script else {
                self.delegate?.wukongDidFailLoadScript()
                return
            }
            self.delegate?.wukongDidLoadScript()
            self.context.exceptionHandler = { [unowned self] (context, exception) in
                if let exception = exception?.toString() {
                    self.delegate?.wukongDidThrowException(exception)
                }
            }
            self.context.evaluateScript(script)
            self.entry()
        }
    }

}
