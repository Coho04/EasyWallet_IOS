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

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task as! BGAppRefreshTask)
        }
    }

    private func handleAppRefresh(_ task: BGAppRefreshTask) {
        scheduleAppRefresh()
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

    public func scheduleNotifications(completion: @escaping (Bool) -> Void) {
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

            var notificationsScheduled = false
            for subscription in subscriptions {
                guard let eventDate = SubscriptionDetailView.calculateNextBillDate(subscription: subscription) else {
                    continue
                }
                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)

                switch subscription.remembercycle {
                case ContentView.RememberCycle.SameDay.rawValue:
                    break
                case ContentView.RememberCycle.OneDayBefore.rawValue:
                    dateComponents.day! -= 1
                case ContentView.RememberCycle.TwoDaysBefore.rawValue:
                    dateComponents.day! -= 2
                case ContentView.RememberCycle.OneWeekBefore.rawValue:
                    dateComponents.day! -= 7
                default:
                    continue
                }

                guard let triggerDate = calendar.date(from: dateComponents) else {
                    continue
                }
                if calendar.isDateInToday(triggerDate) {
                    let content = UNMutableNotificationContent()
                    content.title = String(localized: "Hint")
                    let title = subscription.title ?? "your item"
                    let cost = String(subscription.amount) + "€"
                    var bodyStringKey = ""
                    switch subscription.remembercycle {
                    case ContentView.RememberCycle.SameDay.rawValue:
                        bodyStringKey = includeCostInNotifications ? "today_debited_with_coasts" : "today_debited"
                        break
                    case ContentView.RememberCycle.OneDayBefore.rawValue:
                        bodyStringKey = includeCostInNotifications ? "tomorrow_debited_with_coasts" : "tomorrow_debited"
                        break
                    case ContentView.RememberCycle.TwoDaysBefore.rawValue:
                        bodyStringKey = includeCostInNotifications ? "two_days_debited_with_coasts" : "two_days_debited"
                        break
                    case ContentView.RememberCycle.OneWeekBefore.rawValue:
                        bodyStringKey = includeCostInNotifications ? "one_week_debited_with_coasts" : "one_week_debited"
                        break
                    default:
                        continue
                    }
                    content.body = includeCostInNotifications ? String(format: NSLocalizedString(bodyStringKey, comment: ""), title, cost) : String(format: NSLocalizedString(bodyStringKey, comment: ""), title)

                    let triggerTime = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
                    logger.log("Scheduling notification for: \(triggerTime)")

                    let triggerDaily = Calendar.current.dateComponents([.hour, .minute, .second], from: triggerTime)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDaily, repeats: false)

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    center.add(request) { error in
                        if let error = error {
                            print("Failed to add notification: \(error)")
                            completion(false)
                            return
                        }
                    }
                    notificationsScheduled = true
                }
            }

            if notificationsScheduled {
                print("At least one notification was scheduled for today.")
                userDefaults.set(Date(), forKey: lastNotificationKey)
                completion(true)
            } else {
                print("No notifications needed to be scheduled for today.")
                completion(false)
            }
        } catch {
            print("Failed to fetch items: \(error)")
            completion(false)
        }
    }
}
