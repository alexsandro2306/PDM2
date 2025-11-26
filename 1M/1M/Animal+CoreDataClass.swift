//
//  Animal+CoreDataClass.swift
//  1M
//

import Foundation
import CoreData

@objc(Animal)
public class Animal: NSManagedObject {

}

extension Animal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Animal> {
        return NSFetchRequest<Animal>(entityName: "Animal")
    }



    @NSManaged public var pet_id:String?
    @NSManaged public var sex: String?
    @NSManaged public var size: String?
    @NSManaged public var addr_city: String?
    @NSManaged public var pet_name: String?
    @NSManaged public var color: String?
    @NSManaged public var age: String?
    @NSManaged public var primary_breed: String?
    @NSManaged public var secondary_breed: String?
    @NSManaged public var species: String?
    @NSManaged public var last_modified: Date?
    @NSManaged public var isFollowing: Bool


    @NSManaged public var images: NSSet?
    @NSManaged public var comments: NSSet?
}

