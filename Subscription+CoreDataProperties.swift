//
//  Subscription+CoreDataProperties.swift
//  EasyWallet
//
//  Created by Collin Ilgner on 18.03.24.
//
//

import Foundation
import CoreData


extension Subscription {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subscription> {
        return NSFetchRequest<Subscription>(entityName: "Subscription")
    }

    @NSManaged public var amount: Double
    @NSManaged public var date: Date?
    @NSManaged public var isPaused: Bool
    @NSManaged public var isPinned: Bool
    @NSManaged public var notes: String?
    @NSManaged public var remembercycle: String?
    @NSManaged public var repeatPattern: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var title: String?
    @NSManaged public var url: String?

}

extension Subscription : Identifiable {

}
