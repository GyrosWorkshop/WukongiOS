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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow()
        window?.rootViewController = AppController()
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if UIBackgroundTaskInvalid ~= backgroundTask {
            backgroundTask = application.beginBackgroundTask {
                application.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
    }

}
