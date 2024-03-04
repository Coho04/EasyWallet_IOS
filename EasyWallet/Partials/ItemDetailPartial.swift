//
// Created by Collin Ilgner on 19.02.24.
// Copyright (c) 2024 de.golden-developer. All rights reserved.
//

import SwiftUI

struct ItemDetailPartial: View {

    @ObservedObject var subscription: Subscription
    @State var isAnnual: Bool

    var body: some View {
        NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString(subscription.title ?? "Unknown subscription", comment: "Section Header"))
                        HStack {
                            Text(convertedPrice(for: subscription))
                                    .font(.subheadline)
                                    .foregroundColor(subscription.isPaused ? .secondary : .gray)
                            Spacer()
                            HStack {
                                Text(remainingDays(for: subscription) ?? "Unkown")
                                Text(String(localized: "Days remaining"))
                                        .font(.subheadline)
                            }
                                    .foregroundColor(subscription.isPaused ? .secondary : .gray)

                        }
                    }
                    Spacer()
                    if subscription.isPinned {
                        Image(systemName: "pin.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 44, height: 44, alignment: .center)
                    }
                }
            }
        }
                .opacity(subscription.isPaused ? 0.5 : 1)
    }

    private func remainingDays(for subscription: Subscription) -> String? {
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


    private func convertedPrice(for subscription: Subscription) -> String {
        if (subscription.amount == 0) {
            return String(localized: "For free")
        }
        if (isAnnual) {
            if (subscription.repeatPattern == ContentView.PayRate.monthly.rawValue) {
                return String(format: "%.2f €", (subscription.amount * 12))
            }
        } else {
            if (subscription.repeatPattern == ContentView.PayRate.yearly.rawValue) {
                return String(format: "%.2f €", (subscription.amount / 12))
            }
        }
        return String(format: "%.2f €", subscription.amount)
    }
}
