//
//  AppDelegate.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundTask = UIBackgroundTaskInvalid

    private func beginBackgroundTask() {
        guard backgroundTask == UIBackgroundTaskInvalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: endBackgroundTask)
    }

    private func endBackgroundTask() {
        guard backgroundTask != UIBackgroundTaskInvalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow()
        window?.rootViewController = AppController()
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        beginBackgroundTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        endBackgroundTask()
    }

}
