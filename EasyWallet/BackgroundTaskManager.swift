import Foundation
import UserNotifications
import BackgroundTasks
import os.log
import CoreData

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BackgroundAppRefreshManager")
private let backgroundTaskIdentifier = "de.golden-developer.easywallet.refresh"

class BackgroundTaskManager {

    private var notificationsEnabled: Bool {
        get {
            userDefaults.bool(forKey: "notificationsEnabled")
        }
        set {
            userDefaults.set(newValue, forKey: "notificationsEnabled")
        }
    }
    private var includeCostInNotifications: Bool {
        get {
            userDefaults.bool(forKey: "includeCostInNotifications")
        }
        set {
            userDefaults.set(newValue, forKey: "includeCostInNotifications")
        }
    }

    private let managedObjectContext: NSManagedObjectContext
    private let userDefaults: UserDefaults
    private let lastNotificationKey = "LastNotificationScheduleDate"

    init(context: NSManagedObjectContext, userDefaults: UserDefaults = .standard) {
        logger.log(#function)
        managedObjectContext = context
        self.userDefaults = userDefaults
    }

    static let shared = BackgroundTaskManager(context: PersistenceController.shared.container.viewContext)

    func register() {
        logger.log(#function)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            guard let bgTask = task as? BGAppRefreshTask else {
                return
            }
            self.handleTask(bgTask)
        }
    }

    private func handleTask(_ task: BGAppRefreshTask) {
        logger.log(#function)
        print("handleTask")
        if !notificationsEnabled {
            print("Notifications are disabled. Skipping.")
            logger.log("Notifications are disabled. Skipping.")
            task.setTaskCompleted(success: true)
            return
        }
        print("Notifications are enabled. Scheduling.")

        scheduleAppRefresh()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        scheduleNotifications { success in
            task.setTaskCompleted(success: success)
        }
    }

    public func scheduleAppRefresh() {
        logger.log(#function)
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.log("Task request submitted to scheduler")
        } catch {
            logger.error("Failed to schedule app refresh: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func scheduleNotifications(completion: @escaping (Bool) -> Void) {
        logger.log(#function)
        logger.log("Running scheduleNotifications")
        print("lastNotificationKey: \(lastNotificationKey)")
        if let lastScheduledDate = userDefaults.object(forKey: lastNotificationKey) as? Date, Calendar.current.isDateInToday(lastScheduledDate) {
            logger.log("Notifications were already scheduled today. Skipping.")
            completion(true)
            return
        }

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let fetchRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPaused == NO AND remembercycle != 'None'")
        do {
            let subscriptions = try managedObjectContext.fetch(fetchRequest)
            if subscriptions.isEmpty {
                completion(true)
                return
            }
            for subscription in subscriptions {
                guard let eventDate = subscription.date else { continue } // Assuming `date` is the attribute for the event date

                var triggerDate: Date?

                let calendar = Calendar.current
                switch subscription.remembercycle {
                case ContentView.RememberCycle.None.rawValue:
                    continue
                case ContentView.RememberCycle.SameDay.rawValue:
                    triggerDate = calendar.startOfDay(for: eventDate)
                case ContentView.RememberCycle.OneDayBefore.rawValue:
                    triggerDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: eventDate))
                case ContentView.RememberCycle.TwoDaysBefore.rawValue:
                    triggerDate = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: eventDate))
                case ContentView.RememberCycle.OneWeekBefore.rawValue:
                    triggerDate = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.startOfDay(for: eventDate))
                default:
                    break
                }

                guard let triggerDate = triggerDate else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Reminder"
                let bodyText = includeCostInNotifications ? "Don't forget about \(subscription.title ?? "your item"), costing \(subscription.amount)" : "Don't forget about \(subscription.title ?? "your item")!"
                content.body = bodyText

                let timeInterval = triggerDate.timeIntervalSinceNow
                if timeInterval > 0 {
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                    center.add(request) { error in
                        if let error = error {
                            logger.error("Failed to add notification: \(error.localizedDescription, privacy: .public)")
                            completion(false)
                            return
                        }
                    }
                }
            }
            userDefaults.set(Date(), forKey: lastNotificationKey)
            completion(true)
        } catch {
            logger.error("Failed to fetch items: \(error.localizedDescription, privacy: .public)")
            completion(false)
        }
    }
}
