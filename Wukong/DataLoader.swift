//
//  DataLoader.swift
//  Wukong
//
//  Created by Qusic on 4/23/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class DataLoader: NSObject {

    private var callbacks: [String: (_ data: Data?) -> Void] = [:]

    func load(key: String, url: URL, _ dataCallback: ((_ data: Data?) -> Void)? = nil) {
        let file = URL.cacheDirectory.appendingPathComponent(key, isDirectory: false)
        if let data = try? Data(contentsOf: file) {
            dataCallback?(data)
            return
        }
        if let callback = dataCallback {
            callbacks[key] = callback
        }
        URLSession.dataSession.getAllTasks { (tasks) in
            guard !tasks.contains(where: { $0.originalRequest?.url == url }) else { return }
            URLSession.dataSession.dataTask(with: url) { [weak self] (data, response, error) in
                guard let wself = self else { return }
                try? data?.write(to: file)
                OperationQueue.main.addOperation {
                    wself.callbacks[key]?(data)
                    wself.callbacks.removeValue(forKey: key)
                }
            }.resume()
        }
    }

}
