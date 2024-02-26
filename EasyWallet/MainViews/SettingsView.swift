//
//  SettingsView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 05.02.24.
//  Copyright © 2024 de.golden-developer. All rights reserved.
//

import SwiftUI

struct SettingsView: View {

    @Environment(\.managedObjectContext) private var managedObjectContext

    @AppStorage("notificationsEnabled")
    private var notificationsEnabled = true
    @AppStorage("includeCostInNotifications")
    private var includeCostInNotifications = false
    @AppStorage("notificationTime")
    private var notificationTime = Date()
    @AppStorage("iCloudSyncEnabled")
    private var iCloudSyncEnabled = false
    @AppStorage("currency")
    private var currency = "USD"
    @AppStorage("darkModeEnabled")
    private var darkModeEnabled = false
    @AppStorage("monthlyLimit")
    private var monthlyLimit = 0.0
//    @AppStorage("categories")
//    private var categories = "Food, Utilities, Entertainment"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String(localized: "Notifications"))) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { oldValue, newValue in
                                handleNotificationsToggle(isEnabled: newValue)
                            }
                    Toggle(String(localized: "Include Cost in Notifications"), isOn: $includeCostInNotifications)
                    DatePicker(String(localized: "Notification Time"), selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                }

                Section(header: Text(String(localized: "Synchronization"))) {
                    Toggle(String(localized: "iCloud Sync"), isOn: $iCloudSyncEnabled)
                }

                Section(header: Text("Preferences")) {
                    Picker("Currency", selection: $currency) {
                        Text(String(localized: "USD")).tag("USD")
                        Text(String(localized: "EUR")).tag("EUR")
                    }
                            .pickerStyle(.navigationLink)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)

                    HStack {
                        Text(String(localized: "Monthly Limit"))
                        Spacer()
                        TextField(String(localized: "Monthly Limit"), value: $monthlyLimit, format: .currency(code: currency))
                                .multilineTextAlignment(.trailing)
                    }

                    Picker(String(localized: "Language"), selection: $currency) {
                        Text("Deutsch").tag("german")
                        Text("English").tag("English")
                    }
                            .pickerStyle(.navigationLink)

                }

                Section(header: Text(String(localized: "Support"))) {
                    Button(String(localized: "Imprint")) {
                        openWebPage(url: "https://example.com/imprint")
                    }
                    Button(String(localized: "Privacy Policy")) {
                        openWebPage(url: "https://example.com/privacy")
                    }
                    Button(String(localized: "Help")) {
                    }
                    Button(String(localized: "Feedback")) {
                    }
                    Button(String(localized: "Contact Developer")) {
                    }
                    Button(String(localized: "Tip Jar")) {
                    }
                    Button(String(localized: "Rate the App")) {
                        rateApp()
                    }
                }
            }
                    .navigationTitle(String(localized: "Settings"))
        }
    }

    private func handleNotificationsToggle(isEnabled: Bool) {
        if isEnabled {
        }
    }

    private func openWebPage(url: String) {
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
            UIApplication.shared.open(url)
        }
    }
}

extension Date: RawRepresentable {
    public var rawValue: String {
        timeIntervalSinceReferenceDate.description
    }

    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


