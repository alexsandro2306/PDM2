//
//  Animal+CoreDataClass.swift
//  1M
//

import Foundation
import CoreData

@objc(Animal)
public class Animal: NSManagedObject {
    
}

// propriedades core data
extension Animal {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var species: String
    @NSManaged public var breed: String
    @NSManaged public var gender: String
    @NSManaged public var age: String
    @NSManaged public var location: String
    @NSManaged public var desc: String?
    @NSManaged public var lastUpdated: Date? 
    @NSManaged public var isFollowing: Bool
    @NSManaged public var images: NSSet?
    @NSManaged public var comments: NSSet?
}
