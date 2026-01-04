import Foundation
import CoreData

class AnimalService {
   
    private let adoptAPetURL = "https://www.adoptapet.com/public/search"
    
   
    private let mockURL = "https://carlos-aldeias-estg.github.io/pdm2-2025-mock-api/api/pets.json"
    
    private var isLoading = false
    private let context: NSManagedObjectContext
    
    // cache evitar chamadas repetidas a api
    private var lastFetchTime: Date?
    private let cacheExpiration: TimeInterval = 300
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchAnimals(species: String? = nil, forceRefresh: Bool = false, completion: @escaping (Result<[Animal], Error>) -> Void) {
        guard !isLoading else {
            print("AnimalService: Já está a carregar")
            return
        }
        
        // verificaa cache
        if !forceRefresh, let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpiration {
            print("AnimalService: A usar cache (última busca há \(Int(Date().timeIntervalSince(lastFetch))) segundos)")
            return
        }
        
        isLoading = true
        print("AnimalService: A carregar animais para: \(species ?? "todas")")
        
        Task {
            do {
                let animals = try await fetchFromAdoptAPet(species: species)
                lastFetchTime = Date()
                await MainActor.run {
                    isLoading = false
                    completion(.success(animals))
                }
            } catch let apiError {
                print("AnimalService: AdoptAPet falhou: \(apiError.localizedDescription)")
                print("AnimalService: A tentar Mock API...")
                
                do {
                    let animals = try await fetchFromMockAPI(species: species)
                    await MainActor.run {
                        isLoading = false
                        completion(.success(animals))
                    }
                } catch let mockError {
                    await MainActor.run {
                        isLoading = false
                        completion(.failure(mockError))
                    }
                }
            }
        }
    }
    
    // AdoptAPet
    
    private func fetchFromAdoptAPet(species: String?) async throws -> [Animal] {
        print("AnimalService: A buscar AdoptAPet API")
        
        // construir URL com parâmetros
        var urlComponents = URLComponents(string: adoptAPetURL)
        var queryItems = [URLQueryItem]()
        
        // Aaicionar parâmetros de busca
        if let species = species {
            // mapear gato e cao
            let searchType = species.lowercased() == "cat" ? "cat" : "dog"
            queryItems.append(URLQueryItem(name: "search_type", value: searchType))
        }
        
        // parâmetros adicionais
        queryItems.append(URLQueryItem(name: "pet_type", value: species?.lowercased() ?? "all"))
        queryItems.append(URLQueryItem(name: "geo_range", value: "50"))
        queryItems.append(URLQueryItem(name: "sort", value: "distance"))
        queryItems.append(URLQueryItem(name: "limit", value: "50"))
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw NSError(domain: "AnimalService", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "URL AdoptAPet inválida"])
        }
        
        print("AnimalService: URL: \(url.absoluteString)")
        
        // configurar request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (compatible; YourApp/1.0)", forHTTPHeaderField: "User-Agent")
        
        // requisicao
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // verificar resposta
        if let httpResponse = response as? HTTPURLResponse {
            print("AnimalService: HTTP Status: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200 else {
                throw NSError(domain: "AnimalService", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "AdoptAPet retornou HTTP \(httpResponse.statusCode)"])
            }
        }
        
        print("AnimalService: Download concluído - \(data.count) bytes")
        
        // Processar resposta do AdoptAPet
        return try await processAdoptAPetResponse(data: data, species: species)
    }
    
    private func processAdoptAPetResponse(data: Data, species: String?) async throws -> [Animal] {
        print("AnimalService: A processar resposta AdoptAPet...")
        
       
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("AnimalService: Resposta JSON recebida")
                return try await parseAdoptAPetJSON(jsonObject, species: species)
            }
        } catch {
            print("AnimalService: Não é JSON, pode ser HTML. Tentando HTML...")
        }
       
        throw NSError(domain: "AnimalService", code: 10,
                     userInfo: [NSLocalizedDescriptionKey: "Formato de resposta não suportado pelo AdoptAPet"])
    }
    
    private func parseAdoptAPetJSON(_ json: [String: Any], species: String?) async throws -> [Animal] {
        
        guard let petsArray = json["pets"] as? [[String: Any]] else {
            throw NSError(domain: "AnimalService", code: 11,
                         userInfo: [NSLocalizedDescriptionKey: "Formato JSON inválido do AdoptAPet"])
        }
        
        print("AnimalService: \(petsArray.count) pets do AdoptAPet")
        
        
        let transformedPets = transformAdoptAPetToInternalFormat(petsArray, species: species)
        return try await savePetsToCoreData(pets: transformedPets, species: species)
    }
    
    private func transformAdoptAPetToInternalFormat(_ adoptAPetPets: [[String: Any]], species: String?) -> [[String: Any]] {
        var internalPets: [[String: Any]] = []
        
        for pet in adoptAPetPets {
            var internalPet: [String: Any] = [:]
            
            // Mapear campos do AdoptAPet para o nosso formato
            internalPet["pet_id"] = pet["id"] as? String ?? "adoptapet-\(UUID().uuidString)"
            internalPet["pet_name"] = pet["name"] as? String ?? "Sem Nome"
            internalPet["sex"] = (pet["sex"] as? String)?.capitalized
            internalPet["size"] = pet["size"] as? String
            internalPet["age"] = pet["age"] as? String
            internalPet["primary_breed"] = pet["primary_breed"] as? String
            internalPet["secondary_breed"] = pet["secondary_breed"] as? String
            internalPet["addr_city"] = pet["location"] as? String
            
            // imagens
            if let photos = pet["photos"] as? [[String: Any]], let firstPhoto = photos.first {
                internalPet["results_photo_url"] = firstPhoto["medium"] as? String
                internalPet["large_results_photo_url"] = firstPhoto["large"] as? String
            }
            
            // espécie
            if let speciesType = pet["species"] as? String {
                internalPet["species"] = speciesType.lowercased()
            } else if let requestedSpecies = species {
                internalPet["species"] = requestedSpecies.lowercased()
            }
            
            internalPets.append(internalPet)
            
            
            if internalPets.count == 1 {
                print("🔍 AnimalService: Primeiro pet do AdoptAPet:")
                print("   - Nome: \(internalPet["pet_name"] as? String ?? "N/A")")
                print("   - Espécie: \(internalPet["species"] as? String ?? "N/A")")
            }
        }
        
        return internalPets
    }
    
    // Mock API
    
    private func fetchFromMockAPI(species: String?) async throws -> [Animal] {
        print("🔄 AnimalService: A usar Mock API (fallback)")
        
        guard let url = URL(string: mockURL) else {
            throw NSError(domain: "AnimalService", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "URL mock inválida"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 AnimalService (Mock): HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw NSError(domain: "AnimalService", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "Mock API HTTP \(httpResponse.statusCode)"])
            }
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "AnimalService", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "JSON mock inválido"])
        }
        
        guard let petsArray = jsonObject["pets"] as? [[String: Any]] else {
            throw NSError(domain: "AnimalService", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "'pets' não encontrado no mock"])
        }
        
        print("🐾 AnimalService (Mock): \(petsArray.count) pets no JSON")
        
        // filtrar por espécie
        let filteredPets = filterPets(petsArray, species: species)
        print("🔍 AnimalService (Mock): Filtrados: \(filteredPets.count) pets para '\(species ?? "todas")'")
        
        return try await savePetsToCoreData(pets: filteredPets, species: species)
    }
    
    
    
    private func filterPets(_ pets: [[String: Any]], species: String?) -> [[String: Any]] {
        guard let species = species?.lowercased() else {
            return pets
        }
        
        return pets.filter { pet in
            if let photoUrl = pet["results_photo_url"] as? String {
                let lowerUrl = photoUrl.lowercased()
                if species == "cat" && lowerUrl.contains("placecats.com") {
                    return true
                }
                if species == "dog" && lowerUrl.contains("place.dog") {
                    return true
                }
            }
            
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
        print("💾 AnimalService: A guardar \(pets.count) pets no Core Data")
        
        if pets.isEmpty {
            print("AnimalService: Nenhum pet para guardar")
            return []
        }
        
        return try await context.perform {
            do {
                var savedAnimals: [Animal] = []
                
                for (index, petDict) in pets.enumerated() {
                    let petId = petDict["pet_id"] as? String ?? "\(UUID().uuidString)"
                    
                    let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "pet_id == %@", petId)
                    
                    let existing = try self.context.fetch(fetchRequest)
                    let animal: Animal
                    
                    if let existingAnimal = existing.first {
                        animal = existingAnimal
                    } else {
                        animal = Animal(context: self.context)
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
                    } else if let dictSpecies = petDict["species"] as? String {
                        animal.species = dictSpecies.lowercased()
                    } else {
                        animal.species = "unknown"
                    }
                    
                    // Imagem
                    animal.imageURL = (petDict["large_results_photo_url"] as? String) ??
                                     (petDict["results_photo_url"] as? String)
                    
                    animal.last_modified = Date()
                    animal.isFollowing = false
                    
                    savedAnimals.append(animal)
                    
                    if index < 3 {
                        print("   - \(animal.pet_name ?? "N/A") (\(animal.species ?? "N/A"))")
                    }
                }
                
                if self.context.hasChanges {
                    try self.context.save()
                    print("✅ AnimalService: Guardados \(savedAnimals.count) animais no Core Data")
                }
                
                return savedAnimals
                
            } catch {
                print("❌ AnimalService: Erro Core Data: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // limpar Cache
    
    func clearCache() {
        lastFetchTime = nil
        print("🗑️ AnimalService: Cache limpo")
    }
}
