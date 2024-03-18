//
//  SettingsView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 05.02.24.
//  Copyright © 2024 de.golden-developer. All rights reserved.
//

import SwiftUI
import SentrySwiftUI

struct SettingsView: View {

    @Environment(\.managedObjectContext) private var managedObjectContext

    @AppStorage("notificationsEnabled")
    private var notificationsEnabled = true
    @AppStorage("includeCostInNotifications")
    private var includeCostInNotifications = false
    @AppStorage("notificationTime")
    private var notificationTime = Date()
    @AppStorage("iCloudSync")
    private var iCloudSyncEnabled = false
    @AppStorage("currency")
    private var currency = "USD"

    @State
    private var showingSettingsAlert = false
    @AppStorage("monthlyLimit")
    private var monthlyLimit = 0.0

    var body: some View {
        SentryTracedView("SettingsView"){
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
                        /*
                         Button(String(localized: "Synchronize Now")) {
                         iCloudSync()
                         }
                         Button(String(localized: "Export Data")) {
                         exportData()
                         }
                         Button(String(localized: "Import Data")) {
                         importData()
                         }
                         
                         */
                    }
                    
                    
                    Section(header: Text("Preferences")) {
                        //  Picker("Currency", selection: $currency) {
                        //     Text(String(localized: "USD")).tag("USD")
                        //       Text(String(localized: "EUR")).tag("EUR")
                        //   }
                        //          .pickerStyle(.navigationLink)
                        
                        HStack {
                            Text(String(localized: "Monthly Limit"))
                            Spacer()
                            TextField(String(localized: "Monthly Limit"), value: $monthlyLimit, format: .currency(code: currency))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section(header: Text(String(localized: "Support"))) {
                        Button(String(localized: "Imprint")) {
                            openWebPage(url: "https://golden-developer.de/imprint")
                        }
                        Button(String(localized: "Privacy Policy")) {
                            openWebPage(url: "https://golden-developer.de/privacy")
                        }
                        Button(String(localized: "Help")) {
                            openWebPage(url: "https://support.golden-developer.de")
                        }
                        Button(String(localized: "Feedback")) {
                            rateApp()
                        }
                        Button(String(localized: "Contact Developer")) {
                            openWebPage(url: "https://support.golden-developer.de")
                        }
                        Button(String(localized: "Tip Jar")) {
                            openWebPage(url: "https://donate.golden-developer.de")
                        }
                        Button(String(localized: "Rate the App")) {
                            rateApp()
                        }
                    }
                }
                .navigationTitle(String(localized: "Settings"))
            }
            .alert(isPresented: $showingSettingsAlert) {
                Alert(
                    title: Text(String(localized: "Notification deactivated")),
                    message: Text(String(localized: "Would you like to activate notifications in the settings?")),
                    primaryButton: .default(Text(String(localized: "Open Settings"))) {
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func handleNotificationsToggle(isEnabled: Bool) {
        if isEnabled {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        requestNotificationsAuthorization(center: center)
                    case .denied:
                        promptUserToOpenSettings()
                    case .authorized, .provisional, .ephemeral:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }
    }

    private func iCloudSync() {

    }

    private func exportData() {
    }

    private func importData() {
    }


    private func requestNotificationsAuthorization(center: UNUserNotificationCenter) {
        NSLog("requestNotificationsAuthorization")
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                NSLog("Notifications authorized")
            } else {
                NSLog("Notifications denied: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    private func promptUserToOpenSettings() {
        self.showingSettingsAlert = true
    }

    private func openWebPage(url: String) {
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/6478509715") {
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


