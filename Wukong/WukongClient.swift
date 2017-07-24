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
                "get": unsafeBitCast({ (key) in
                    return "123"
                } as @convention(block) (String) -> String, to: AnyObject.self),
                "set": unsafeBitCast({ (key, value) in

                } as @convention(block) (String, String) -> Void, to: AnyObject.self),
                "remove": unsafeBitCast({ (key) in
                    
                } as @convention(block) (String) -> Void, to: AnyObject.self)
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
            self.context.exceptionHandler = { (context, exception) in
                print(exception?.toString() ?? "")
            }
            self.context.evaluateScript(script)
            self.entry()
        }
    }
}
