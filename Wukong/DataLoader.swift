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
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: Int.max, diskPath: "Wukong")
        return URLSession(configuration: configuration)
    }()
    private var callbacks: [URL: (_ data: Data?) -> Void] = [:]

    func load(url: URL, _ handler: ((_ data: Data?) -> Void)? = nil) {
        if let callback = handler {
            callbacks[url] = callback
        }
        session.getAllTasks { [weak self] (tasks) in
            guard let wself = self else { return }
            guard !tasks.contains(where: { $0.originalRequest?.url == url }) else { return }
            let task = wself.session.dataTask(with: url) { (data, response, error) in
                wself.callbacks[url]?(data)
                wself.callbacks.removeValue(forKey: url)
            }
            task.resume()
        }
    }
    
}
