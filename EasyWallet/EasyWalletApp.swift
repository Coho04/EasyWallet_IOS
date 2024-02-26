//
//  EasyWalletApp.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 26.02.24.
//

import SwiftUI

@main
struct EasyWalletApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
