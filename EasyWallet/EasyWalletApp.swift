//
//  EasyWalletApp.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 26.02.24.
//

import SwiftUI
import BackgroundTasks


@main
struct EasyWalletApp: App {

    let persistenceController = PersistenceController.shared
    @Environment(\.managedObjectContext) private var viewContext
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
                .onChange(of: phase) { oldPhase, newPhase in
                    switch newPhase {
                    case .background:  BackgroundTaskManager.shared.scheduleAppRefresh()
                        break;
                    default: break
                    }
                }
    }
}
