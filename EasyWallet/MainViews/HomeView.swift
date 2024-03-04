//
//  HomeView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 05.02.24.
//  Copyright © 2024 de.golden-developer. All rights reserved.
//

import SwiftUI

struct HomeView: View {

    @AppStorage("monthlyLimit")
    private var monthlyLimit = 0.0

    @FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Subscription.isPinned, ascending: false),
                NSSortDescriptor(keyPath: \Subscription.isPaused, ascending: true),
                NSSortDescriptor(keyPath: \Subscription.timestamp, ascending: true)
            ],
            animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    @State private var isAnnual: Bool = false

    var body: some View {
        NavigationStack {
            HStack {
                Text(String(localized: "Subscriptions"))
                        .font(.title)
                Spacer()
                HStack {
                    Text(String(format: "%.2f", summedAmount()))
                            .id(isAnnual)
                    if monthlyLimit > 0 {
                        Text(String("/"))
                        Text(String("\(isAnnual ? (monthlyLimit * 12) : monthlyLimit)"))
                    }
                    Text(String("€"))
                }
            }
                    .padding()

            Form {
                Section {
                    Picker(selection: $isAnnual, label: Text(String(localized: "Payment rate"))) {
                        Text(String(localized: "Monthly"))
                                .font(.title)
                                .tag(false)
                        Text(String(localized: "Yearly"))
                                .font(.title)
                                .tag(true)
                    }
                }
                List(subscriptions) { subscription in
                    ItemDetailPartial(subscription: subscription, isAnnual: isAnnual)
                            .id(isAnnual)
                }
            }
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            NavigationLink(destination: SubscriptionCreateView()) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .overlay(Group {
                        if subscriptions.isEmpty {
                            Text(String(localized: "Oops, looks like there's no data..."))
                        }
                    })
        }
                .background(Color(.systemGray6))
    }

    private func summedAmount() -> Double {
        var sum = 0.0
        for subscription in subscriptions {
            if (subscription.repeatPattern == ContentView.PayRate.monthly.rawValue) {
                sum += subscription.amount
            } else {
                sum += (subscription.amount/12)
            }
            
        }
        return isAnnual ? sum * 12 : sum
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
