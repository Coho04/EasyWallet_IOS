//
//  ItemCreateView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 31.01.24.
//

import SwiftUI
import Sentry
import SentrySwiftUI

struct SubscriptionCreateView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var url: String = ""
    @State private var amountString: String = ""
    @State private var showGreeting: ContentView.PayRate = .monthly
    @State private var rememberCycle: ContentView.RememberCycle = .SameDay
    @State private var date = Date()

    var amount: Double? {
        Double(amountString.replacingOccurrences(of: ",", with: "."))
    }

    var isFormValid: Bool {
        guard let amount = amount else {
            return false
        }
        return !title.isEmpty && amount >= 0 && amount <= 10000
    }

    var body: some View {
        SentryTracedView("SubscriptionCreateView"){
            List {
                Section {
                    TextField(String(localized: "Title"), text: $title)
                        .disableAutocorrection(true)
                    TextField(String(localized: "URL"), text: binding)
                        .keyboardType(.URL)
                        .accessibility(hint: Text(String(localized: "URL of the subscription")))
                        .disableAutocorrection(true)
                    
                    
                    HStack {
                        HStack {
                            TextField(String(localized: "Amount"), text: $amountString)
                                .keyboardType(.decimalPad)
                                .disableAutocorrection(true)
                            Text(String(localized: "Euro"))
                        }
                        .padding(.horizontal, 21)
                    }
                    .listRowInsets(EdgeInsets())
                    
                    
                    DatePicker(String(localized: "Start Date"),
                               selection: $date,
                               displayedComponents: [.date]
                    )
                    
                    Picker(String(localized: "Payment rate"), selection: $showGreeting) {
                        ForEach(ContentView.PayRate.allCases) { planet in
                            Text(NSLocalizedString(planet.rawValue.capitalized, comment: "Section Header"))
                        }
                    }
                    
                    Picker(String(localized: "Reminde me"), selection: $rememberCycle) {
                        ForEach(ContentView.RememberCycle.allCases) { planet in
                            Text(NSLocalizedString(planet.rawValue.capitalized, comment: "Section Header"))
                        }
                    }
                    TextField(String(localized: "Notes"), text: $notes)
                }
                .padding(10)
                
                Section {
                    Button(String(localized: "Save")) {
                        saveItem()
                    }
                    .disabled(!isFormValid)
                }
            }
            .textFieldStyle(.roundedBorder)
            .navigationTitle(String(localized: "Add subscription"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Save")) {
                        saveItem()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var binding: Binding<String> {
        Binding<String>(
                get: { self.url },
                set: {
                    if (!$0.isEmpty) {
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
                }
        )
    }


    private func saveItem() {
        let viewContext = PersistenceController.shared.container.viewContext
        let subscription = Subscription(context: viewContext)
        subscription.title = title
        subscription.amount = Double(amount ?? 0)
        subscription.date = date
        subscription.repeatPattern = showGreeting.rawValue
        subscription.notes = notes
        subscription.url = url
        subscription.remembercycle = rememberCycle.rawValue
        subscription.timestamp = Date()
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            SentrySDK.capture(error: error)
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        presentationMode.wrappedValue.dismiss()
        print("Saving item with title: \(title) and amount: \(amount ?? 0)")
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


class SubscriptionCreateView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionCreateView()
    }
}
