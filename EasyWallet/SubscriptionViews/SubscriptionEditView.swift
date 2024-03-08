//
//  ItemCreateView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 31.01.24.
//

import SwiftUI

struct SubscriptionEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var subscription: Subscription
    @State private var title: String
    @State private var url: String
    @State private var amountString: String
    @State private var date = Date()
    @State private var notes: String = ""
    @State private var paymentRate: ContentView.PayRate = .monthly
    @State private var rememberCycle: ContentView.RememberCycle = .SameDay

    init(subscription: Subscription) {
        self.subscription = subscription
        _title = State(initialValue: subscription.title ?? "")
        _notes = State(initialValue: subscription.notes ?? "")
        _amountString = State(initialValue: String(subscription.amount))
        _date = State(initialValue: subscription.date ?? Date())
        _url = State(initialValue: subscription.url ?? "")
        _paymentRate = State(initialValue: ContentView.PayRate(rawValue: subscription.repeatPattern ?? "monthly") ?? .monthly)
        _rememberCycle = State(initialValue: ContentView.RememberCycle(rawValue: subscription.remembercycle ?? "SameDay") ?? .SameDay)
    }

    var amount: Double? {
        let normalizedAmountString = amountString.replacingOccurrences(of: ",", with: ".")
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        return formatter.number(from: normalizedAmountString)?.doubleValue
    }

    var isFormValid: Bool {
        guard let amountValue = amount, !title.isEmpty else {
            return false
        }
        return amountValue >= 0.0 && amountValue <= 10000
    }


    var body: some View {
        List {
            Section(header: Text(NSLocalizedString("Subscription information", comment: "Section Header"))) {
                TextField(NSLocalizedString("Title", comment: "Section Header"), text: $title)
                        .disableAutocorrection(true)
                TextField(NSLocalizedString("URL", comment: "Section Header"), text: binding)
                        .keyboardType(.URL)
                        .accessibility(hint: Text(NSLocalizedString("URL of the subscription", comment: "Accessibility Hint")))
                        .disableAutocorrection(true)

                HStack {
                    TextField(NSLocalizedString("Amount", comment: ""), text: $amountString)
                            .keyboardType(.decimalPad)
                            .disableAutocorrection(true)
                    Spacer()
                    Text(String(localized: "Euro"))
                }

                Picker(NSLocalizedString("Payment rate", comment: ""), selection: $paymentRate) {
                    ForEach(ContentView.PayRate.allCases) { planet in
                        Text(NSLocalizedString(planet.rawValue.capitalized, comment: "Section Header"))
                    }
                }
                DatePicker(NSLocalizedString("Start Date", comment: ""),
                        selection: $date,
                        displayedComponents: [.date]
                )
                Picker(NSLocalizedString("Reminde me", comment: ""), selection: $rememberCycle) {
                    ForEach(ContentView.RememberCycle.allCases) { planet in
                        Text(NSLocalizedString(planet.rawValue.capitalized, comment: "Section Header"))
                    }
                }
                TextField(NSLocalizedString("Notes", comment: ""), text: $notes)
            }

            Section {
                Button(NSLocalizedString("Save", comment: "")) {
                    saveItem()
                }
                        .disabled(!isFormValid)
            }
        }
                .textFieldStyle(.roundedBorder)
                .navigationTitle(String(localized: "Edit subscription"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(String(localized: "Save")) {
                            saveItem()
                        }
                                .disabled(!isFormValid)
                    }
                }
    }

    private var binding: Binding<String> {
        Binding<String>(
                get: { self.url },
                set: {
                    if !$0.hasPrefix("https://") {
                        if $0.hasPrefix("http://") {
                            self.url = "https://" + $0.dropFirst(7)
                        } else {
                            self.url = "https://" + $0
                        }
                    } else {
                        self.url = $0
                    }
                }
        )
    }

    private func saveItem() {
        subscription.title = title
        subscription.amount = Double(amount ?? 0)
        subscription.repeatPattern = paymentRate.rawValue
        subscription.date = date
        subscription.url = url
        subscription.remembercycle = rememberCycle.rawValue
        subscription.notes = notes
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }


    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


class SubscriptionEditView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionCreateView()
    }
}
