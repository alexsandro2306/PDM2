//
//  PersistenceController.swift
//  1M
//
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // adicionar animais de exemplo para o preview
        let viewContext = controller.container.viewContext
        addPreviewData(to: viewContext)
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AdocaoModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // configuração para lightweight migration
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores { [container] storeDesc, error in
            if let error = error as NSError? {
                print("Error loading Core Data: \(error), \(error.userInfo)")
                
                // tentar recriar a base de dados se falhar
                Self.recreatePersistentStore(for: container)
            } else {
                print("Core Data successfully loaded!")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // evitar captura do seld
    private static func recreatePersistentStore(for container: NSPersistentContainer) {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            fatalError("The store URL could not be obtained.")
        }
        
        do {
            print("Attempting to recreate the database...")
            
            // remove a store corrompida
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            
            // tenta carregar novamente
            container.loadPersistentStores { storeDesc, error in
                if let error = error {
                    fatalError("Critical failure when recreating Core Data: \(error)")
                } else {
                    print("Database successfully recreated!")
                }
            }
        } catch {
            fatalError("Failed to recreate database: \(error)")
        }
    }
    
    // dados estaticos
    private static func addPreviewData(to context: NSManagedObjectContext) {
        let mockAnimals = [
            ("Max", "Dog", "Labrador", "Male", "Young", "Lisboa", "Labrador muito brincalhão", true),
            ("Luna", "Dog", "Poodle", "Female", "Adult", "Porto", "Poodle inteligente", false),
            ("Bobby", "Dog", "Bulldog", "Male", "Senior", "Faro", "Bulldog tranquilo", true)
        ]
        
        for animalData in mockAnimals {
            let animal = Animal(context: context)
            animal.id = UUID().uuidString
            animal.name = animalData.0
            animal.species = animalData.1
            animal.breed = animalData.2
            animal.gender = animalData.3
            animal.age = animalData.4
            animal.location = animalData.5
            animal.desc = animalData.6
            animal.isFollowing = animalData.7
            animal.lastUpdated = Date()
        }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Error saving preview context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // salvar contexto
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print(" Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
