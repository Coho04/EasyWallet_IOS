//
//  ContentView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 29.01.24.
//

import SwiftUI
import CoreData

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
//
            SettingsView()
                    .tabItem {
                        Label(String(localized: "Settings"), systemImage: "gear")
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
