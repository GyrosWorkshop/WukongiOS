//
//  DataLoader.swift
//  Wukong
//
//  Created by Qusic on 4/23/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class DataLoader: NSObject {

    static let sharedInstance = DataLoader()

    private var callbacks: [String: (_ data: Data?) -> Void] = [:]

    func load(url: URL, _ dataCallback: ((_ data: Data?) -> Void)? = nil) {
        URLSession.dataSession.dataTask(with: url) { (data, response, error) in
            print("Data:", "fetched", data?.count ?? 0, url)
            DispatchQueue.main.async {
                dataCallback?(data)
            }
        }.resume()
    }

    func load(key: String, url: URL, _ dataCallback: ((_ data: Data?) -> Void)? = nil) {
        let file = URL.cacheDirectory.appendingPathComponent(key, isDirectory: false)
        if let data = try? Data(contentsOf: file) {
            print("Data:", "cached", data.count, key, url)
            dataCallback?(data)
            return
        }
        if let callback = dataCallback {
            callbacks[key] = callback
        }
        URLSession.dataSession.getAllTasks { (tasks) in
            guard !tasks.contains(where: { $0.originalRequest?.url == url }) else { return }
            URLSession.dataSession.dataTask(with: url) { [unowned self] (data, response, error) in
                print("Data:", "fetched", data?.count ?? 0, key, url)
                try? data?.write(to: file)
                DispatchQueue.main.async {
                    self.callbacks[key]?(data)
                    self.callbacks.removeValue(forKey: key)
                }
            }.resume()
        }
    }

}
