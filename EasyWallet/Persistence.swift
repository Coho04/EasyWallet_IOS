import CoreData
import CloudKit

struct PersistenceController {
    static var shared: PersistenceController = {
        let useCloudSync  = UserDefaults.standard.bool(forKey: "iCloudSync")
        return PersistenceController(inMemory: false, useCloudSync: useCloudSync)
    }()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true, useCloudSync: false)
        let viewContext = result.container.viewContext
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false, useCloudSync: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "EasyWallet")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        if useCloudSync {
            let storeDescription = container.persistentStoreDescriptions.first
            storeDescription?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.de.golden-developer.easywallet.Subscriptions")
        } else {
            container.persistentStoreDescriptions.first?.cloudKitContainerOptions = nil
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
