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

    private func entry() {
        context.globalObject.setValue({
            let defaults = UserDefaults(suiteName: Constant.identifier)!
            return [
                "App": [ // TODO
                    "url": unsafeBitCast({ () in
                        return "wukong://"
                    } as @convention(block) () -> String, to: AnyObject.self),
                    "webview": unsafeBitCast({ (url) in

                    } as @convention(block) (String) -> Void, to: AnyObject.self),
                    "reload": unsafeBitCast({ () in

                    } as @convention(block) () -> Void, to: AnyObject.self)
                ],
                "Network": [ // TODO
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
                        return defaults.string(forKey: key)
                    } as @convention(block) (String) -> String?, to: AnyObject.self),
                    "set": unsafeBitCast({ (key, value) in
                        defaults.set(value, forKey: key)
                    } as @convention(block) (String, String) -> Void, to: AnyObject.self),
                    "remove": unsafeBitCast({ (key) in
                        defaults.removeObject(forKey: key)
                    } as @convention(block) (String) -> Void, to: AnyObject.self)
                ]
            ]
        }(), forProperty: Constant.platformKey)
        context.globalObject.setValue({
            return client.call(withArguments: [platform])
        }(), forProperty: Constant.storeKey)
    }

    func getState<T>(_ property: [String]) -> T? {
        guard let state = store.invokeMethod("getState", withArguments: []) else { return nil }
        let object = property.reduce(state) { $0.forProperty($1) }
        return object.toObject() as? T
    }

    func querySelector<T>(_ name: String) -> T? {
        guard let state = store.invokeMethod("getState", withArguments: []) else { return nil }
        guard let object = selector.invokeMethod(name, withArguments: [state]) else { return nil }
        return object.toObject() as? T
    }

    func dispatchAction(_ name: [String], _ data: [Any]) {
        let object = name.reduce(action) { $0.forProperty($1) }
        _ = object.invokeMethod("create", withArguments: data)
    }

    func subscribeChange() {
        // TODO
    }

}
