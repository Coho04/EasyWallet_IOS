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
        entity: Subscription.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Subscription.isPinned, ascending: false),
                NSSortDescriptor(keyPath: \Subscription.isPaused, ascending: true),
                NSSortDescriptor(keyPath: \Subscription.timestamp, ascending: true)
            ],
            animation: .default)
    private var fetchedSubscriptions: FetchedResults<Subscription>
    @State private var isAnnual: Bool = false
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .remainingDaysAscending

    enum SortOption {
        case alphabeticalAscending, alphabeticalDescending, costAscending, costDescending, remainingDaysAscending, remainingDaysDescending
    }

    var sortedSubscriptions: [Subscription] {
        let subscriptions = fetchedSubscriptions.filter { subscription in
                    searchText.isEmpty || subscription.title?.localizedCaseInsensitiveContains(searchText) ?? false
                }
                .map {
                    $0
                }
        return subscriptions.sorted { (firstSubscription: Subscription, secondSubscription: Subscription) -> Bool in
            if firstSubscription.isPinned && !secondSubscription.isPinned {
                return true
            } else if !firstSubscription.isPinned && secondSubscription.isPinned {
                return false
            }

            if !firstSubscription.isPaused && secondSubscription.isPaused {
                return true
            } else if firstSubscription.isPaused && !secondSubscription.isPaused {
                return false
            }

            switch sortOption {
            case .alphabeticalAscending:
                return firstSubscription.title ?? "" < secondSubscription.title ?? ""
            case .alphabeticalDescending:
                return firstSubscription.title ?? "" > secondSubscription.title ?? ""
            case .costAscending:
                var firstAmount = firstSubscription.amount
                var secondAmount = secondSubscription.amount
                if firstSubscription.repeatPattern == ContentView.PayRate.yearly.rawValue {
                    firstAmount /= 12
                }
                if secondSubscription.repeatPattern == ContentView.PayRate.yearly.rawValue {
                    secondAmount /= 12
                }
                return firstAmount < secondAmount
            case .costDescending:
                var firstAmount = firstSubscription.amount
                var secondAmount = secondSubscription.amount
                if firstSubscription.repeatPattern == ContentView.PayRate.yearly.rawValue {
                    firstAmount /= 12
                }
                if secondSubscription.repeatPattern == ContentView.PayRate.yearly.rawValue {
                    secondAmount /= 12
                }
                return firstAmount > secondAmount
            case .remainingDaysAscending:
                let firstDays = remainingDays(for: firstSubscription) ?? Int.max
                let secondDays = remainingDays(for: secondSubscription) ?? Int.max
                return firstDays < secondDays
            case .remainingDaysDescending:
                let firstDays = remainingDays(for: firstSubscription) ?? Int.max
                let secondDays = remainingDays(for: secondSubscription) ?? Int.max
                return firstDays > secondDays
            }
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
                            .underline()
                            .id(isAnnual)
                    if monthlyLimit > 0 {
                        Text(String("/"))
                        Text(String("\(isAnnual ? (monthlyLimit * 12) : monthlyLimit)"))
                                .underline()
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
                    .searchable(text: $searchText)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Menu {
                                Button("Alphabetically ascending", action: { sortOption = .alphabeticalAscending })
                                Button("Alphabetically descending", action: { sortOption = .alphabeticalDescending })
                                Button("Ascending by cost", action: { sortOption = .costAscending })
                                Button("Descending by cost", action: { sortOption = .costDescending })
                                Button("Ascending by days", action: { sortOption = .remainingDaysAscending })
                                Button("Descending by days", action: { sortOption = .remainingDaysDescending })
                            } label: {
                                Label("Sorting", systemImage: "arrow.up.arrow.down")
                            }
                        }

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

    public func remainingDays(for subscription: Subscription) -> Int? {
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
        return components.day ?? 0
    }

    private func summedAmount() -> Double {
        var sum = 0.0
        for subscription in sortedSubscriptions {
            if (subscription.repeatPattern == ContentView.PayRate.monthly.rawValue) {
                sum += subscription.amount
            } else {
                sum += (subscription.amount / 12)
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
