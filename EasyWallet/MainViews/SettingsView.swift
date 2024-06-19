//
//  SettingsView.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 05.02.24.
//  Copyright © 2024 de.golden-developer. All rights reserved.
//

import SwiftUI
import CoreData
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

    @FetchRequest(entity: Subscription.entity(), sortDescriptors: [], animation: .default)
    private var fetchedSubscriptions: FetchedResults<Subscription>

    @State private var showingExportAlert = false
    @State private var exportFilePath: URL?
    @State private var isShowingShareSheet = false
    @State private var document: SubscriptionDocument?
    @State private var showDocumentPicker = false
    
    var body: some View {
        SentryTracedView("SettingsView") {
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

                        Button(String(localized: "Synchronize Now")) {
                            iCloudSync()
                        }

                        Button("Export Subscriptions") {
                                                  exportData(Array(fetchedSubscriptions))

                                              }

                        Button(String(localized: "Import Data")) {
                            importData()
                        }
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
                                    .sheet(isPresented: $isShowingShareSheet) {

                        if let exportFilePath = self.exportFilePath {
                            ShareSheet(activityItems: [exportFilePath])
                        }
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


    private func exportData(_ subscriptions: [Subscription]) {
            
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let codableSubscriptions = subscriptions.map {
                $0.toCodable()
            }
            let jsonData = try encoder.encode(codableSubscriptions)

            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let exportFileURL = temporaryDirectoryURL.appendingPathComponent("subscriptions.json")
            let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = directoryURL.appendingPathComponent("data.json")
          
            do {
                try jsonData.write(to: exportFileURL, options: .atomic)
                exportFilePath = fileURL
                let av = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            } catch {
              print("Fehler beim Speichern der Datei: \(error.localizedDescription)")
            }
        } catch {
            print("Fehler beim Exportieren der Abonnements: \(error)")
        }
    }


    private func importData() {
    }

    struct ShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context: Context) -> UIActivityViewController {
            return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            
        }
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

extension Subscription {
    func asDictionary() -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        func formatDate(_ date: Date) -> String {
            return dateFormatter.string(from: date)
        }

        return [
            "title": self.title ?? "",
            "amount": self.amount,
            "date": self.date != nil ? formatDate(self.date!) : "",
            "isPaused": self.isPaused,
            "isPinned": self.isPinned,
            "notes": self.notes ?? "",
            "rememberCycle": self.remembercycle ?? "",
            "repeatPattern": self.repeatPattern ?? "",
            "timestamp": self.timestamp != nil ? formatDate(self.timestamp!) : "",
            "url": self.url ?? "",
        ]
    }

    func toCodable() -> SubscriptionCodable {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return SubscriptionCodable(
                title: self.title ?? "",
                amount: self.amount,
                date: self.date.map {
                    dateFormatter.string(from: $0)
                },
                isPaused: self.isPaused,
                isPinned: self.isPinned,
                notes: self.notes,
                rememberCycle: self.remembercycle,
                repeatPattern: self.repeatPattern,
                timestamp: self.timestamp.map {
                    dateFormatter.string(from: $0)
                },
                url: self.url
        )
    }
}

struct SubscriptionCodable: Encodable {
    var title: String
    var amount: Double
    var date: String?
    var isPaused: Bool
    var isPinned: Bool
    var notes: String?
    var rememberCycle: String?
    var repeatPattern: String?
    var timestamp: String?
    var url: String?
}
