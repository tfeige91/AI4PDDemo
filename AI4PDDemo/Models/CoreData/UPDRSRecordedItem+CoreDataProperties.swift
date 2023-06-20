//
//  UPDRSRecordedItem+CoreDataProperties.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.06.23.
//
//

import Foundation
import CoreData


extension UPDRSRecordedItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UPDRSRecordedItem> {
        return NSFetchRequest<UPDRSRecordedItem>(entityName: "UPDRSRecordedItem")
    }

    @NSManaged public var orderNumber: Int16
    @NSManaged public var name: String?
    @NSManaged public var videoURL: URL?
    @NSManaged public var date: Date?
    @NSManaged public var rating: Int16
    @NSManaged public var session: Session?

    public var wrappedName: String {
        name ?? "UPDRS Aufnahme"
    }
    
    public var wrappedDate: Date {
        return date ?? Date(timeIntervalSinceReferenceDate: 190_058_400.0)
    }
}

extension UPDRSRecordedItem : Identifiable {

}
