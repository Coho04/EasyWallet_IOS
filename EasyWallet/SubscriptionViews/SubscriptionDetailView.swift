//
// Created by Collin Ilgner on 02.02.24.
// Copyright (c) 2024 de.golden-developer. All rights reserved.
//

import SwiftUI
import CoreData

struct SubscriptionDetailView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var subscription: Subscription

    var body: some View {
        List {
                Section(header: Text(NSLocalizedString(subscription.title ?? "Unknown", comment: "Section Header")).font(.title2)) {
                DetailRow(label: String(localized: "Costs"), value: "\(String(format: "%.2f €", subscription.amount)) \(subscription.repeatPattern ?? "monatlich")")
                DetailRow(label: String(localized: "Next invoice"), value: subscription.date.map {
                    dateFormatter.string(from: $0)
                } ?? "Unbekannt")
                DetailRow(label: String(localized: "Previous invoice"), value: "27. Januar 2024")
                DetailRow(label: String(localized: "Created on"), value: subscription.timestamp.map {dateFormatter.string(from: $0)} ?? "Unbekannt")
            }
                    .textCase(nil)
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

    private func calculatePreviousBillDate(from nextBillDate: Date?) -> Date {
        guard let nextBillDate = nextBillDate else {
            return Date()
        }
        var dateComponents = DateComponents()
        dateComponents.month = -1
        return Calendar.current.date(byAdding: dateComponents, to: nextBillDate) ?? Date()
    }

    private func deleteItem() {
        viewContext.delete(subscription)
        do {
            try viewContext.save()
        } catch {
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
