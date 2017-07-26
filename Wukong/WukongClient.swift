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

    private let context = JSContext()!
    private let scriptLoader = ScriptLoader()
    private let dataLoader = DataLoader()
    private let audioPlayer = AudioPlayer()

    private var client: JSValue { return context.globalObject.forProperty(Constant.Script.client).forProperty(Constant.Script.main) }
    private var action: JSValue { return context.globalObject.forProperty(Constant.Script.client).forProperty(Constant.Script.action) }
    private var selector: JSValue { return context.globalObject.forProperty(Constant.Script.client).forProperty(Constant.Script.selector) }

    private var platform: JSValue { return context.globalObject.forProperty(Constant.Script.platform) }
    private var store: JSValue { return context.globalObject.forProperty(Constant.Script.store) }

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
            var networkHook: () -> Void = {}
            return [
                "App": [
                    "url": unsafeBitCast({ [unowned self] () in
                        let channel = self.getState([.channel, .name]) ?? ""
                        return "wukong://\(channel)"
                    } as @convention(block) () -> String, to: AnyObject.self),
                    "webview": unsafeBitCast({ [unowned self] (url) in
                        self.delegate?.wukongRequestOpenURL(url)
                    } as @convention(block) (String) -> Void, to: AnyObject.self),
                    "reload": unsafeBitCast({ () in
                        // do nothing
                    } as @convention(block) () -> Void, to: AnyObject.self)
                ],
                "Network": [ // TODO
                    "url": unsafeBitCast({ (scheme, endpoint) in
                        return "\(scheme)s://\(Constant.URL.api)\(endpoint)"
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
                        return UserDefaults.clientDefaults.string(forKey: key)
                    } as @convention(block) (String) -> String?, to: AnyObject.self),
                    "set": unsafeBitCast({ (key, value) in
                        UserDefaults.clientDefaults.set(value, forKey: key)
                    } as @convention(block) (String, String) -> Void, to: AnyObject.self),
                    "remove": unsafeBitCast({ (key) in
                        UserDefaults.clientDefaults.removeObject(forKey: key)
                    } as @convention(block) (String) -> Void, to: AnyObject.self)
                ]
            ]
        }(), forProperty: Constant.Script.platform)
        context.globalObject.setValue({
            return client.call(withArguments: [platform])
        }(), forProperty: Constant.Script.store)
    }

    func getState<T>(_ property: [Constant.State]) -> T? {
        guard let state = store.invokeMethod("getState", withArguments: []) else { return nil }
        let object = property.reduce(state) { $0.forProperty($1.rawValue) }
        return object.toObject() as? T
    }

    func querySelector<T>(_ name: Constant.Selector) -> T? {
        guard let state = store.invokeMethod("getState", withArguments: []) else { return nil }
        guard let object = selector.invokeMethod(name.rawValue, withArguments: [state]) else { return nil }
        return object.toObject() as? T
    }

    func dispatchAction(_ name: [Constant.Action], _ data: [Any]) {
        let object = name.reduce(action) { $0.forProperty($1.rawValue) }
        _ = object.invokeMethod("create", withArguments: data)
    }

    func subscribeChange() {
        // TODO
    }

}
