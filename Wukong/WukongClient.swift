//
//  WukongClient.swift
//  Wukong
//
//  Created by Qusic on 7/22/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import JavaScriptCore
import SwiftWebSocket

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
            let apiURL: (String, String) -> String = { (scheme, endpoint) in "\(scheme)s://\(Constant.URL.api)\(endpoint)" }
            var networkHook = JSValue(undefinedIn: context)!
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
                "Network": [
                    "url": unsafeBitCast({ (scheme, endpoint) in
                        return apiURL(scheme, endpoint)
                    } as @convention(block) (String, String) -> String, to: AnyObject.self),
                    "http": unsafeBitCast({ [unowned self] (method, endpoint, body) in
                        guard let url = URL(string: apiURL("http", endpoint)) else { return self.jsPromise() }
                        var request = URLRequest(url: url)
                        request.httpMethod = method
                        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
                        return self.jsPromise { (resolve, reject) in
                            URLSession.apiSession.dataTask(with: request) { [unowned self] (data, response, error) in
                                guard error == nil else {
                                    reject(self.jsError(error?.localizedDescription))
                                    return
                                }
                                guard let response = response as? HTTPURLResponse else {
                                    reject(self.jsError("No response"))
                                    return
                                }
                                let status = response.statusCode
                                let error = 200 ... 299 ~= status ? NSNull() : HTTPURLResponse.localizedString(forStatusCode: status) as Any
                                networkHook.call(withArguments: [method, endpoint, status, error])
                                var object: Any = ""
                                if let data = data {
                                    if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                                        object = json
                                    } else if let string = String(data: data, encoding: .utf8) {
                                        object = string
                                    }
                                }
                                resolve(JSValue(object: object, in: self.context))
                            }.resume()
                        }
                    } as @convention(block) (String, String, [String: Any]) -> JSValue, to: AnyObject.self),
                    "websocket": unsafeBitCast({ (endpoint, handler) in
                        guard let url = URL(string: apiURL("ws", endpoint)) else { return }
                        var request = URLRequest(url: url)
                        if let cookies = URLSession.apiSession.configuration.httpCookieStorage?.cookies(for: url) {
                            let headers = HTTPCookie.requestHeaderFields(with: cookies)
                            headers.forEach {
                                request.setValue($1, forHTTPHeaderField: $0)
                            }
                        }
                        let websocket = WebSocket(request: request)
                        typealias SendFunction = @convention(block) (String, [String: Any]) -> Void
                        let send = unsafeBitCast({ (eventName, eventData) in
                            var object = eventData
                            object["eventName"] = eventName
                            guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else { return }
                            websocket.send(data: data)
                        } as SendFunction, to: AnyObject.self)
                        guard let emit = handler.call(withArguments: [send]) else {
                            websocket.close()
                            return
                        }
                        var timer: Timer? = nil
                        websocket.event.open = {
                            emit.call(withArguments: ["open"])
                            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [unowned send] (timer) in
                                unsafeBitCast(send, to: SendFunction.self)("ping", [:])
                            }
                            timer?.tolerance = 1
                        }
                        websocket.event.close = { (code, reason, clean) in
                            emit.call(withArguments: ["close"])
                            timer?.invalidate()
                            timer = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                websocket.open()
                            }
                        }
                        websocket.event.error = { (error) in
                            emit.call(withArguments: ["error"])
                        }
                        websocket.event.message = { (message) in
                            print("\(message)")
                        }
                    } as @convention(block) (String, JSValue) -> Void, to: AnyObject.self),
                    "hook": unsafeBitCast({ (callback) in
                        networkHook = callback
                    } as @convention(block) (JSValue) -> Void, to: AnyObject.self)
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

    private func jsPromise(_ executor: ((@escaping (JSValue?) -> Void, @escaping (JSValue?) -> Void) -> Void)? = nil) -> JSValue {
        return context.globalObject.forProperty("Promise").construct(withArguments: [unsafeBitCast({ (resolve, reject) in
            if let executor = executor {
                executor(
                    { resolve.call(withArguments: [$0].flatMap({$0})) },
                    { reject.call(withArguments: [$0].flatMap({$0})) }
                )
            } else {
                resolve.call(withArguments: [])
            }
        } as @convention(block) (JSValue, JSValue) -> Void, to: AnyObject.self)])
    }

    private func jsError(_ message: String? = nil) -> JSValue {
        return context.globalObject.forProperty("Error").construct(withArguments: [message].flatMap({$0}))
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

    func subscribeChange(_ handler: (() -> Void)? = nil) {
        guard let handler = handler else { return }
        store.invokeMethod("subscribe", withArguments: [unsafeBitCast(handler, to: AnyObject.self)])
    }

}
