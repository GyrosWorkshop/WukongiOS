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
    func wukongDidLaunch()
    func wukongDidThrowException(_ exception: String)
    func wukongRequestOpenURL(_ url: String)
}

class WukongClient: NSObject {

    static let sharedInstance = WukongClient()

    private var context: JSContext!
    private weak var delegate: WukongDelegate!

    private var client: JSValue { return context.globalObject.forProperty(Constant.Script.client).forProperty(Constant.Script.main) }
    private var action: JSValue { return context.globalObject.forProperty(Constant.Script.client).forProperty(Constant.Script.action) }
    private var selector: JSValue { return context.globalObject.forProperty(Constant.Script.client).forProperty(Constant.Script.selector) }
    private var platform: JSValue { return context.globalObject.forProperty(Constant.Script.platform) }
    private var store: JSValue { return context.globalObject.forProperty(Constant.Script.store) }

    func run(_ delegate: WukongDelegate) {
        guard context == nil else { return }
        self.delegate = delegate
        ScriptLoader.sharedInstance.load(online: true) { [unowned self] (script) in
            self.setupContext(script)
        }
    }

    func reload() {
        guard context != nil else { return }
        ScriptLoader.sharedInstance.load(online: false) { [unowned self] (script) in
            self.setupContext(script)
        }
    }

    private func setupContext(_ script: String?) {
        guard let script = script else {
            print("Client:", "failed")
            delegate.wukongDidFailLoadScript()
            return
        }
        print("Client:", "loaded")
        delegate.wukongDidLoadScript()
        context = JSContext()!
        context.exceptionHandler = { [unowned self] (context, exception) in
            context?.exception = exception
            if let exception = exception?.toString() {
                print("Client:", "exception", exception)
                self.delegate.wukongDidThrowException(exception)
            }
        }
        context.evaluateScript(script)
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
                        print("Client:", "open", url)
                        self.delegate.wukongRequestOpenURL(url)
                    } as @convention(block) (String) -> Void, to: AnyObject.self),
                    "reload": unsafeBitCast({ [unowned self] () in
                        DispatchQueue.main.async {
                            self.reload()
                        }
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
                        if method != "GET", let data = try? JSONSerialization.data(withJSONObject: body, options: []) {
                            request.httpBody = data
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        }
                        return self.jsPromise { [unowned self] (resolve, reject) in
                            URLSession.apiSession.dataTask(with: request) { [unowned self] (data, response, error) in
                                guard error == nil else {
                                    print("HTTP:", method, endpoint, error?.localizedDescription ?? "unknown error")
                                    reject(self.jsError(error?.localizedDescription))
                                    return
                                }
                                guard let response = response as? HTTPURLResponse else {
                                    print("HTTP:", method, endpoint, "unknown response")
                                    reject(self.jsError("No response"))
                                    return
                                }
                                let status = response.statusCode
                                let error = 200 ... 299 ~= status ? NSNull() : HTTPURLResponse.localizedString(forStatusCode: status) as Any
                                networkHook.call(withArguments: [method, endpoint, status, error])
                                if let exception = self.context.exception {
                                    self.context.exception = nil
                                    print("HTTP:", method, endpoint, exception)
                                    reject(exception)
                                } else {
                                    var object: Any = ""
                                    if let data = data {
                                        if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                                            object = json
                                        } else if let string = String(data: data, encoding: .utf8) {
                                            object = string
                                        }
                                    }
                                    print("HTTP:", method, endpoint, "ok")
                                    resolve(JSValue(object: object, in: self.context))
                                }
                            }.resume()
                        }
                    } as @convention(block) (String, String, [String: Any]) -> JSValue, to: AnyObject.self),
                    "websocket": unsafeBitCast({ (endpoint, handler) in
                        guard let url = URL(string: apiURL("ws", endpoint)) else { return }
                        var request = URLRequest(url: url)
                        if let cookieUrl = URL(string: apiURL("http", endpoint)),
                            let cookies = URLSession.apiSession.configuration.httpCookieStorage?.cookies(for: cookieUrl) {
                            let headers = HTTPCookie.requestHeaderFields(with: cookies)
                            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
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
                            print("WebSocket:", "open")
                            emit.call(withArguments: ["open"])
                            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak send] (timer) in
                                if let send = send {
                                    unsafeBitCast(send, to: SendFunction.self)("ping", [:])
                                } else {
                                    timer.invalidate()
                                }
                            }
                            timer?.tolerance = 1
                        }
                        websocket.event.close = { (code, reason, clean) in
                            print("WebSocket:", "close", code, reason, clean)
                            emit.call(withArguments: ["close"])
                            timer?.invalidate()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak websocket] in
                                websocket?.open()
                            }
                        }
                        websocket.event.error = { (error) in
                            print("WebSocket:", "error", error)
                            emit.call(withArguments: ["error"])
                        }
                        websocket.event.message = { (message) in
                            guard let string = message as? String else { return }
                            guard let data = string.data(using: .utf8) else { return }
                            guard var object = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] else { return }
                            guard let name = object["eventName"] else { return }
                            object.removeValue(forKey: "eventName")
                            print("WebSocket:", "event", name)
                            emit.call(withArguments: [name, object])
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
        print("Client:", "launched")
        delegate.wukongDidLaunch()
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
        let helper = name.reduce(action) { $0.forProperty($1.rawValue) }
        guard let object = helper.invokeMethod("create", withArguments: data) else { return }
        store.invokeMethod("dispatch", withArguments: [object])
    }

    func subscribeChange(_ handler: (() -> Void)? = nil) {
        guard let handler = handler else { return }
        store.invokeMethod("subscribe", withArguments: [unsafeBitCast({
            DispatchQueue.main.async(execute: handler)
        } as @convention(block) () -> Void, to: AnyObject.self)])
    }

}
