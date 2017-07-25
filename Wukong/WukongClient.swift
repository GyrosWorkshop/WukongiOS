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
    func wukongRequestOpenURL(_ url: String)
}

class WukongClient: NSObject {

    private struct Constant {
        static let identifier = "wukong-client"
        static let clientKey = "Wukong"
        static let actionKey = "Action"
        static let selectorKey = "Selector"
        static let platformKey = "Platform"
        static let storeKey = "Store"
    }

    private let context = JSContext()!
    private let scriptLoader = ScriptLoader()
    private let dataLoader = DataLoader()
    private let audioPlayer = AudioPlayer()

    private var client: JSValue { return context.globalObject.forProperty(Constant.clientKey).forProperty("default") }
    private var action: JSValue { return context.globalObject.forProperty(Constant.clientKey).forProperty(Constant.actionKey) }
    private var selector: JSValue { return context.globalObject.forProperty(Constant.clientKey).forProperty(Constant.selectorKey) }

    private var platform: JSValue { return context.globalObject.forProperty(Constant.platformKey) }
    private var store: JSValue { return context.globalObject.forProperty(Constant.storeKey) }

    static let sharedInstance = WukongClient()
    weak var delegate: WukongDelegate?

    private func entry() {
        context.globalObject.setValue({
            let defaults = UserDefaults(suiteName: Constant.identifier)!
            return [
                "App": [
                    "url": unsafeBitCast({ () in
                        return "wukong://"
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
                        guard key.isString else { return nil }
                        return defaults.string(forKey: key.toString())
                    } as @convention(block) (JSValue) -> String?, to: AnyObject.self),
                    "set": unsafeBitCast({ (key, value) in
                        guard key.isString else { return }
                        defaults.set(value.toString(), forKey: key.toString())
                    } as @convention(block) (JSValue, JSValue) -> Void, to: AnyObject.self),
                    "remove": unsafeBitCast({ (key) in
                        guard key.isString else { return }
                        defaults.removeObject(forKey: key.toString())
                    } as @convention(block) (JSValue) -> Void, to: AnyObject.self)
                ]
            ]
        }(), forProperty: Constant.platformKey)
        context.globalObject.setValue({
            return client.call(withArguments: [platform])
        }(), forProperty: Constant.storeKey)

        // TODO
        print(context.evaluateScript(Constant.storeKey))
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
