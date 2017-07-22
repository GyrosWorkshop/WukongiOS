//
//  DataLoader.swift
//  Wukong
//
//  Created by Qusic on 4/23/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class DataLoader: NSObject {

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()
    private let directory: URL = {
        let directory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!, isDirectory: true).appendingPathComponent("Wukong", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()
    private var callbacks: [String: (_ data: Data?) -> Void] = [:]

    func load(key: String, url: URL, _ dataCallback: ((_ data: Data?) -> Void)? = nil) {
        let file = directory.appendingPathComponent(key, isDirectory: false)
        if let data = try? Data(contentsOf: file) {
            dataCallback?(data)
            return
        }
        if let callback = dataCallback {
            callbacks[key] = callback
        }
        session.getAllTasks { [weak self] (tasks) in
            guard let wself = self else { return }
            guard !tasks.contains(where: { $0.originalRequest?.url == url }) else { return }
            wself.session.dataTask(with: url) { [weak self] (data, response, error) in
                guard let wself = self else { return }
                wself.callbacks[key]?(data)
                wself.callbacks.removeValue(forKey: key)
                try? data?.write(to: file)
            }.resume()
        }
    }
    
}
