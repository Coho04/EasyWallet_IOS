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
    private var fetchedSubscriptions: FetchedResults<Subscription>
    @State private var isAnnual: Bool = false

    
    var sortedSubscriptions: [Subscription] {
        let subscriptions = fetchedSubscriptions.map { $0 }
        return subscriptions.sorted { firstSubscription, secondSubscription in
            if firstSubscription.isPinned != secondSubscription.isPinned {
                return firstSubscription.isPinned && !secondSubscription.isPinned
            }
            if firstSubscription.isPaused != secondSubscription.isPaused {
                return !firstSubscription.isPaused && secondSubscription.isPaused
            }
            guard let firstNextPayment = remainingDays(for: firstSubscription),
                  let secondNextPayment = remainingDays(for: secondSubscription),
                  let firstDays = Int(firstNextPayment),
                  let secondDays = Int(secondNextPayment) else {
                return false
            }
            return firstDays < secondDays
        }
    }

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
                List(sortedSubscriptions) { subscription in
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
                        if sortedSubscriptions.isEmpty {
                            Text(String(localized: "Oops, looks like there's no data..."))
                        }
                    })
        }
                .background(Color(.systemGray6))
    }
    
    
    public func remainingDays(for subscription: Subscription) -> String? {
        guard let startBillDate = subscription.date else {
            return nil
        }

        var nextBillDate = startBillDate
        let today = Date()

        let addYear = subscription.repeatPattern == ContentView.PayRate.yearly.rawValue;

        while nextBillDate <= today {
            if let updatedDate = Calendar.current.date(byAdding: addYear ? .year : .month, value: 1, to: nextBillDate) {
                nextBillDate = updatedDate
            } else {
                return nil
            }
        }
        let calendar = Calendar.current

        let currentDay = calendar.startOfDay(for: today)
        let nextPayment = calendar.startOfDay(for: nextBillDate)
        let components = calendar.dateComponents([.day], from: currentDay, to: nextPayment)
        return "\(components.day ?? 0)"
    }

    private func summedAmount() -> Double {
        var sum = 0.0
        for subscription in sortedSubscriptions {
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
