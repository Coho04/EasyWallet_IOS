//
//  ContentView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 29.01.24.
//

import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {

    public enum PayRate: String, CaseIterable, Identifiable {
        case monthly, yearly
        public var id: Self {
            self
        }
    }

    public enum RememberCycle: String, CaseIterable, Identifiable {
        case SameDay, OneDayBefore, TwoDaysBefore, OneWeekBefore, None
        public var id: Self {
            self
        }
    }


    var body: some View {
        TabView {
            HomeView()
                    .tabItem {
                        Image(systemName: "creditcard.circle")
                        Text(String(localized: "Subscriptions"))
                    }
            StatisticView()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text(String(localized: "Statistics"))
                    }
            SettingsView()
                    .tabItem {
                        Label(String(localized: "Settings"), systemImage: "gear")
                    }
        }    .onAppear {
            requestPermission()
        }
    }
    
    func requestPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Authorization granted.")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("Authorization denied.")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
}


extension Subscription {
    static var example: Subscription {
        let context = PersistenceController.preview.container.viewContext
        let subscription = Subscription(context: context)
        subscription.timestamp = Date()
        return subscription
    }
}

class ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
