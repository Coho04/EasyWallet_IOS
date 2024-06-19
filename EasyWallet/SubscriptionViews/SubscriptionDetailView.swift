//
// Created by Collin Ilgner on 02.02.24.
// Copyright (c) 2024 de.golden-developer. All rights reserved.
//

import SwiftUI
import CoreData
import Sentry
import SentrySwiftUI

struct SubscriptionDetailView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var subscription: Subscription

    @Environment(\.presentationMode)
    var presentationMode

    var body: some View {
        SentryTracedView("SubscriptionDetailView") {
            List {
                Section(header:
                HStack {
                    if let urlString = subscription.url, let url = URL(string: urlString), let faviconURL = URL(string: "https://www.google.com/s2/favicons?sz=64&domain_url=\(url.host ?? "")") {
                        AsyncImage(url: faviconURL) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                                .frame(width: 20, height: 20)
                                .cornerRadius(5)
                                .padding(.trailing, 5)
                    }
                    Text(NSLocalizedString(subscription.title ?? "Unknown", comment: "Section Header"))
                            .font(.title2)
                }
                ) {
                    DetailRow(label: String(localized: "Costs"), value: "\(String(format: "%.2f €", subscription.amount)) \(repeatPattern(subscription: subscription))")
                    DetailRow(label: String(localized: "Next invoice"), value: SubscriptionDetailView.calculateNextBillDate(subscription: subscription).map {
                        DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none)
                    } ?? "")
                    DetailRow(
                            label: String(localized: "Previous invoice"),
                            value: calculatePreviousBillDate(subscription: subscription).map {
                                DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none)
                            } ?? ""
                    )
                    DetailRow(label: String(localized: "Created on"), value: subscription.timestamp.map {
                        dateFormatter.string(from: $0)
                    } ?? String(localized: "Unknown"))
                    DetailRow(label: String(localized: "Url"), value: subscription.url ?? String(localized: "Unknown"))
                }
                        .textCase(nil)

                Section {
                    if let notes = subscription.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        DetailRow(
                                label: String(localized: "Notes"),
                                value: notes
                        )
                    }
                }

                Section(header: Text(String(localized: "Actions")).font(.headline)) {
                    Button(action: pinningItem) {
                        HStack {
                            if (subscription.isPinned) {
                                Text(String(localized: "Unpin this subscription."))
                                Spacer()
                                Image(systemName: "pin.slash")
                            } else {
                                Text(String(localized: "Pin this subscription"))
                                Spacer()
                                Image(systemName: "pin")
                            }
                        }
                    }
                            .foregroundColor(.blue)
                    Button(action: pausingItem) {
                        HStack {
                            if (subscription.isPaused) {
                                Text(String(localized: "Continue this subscription"))
                                Spacer()
                                Image(systemName: "playpause.circle")
                            } else {
                                Text(String(localized: "Pause this subscription"))
                                Spacer()
                                Image(systemName: "pause.circle")
                            }
                        }
                    }
                            .foregroundColor(.gray)
                    Button(action: deleteItem) {
                        HStack {
                            Text(String(localized: "Delete this subscription"))
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                            .foregroundColor(.red)
                }
                        .textCase(nil)
            }
                    .listStyle(InsetGroupedListStyle())
                    .navigationBarTitle(String(localized: "Subscriptions"), displayMode: .inline)
                    .toolbar {
                        ToolbarItem {
                            NavigationLink(destination: SubscriptionEditView(subscription: subscription)) {
                                Image(systemName: "square.and.pencil.circle")
                                        .foregroundColor(.blue)
                            }
                        }
                    }
        }
    }

    private func repeatPattern(subscription: Subscription) -> String {
        guard let patternString = subscription.repeatPattern else {
            return ""
        }

        if let pattern = ContentView.PayRate(rawValue: patternString) {
            return NSLocalizedString(pattern.rawValue.capitalized, comment: "")
        } else {
            return ""
        }
    }


    private func calculatePreviousBillDate(subscription: Subscription) -> Date? {
        guard let startBillDate = subscription.date, let repeatPattern = subscription.repeatPattern else {
            return nil
        }

        let today = Date()
        let calendar = Calendar.current
        var potentialPreviousBillDate = startBillDate
        var dateComponentToAdd = DateComponents()
        if repeatPattern == ContentView.PayRate.monthly.rawValue {
            dateComponentToAdd.month = 1
        } else if repeatPattern == ContentView.PayRate.yearly.rawValue {
            dateComponentToAdd.year = 1
        } else {
            return nil
        }

        var lastBillDate: Date? = nil
        repeat {
            if let updatedDate = calendar.date(byAdding: dateComponentToAdd, to: potentialPreviousBillDate), updatedDate < today {
                lastBillDate = updatedDate
                potentialPreviousBillDate = updatedDate
            } else {
                break
            }
        } while potentialPreviousBillDate < today

        return lastBillDate
    }

    public static func calculateNextBillDate(subscription: Subscription) -> Date? {
        guard let startBillDate = subscription.date else {
            return nil
        }

        var nextBillDate = startBillDate
        let today = Date()
        let calendar = Calendar.current

        var dateComponentToAdd = DateComponents()
        if subscription.repeatPattern == ContentView.PayRate.monthly.rawValue {
            dateComponentToAdd.month = 1
        } else if subscription.repeatPattern == ContentView.PayRate.yearly.rawValue {
            dateComponentToAdd.year = 1
        } else {
            return nil
        }

        while nextBillDate <= today {
            if let updatedDate = calendar.date(byAdding: dateComponentToAdd, to: nextBillDate) {
                nextBillDate = updatedDate
            } else {
                return nil
            }
        }
        return nextBillDate
    }


    private func deleteItem() {
        viewContext.delete(subscription)
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            SentrySDK.capture(error: nsError)
            print("Delete failed: \(error.localizedDescription)")
        }
    }

    private func pinningItem() {
        subscription.isPinned.toggle()
        saveItem()
    }

    private func pausingItem() {
        subscription.isPaused.toggle()
        saveItem()
    }

    private func saveItem() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            SentrySDK.capture(error: nsError)
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct DetailRow: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(String(localized: "\(label)"))
                    .font(.headline)
                    .foregroundColor(.secondary)
            Text(value)
                    .font(.body)
        }
                .padding(.vertical, 2)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, dd.MM.yyyy HH:mm"
    return formatter
}()

struct SubscriptionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let subscription = Subscription.example
        SubscriptionDetailView(subscription: subscription);
    }
}
