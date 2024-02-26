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
                            Text(remainingDays(for: subscription) ?? "Unkown")
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
        let calendar = Calendar.current

        guard let itemDate = subscription.date else {
            return nil
        }

        let currentDay = calendar.startOfDay(for: Date())
        let nextPayment = calendar.startOfDay(for: itemDate)
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
