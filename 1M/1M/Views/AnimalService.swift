import Foundation
import CoreData

class AnimalService {
    private let mockURL = "https://carlos-aldeias-estg.github.io/pdm2-2025-mock-api/api/pets.json"
    private var isLoading = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchAnimals(species: String? = nil, completion: @escaping (Result<[Animal], Error>) -> Void) {
        guard !isLoading else {
            print("⚠️ AnimalService: Já está a carregar")
            return
        }
        
        isLoading = true
        
        print("🚀 AnimalService: A carregar animais para: \(species ?? "todas")")
        
        // Usar async/await para evitar problemas com URLSession
        Task {
            do {
                let animals = try await fetchAnimalsAsync(species: species)
                await MainActor.run {
                    isLoading = false
                    completion(.success(animals))
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func fetchAnimalsAsync(species: String?) async throws -> [Animal] {
        print("🔗 AnimalService: A buscar Mock API async")
        
        guard let url = URL(string: mockURL) else {
            throw NSError(domain: "AnimalService", code: 1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        
        // 1. Fazer download dos dados
        print("📥 AnimalService: A fazer download...")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        print("✅ AnimalService: Download concluído - \(data.count) bytes")
        
        // 2. Verificar resposta HTTP
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 AnimalService: HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw NSError(domain: "AnimalService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
        }
        
        // 3. Processar JSON
        print("🔄 AnimalService: A processar JSON...")
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "AnimalService", code: 3, userInfo: [NSLocalizedDescriptionKey: "JSON inválido"])
        }
        
        print("✅ AnimalService: JSON parseado!")
        print("📊 AnimalService: Status: \(jsonObject["status"] as? String ?? "N/A")")
        
        guard let petsArray = jsonObject["pets"] as? [[String: Any]] else {
            throw NSError(domain: "AnimalService", code: 4, userInfo: [NSLocalizedDescriptionKey: "'pets' não encontrado"])
        }
        
        print("🐾 AnimalService: \(petsArray.count) pets no JSON")
        
        if let firstPet = petsArray.first {
            print("🔍 AnimalService: Primeiro pet:")
            print("   - Nome: \(firstPet["pet_name"] as? String ?? "N/A")")
            print("   - Foto: \(firstPet["results_photo_url"] as? String ?? "N/A")")
            print("   - Raça: \(firstPet["primary_breed"] as? String ?? "N/A")")
        }
        
        // 4. Filtrar por espécie
        let filteredPets = filterPets(petsArray, species: species)
        print("🔍 AnimalService: Filtrados: \(filteredPets.count) pets para '\(species ?? "todas")'")
        
        // 5. Salvar no Core Data
        return try await savePetsToCoreData(pets: filteredPets, species: species)
    }
    
    private func filterPets(_ pets: [[String: Any]], species: String?) -> [[String: Any]] {
        guard let species = species?.lowercased() else {
            return pets
        }
        
        return pets.filter { pet in
            // 1. Verificar pela URL da foto
            if let photoUrl = pet["results_photo_url"] as? String {
                let lowerUrl = photoUrl.lowercased()
                if species == "cat" && lowerUrl.contains("placecats.com") {
                    return true
                }
                if species == "dog" && lowerUrl.contains("place.dog") {
                    return true
                }
            }
            
            // 2. Verificar pelo nome da raça
            if let breed = pet["primary_breed"] as? String {
                let lowerBreed = breed.lowercased()
                let catBreeds = ["maine coon", "persian cat", "siamese cat", "bengal cat", "british shorthair"]
                
                if species == "cat" {
                    return catBreeds.contains { lowerBreed.contains($0) }
                }
                if species == "dog" {
                    return !catBreeds.contains { lowerBreed.contains($0) } && !lowerBreed.contains("cat")
                }
            }
            
            return false
        }
    }
    
    private func savePetsToCoreData(pets: [[String: Any]], species: String?) async throws -> [Animal] {
        print("💾 AnimalService: A guardar \(pets.count) pets")
        
        if pets.isEmpty {
            print("⚠️ AnimalService: Nenhum pet para guardar")
            return []
        }
        
        return try await context.perform {
            do {
                var savedAnimals: [Animal] = []
                
                for (index, petDict) in pets.enumerated() {
                    // Criar ID único se não existir
                    let petId = petDict["pet_id"] as? String ?? "mock-\(UUID().uuidString)"
                    
                    // Verificar se já existe
                    let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "pet_id == %@", petId)
                    
                    let existing = try self.context.fetch(fetchRequest)
                    let animal: Animal
                    
                    if let existingAnimal = existing.first {
                        animal = existingAnimal
                        print("🔄 AnimalService: Atualizando \(petDict["pet_name"] as? String ?? "Sem nome")")
                    } else {
                        animal = Animal(context: self.context)
                        print("➕ AnimalService: Novo \(petDict["pet_name"] as? String ?? "Sem nome")")
                    }
                    
                    // Preencher dados
                    animal.pet_id = petId
                    animal.pet_name = petDict["pet_name"] as? String
                    animal.sex = petDict["sex"] as? String
                    animal.size = petDict["size"] as? String
                    animal.addr_city = petDict["addr_city"] as? String
                    animal.age = petDict["age"] as? String
                    animal.primary_breed = petDict["primary_breed"] as? String
                    animal.secondary_breed = petDict["secondary_breed"] as? String
                    animal.color = nil
                    
                    // Determinar espécie
                    if let requestedSpecies = species {
                        animal.species = requestedSpecies.lowercased()
                    } else {
                        // Auto-detetar
                        if let photoUrl = petDict["results_photo_url"] as? String {
                            if photoUrl.lowercased().contains("placecats.com") {
                                animal.species = "cat"
                            } else if photoUrl.lowercased().contains("place.dog") {
                                animal.species = "dog"
                            } else {
                                animal.species = "unknown"
                            }
                        } else {
                            animal.species = "unknown"
                        }
                    }
                    
                    // Imagem
                    animal.imageURL = (petDict["large_results_photo_url"] as? String) ?? (petDict["results_photo_url"] as? String)
                    
                    animal.last_modified = Date()
                    animal.isFollowing = false
                    
                    savedAnimals.append(animal)
                    
                    // Log
                    if index < 2 {
                        print("📝 AnimalService: \(index + 1). \(animal.pet_name ?? "N/A") (\(animal.species ?? "N/A"))")
                    }
                }
                
                if self.context.hasChanges {
                    try self.context.save()
                    print("✅ AnimalService: Guardados \(savedAnimals.count) animais!")
                    
                    // Verificar total
                    let countRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
                    if let species = species {
                        countRequest.predicate = NSPredicate(format: "species ==[c] %@", species)
                    }
                    let total = try self.context.count(for: countRequest)
                    print("📊 AnimalService: Total no Core Data: \(total)")
                }
                
                return savedAnimals
                
            } catch {
                print("❌ AnimalService: Erro Core Data: \(error.localizedDescription)")
                throw error
            }
        }
    }
}
