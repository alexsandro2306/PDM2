import Foundation
import CoreData

class AnimalService {
    private let baseURL = "https://api-staging.adoptapet.com/search/pet_search"
    private let apiKey = "hg4nsv85lppeoqqixy3tnlt3k8lj6o0c"
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchAnimals(
        cityOrZip: String = "10001",
        geoRange: Int = 50,
        species: String? = nil,  // ✅ MUDANÇA: nil por default
        startNumber: Int = 1,
        endNumber: Int = 10,
        completion: @escaping (Result<[Animal], Error>) -> Void
    ) {
        // ✅ MUDANÇA: Construir URL dinamicamente
        var urlString = "\(baseURL)?key=\(apiKey)&v=3&output=json&city_or_zip=\(cityOrZip)&geo_range=\(geoRange)&start_number=\(startNumber)&end_number=\(endNumber)"
        
        // ✅ Só adiciona species se existir
        if let species = species {
            urlString += "&species=\(species)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🔗 A buscar: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Erro de rede: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                print("❌ Sem dados")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                print("✅ Status: \(apiResponse.status)")
                
                if apiResponse.status == "ok", let pets = apiResponse.pets {
                    print("🐾 Encontrados \(pets.count) animais")
                    
                    // ✅ MUDANÇA: Passar o species para saveAnimalsToCoreData
                    self.saveAnimalsToCoreData(pets: pets, species: species) { result in
                        DispatchQueue.main.async {
                            completion(result)
                        }
                    }
                }
                else if let exception = apiResponse.exception {
                    print("❌ API Exception: \(exception.msg)")
                    DispatchQueue.main.async {
                        completion(.failure(APIException.error(exception)))
                    }
                } else {
                    print("❌ Resposta desconhecida")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.unknownResponse))
                    }
                }
                
            } catch {
                print("❌ ERRO DECODING: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔍 Key não encontrada: \(key) em \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("🔍 Type mismatch: \(type) em \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("🔍 Value não encontrado: \(type) em \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("🔍 Data corrompida: \(context)")
                    @unknown default:
                        print("🔍 Erro desconhecido")
                    }
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    
    private func saveAnimalsToCoreData(pets: [PetDTO], species: String?, completion: @escaping (Result<[Animal], Error>) -> Void) {
        print("🚨 saveAnimalsToCoreData INICIADA - Espécie: \(species ?? "todas")")
        print("💾 Recebidos \(pets.count) pets para guardar")
        
        context.perform {
            do {
                var savedAnimals: [Animal] = []
                
                for (index, petDTO) in pets.enumerated() {
                    print("🔄 [\(index + 1)/\(pets.count)] \(petDTO.pet_name ?? "Sem nome")")
                    
                    guard let petId = petDTO.pet_id else {
                        print("   ⚠️ pet_id vazio - SKIP")
                        continue
                    }
                    
                    let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "pet_id == %@", petId)
                    
                    let existingAnimals = try self.context.fetch(fetchRequest)
                    
                    let animal: Animal
                    
                    if let existingAnimal = existingAnimals.first {
                        animal = existingAnimal
                    } else {
                        animal = Animal(context: self.context)
                    }
                    
                    // Mapeamento
                    animal.pet_id = petId
                    animal.pet_name = petDTO.pet_name
                    animal.sex = petDTO.sex
                    animal.size = petDTO.size
                    animal.addr_city = petDTO.addr_city
                    animal.color = petDTO.color
                    animal.age = petDTO.age
                    animal.primary_breed = petDTO.primary_breed
                    animal.secondary_breed = petDTO.secondary_breed
                    
                    // ✅ MUDANÇA CRÍTICA: Usar species do parâmetro, não do DTO
                    animal.species = species?.lowercased() ?? "unknown"
                    print("   🏷️ Espécie: \(animal.species ?? "N/A")")
                    
                    animal.isFollowing = false
                    
                    if let photos = petDTO.photos, let firstPhoto = photos.first {
                        animal.imageURL = firstPhoto.url
                    }
                    
                    if let lastModifiedString = petDTO.last_modified {
                        let formatter = ISO8601DateFormatter()
                        animal.last_modified = formatter.date(from: lastModifiedString)
                    } else {
                        animal.last_modified = Date()
                    }
                    
                    savedAnimals.append(animal)
                }
                
                print("💾 A guardar \(savedAnimals.count) animais...")
                
                if self.context.hasChanges {
                    try self.context.save()
                    print("🎉 SUCESSO! Guardados \(savedAnimals.count) animais!")
                } else {
                    print("⚠️ Sem mudanças no contexto")
                }
                
                completion(.success(savedAnimals))
                
            } catch {
                print("❌ ERRO ao guardar: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    
    
    func fetchAnimalsWithFilters(
        filters: AnimalFilters,
        completion: @escaping (Result<[Animal], Error>) -> Void
    ) {
        var urlString = "\(baseURL)?key=\(apiKey)&v=3&output=json&city_or_zip=\(filters.cityOrZip)&geo_range=\(filters.geoRange)&start_number=\(filters.startNumber)&end_number=\(filters.endNumber)"
        
        if let species = filters.species {
            urlString += "&species=\(species)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // ✅ MUDANÇA: Passar species para fetchAnimalsWithURL
        fetchAnimalsWithURL(url, species: filters.species, completion: completion)
    }
    
    private func fetchAnimalsWithURL(_ url: URL, species: String?, completion: @escaping (Result<[Animal], Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                
                if apiResponse.status == "ok", let pets = apiResponse.pets {
                    // ✅ MUDANÇA: Passar species para saveAnimalsToCoreData
                    self?.saveAnimalsToCoreData(pets: pets, species: species) { result in
                        DispatchQueue.main.async {
                            completion(result)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.unknownResponse))
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}

// MODELOS
struct APIResponse: Codable {
    let status: String
    let pets: [PetDTO]?
    let exception: APIException?
}

struct PetDTO: Codable {
    let pet_id: String?
    let pet_name: String?
    let sex: String?
    let age: String?
    let size: String?
    let primary_breed: String?
    let secondary_breed: String?
    let addr_city: String?
    let addr_state_code: String?
    let color: String?
    let species: String?
    let last_modified: String?
    let contact: ContactDTO?
    let breeds: BreedsDTO?
    let photos: [PhotoDTO]?
    
    let order: Int?
    let primaryPhotoId: Int?
    let primary_breed_id: Int?
    let details_url: String?
    let results_photo_url: String?
}

struct ContactDTO: Codable {
    let city: String?
    let state: String?
    let email: String?
    let phone: String?
}

struct BreedsDTO: Codable {
    let primary: String?
    let secondary: String?
}

struct PhotoDTO: Codable {
    let url: String?
    let size: String?
}

struct APIException: Codable, Error {
    let msg: String
    let details: String?
    
    static func error(_ exception: APIException) -> Error {
        return NSError(domain: "AdoptAPetAPI", code: 0, userInfo: [
            NSLocalizedDescriptionKey: exception.msg,
            NSLocalizedFailureReasonErrorKey: exception.details ?? ""
        ])
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case unknownResponse
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "URL inválida"
        case .noData: return "Nenhum dado recebido"
        case .unknownResponse: return "Resposta desconhecida da API"
        }
    }
}

struct AnimalFilters {
    let cityOrZip: String
    let geoRange: Int
    let startNumber: Int
    let endNumber: Int
    var species: String?
    var breedId: String?
    var sex: String?
    var age: String?
    var colorId: String?
    var petSizeRangeId: String?
    
    init(cityOrZip: String = "10001",
         geoRange: Int = 50,
         startNumber: Int = 1,
         endNumber: Int = 10) {
        self.cityOrZip = cityOrZip
        self.geoRange = geoRange
        self.startNumber = startNumber
        self.endNumber = endNumber
    }
}
