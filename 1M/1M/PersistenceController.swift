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
        
        // adicionar animais de exemplo para o preview (com campos da API)
        let viewContext = controller.container.viewContext
        addPreviewData(to: viewContext)
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AdocaoModel") // ou o nome do teu .xcdatamodeld
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // configuração para lightweight migration / para nao corromper
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
    
    // evitar captura do self
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
    
    // dados estaticos para preview (atualizados com campos da API)
    private static func addPreviewData(to context: NSManagedObjectContext) {
        let mockAnimals = [
            (12345, "Buddy", "dog", "Labrador", "m", "young", "large", "Golden", "Lisboa", true, Date()),
            (12346, "Luna", "cat", "Siamese", "f", "adult", "small", "Cream", "Porto", true, Date()),
            (12347, "Max", "dog", "Mixed Breed", "m", "senior", "medium", "Black", "Faro", false, Date()),
            (12348, "Bella", "dog", "German Shepherd", "f", "young", "large", "Black/Tan", "Coimbra", false, Date()),
            (12349, "Charlie", "cat", "Persian", "m", "baby", "small", "White", "Aveiro", true, Date())
        ]
        
        for animalData in mockAnimals {
            let animal = Animal(context: context)
            animal.pet_id = String(animalData.0)
            animal.pet_name = animalData.1
            animal.species = animalData.2
            animal.primary_breed = animalData.3
            animal.sex = animalData.4
            animal.age = animalData.5
            animal.size = animalData.6
            animal.color = animalData.7
            animal.addr_city = animalData.8
            animal.isFollowing = animalData.9
            animal.last_modified = animalData.10
            
            // Campos opcionais que podem ser nil
            animal.secondary_breed = nil
       
        }
        
        do {
            try context.save()
            print("✅ Preview data created successfully: \(mockAnimals.count) animals")
        } catch {
            let nsError = error as NSError
            print("❌ Error saving preview context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // salvar contexto
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Context saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Função auxiliar para limpar todos os dados (útil para desenvolvimento)
    func clearAllData() {
        let context = container.viewContext
        
        // Entidades para limpar
        let entityNames = ["Animal", "Photo"] // Adiciona outras entidades se tiveres
        
        for entityName in entityNames {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.persistentStoreCoordinator.execute(deleteRequest, with: context)
                print("✅ Cleared all \(entityName) data")
            } catch {
                print("❌ Error clearing \(entityName): \(error)")
            }
        }
        
        saveContext()
    }
    
    // Função para contar animais na base de dados
    func getAnimalCount() -> Int {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("❌ Error counting animals: \(error)")
            return 0
        }
    }
    
    // Função para verificar se há animais seguidos
    func getFollowedAnimalsCount() -> Int {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFollowing == true")
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("❌ Error counting followed animals: \(error)")
            return 0
        }
    }
}

// MARK: - Extensão para facilitar o acesso ao contexto
extension PersistenceController {
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}
