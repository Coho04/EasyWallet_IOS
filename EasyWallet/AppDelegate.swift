//
// Created by Collin Ilgner on 05.02.24.
// Copyright (c) 2024 de.golden-developer. All rights reserved.
//

import UIKit
import Sentry
import UserNotifications
import SwiftUI
import CoreData
import UserNotifications
import os

import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SentrySDK.start { options in
            options.dsn = "https://a4403bf4769fdeb774d2fcaaef82a5a2@o4504089255804929.ingest.us.sentry.io/4506915491807232"
            #if DEBUG
            options.debug = true
            options.environment = "staging"
            #else
            options.debug = false
            options.environment = "production"
            #endif

            options.enableTracing = true
            options.attachViewHierarchy = true
            options.enablePreWarmedAppStartTracing = true
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
        }

        UNUserNotificationCenter.current().delegate = self
        BackgroundTaskManager.shared.registerBackgroundTasks()
        return true
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }
}
