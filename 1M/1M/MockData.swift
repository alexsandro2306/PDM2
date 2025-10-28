import Foundation
import CoreData

struct MockData {
    
    // MARK: - Estrutura Mock de Animal
    struct MockAnimal {
        let id: String
        let name: String
        let species: String
        let breed: String
        let gender: String
        let age: String
        let location: String
        let desc: String
        let isFollowing: Bool
        
        init(id: String = UUID().uuidString,
             name: String,
             species: String,
             breed: String,
             gender: String,
             age: String,
             location: String,
             desc: String,
             isFollowing: Bool = false) {
            self.id = id
            self.name = name
            self.species = species
            self.breed = breed
            self.gender = gender
            self.age = age
            self.location = location
            self.desc = desc
            self.isFollowing = isFollowing
        }
    }
    
    // MARK: - Dados Mock Estáticos
    static let animals: [MockAnimal] = [
        MockAnimal(
            name: "Max",
            species: "Dog",
            breed: "Labrador",
            gender: "Male",
            age: "Adult",
            location: "Lisboa",
            desc: "Max é um labrador energético e amigável que adora brincar e correr no parque. Dá-se bem com crianças e outros cães."
        ),
        MockAnimal(
            name: "Luna",
            species: "Cat",
            breed: "Persian",
            gender: "Female",
            age: "Young",
            location: "Porto",
            desc: "Luna é uma gata persa elegante e tranquila. Adora carinho e passar tempo no sofá."
        ),
        MockAnimal(
            name: "Buddy",
            species: "Dog",
            breed: "Poodle",
            gender: "Male",
            age: "Senior",
            location: "Coimbra",
            desc: "Buddy é um poodle gentil e carinhoso. Apesar da idade, ainda tem muita energia para dar."
        ),
        MockAnimal(
            name: "Mia",
            species: "Cat",
            breed: "Siamese",
            gender: "Female",
            age: "Baby",
            location: "Braga",
            desc: "Mia é uma gatinha siamesa adorável e brincalhona. Está à procura de uma família amorosa."
        ),
        MockAnimal(
            name: "Rocky",
            species: "Dog",
            breed: "Bulldog",
            gender: "Male",
            age: "Adult",
            location: "Faro",
            desc: "Rocky é um bulldog forte mas muito dócil. Adora atenção e é perfeito para apartamento."
        ),
        MockAnimal(
            name: "Whiskers",
            species: "Cat",
            breed: "Maine Coon",
            gender: "Male",
            age: "Young",
            location: "Setúbal",
            desc: "Whiskers é um maine coon grande e fofo. Muito sociável e brincalhão."
        ),
        MockAnimal(
            name: "Bella",
            species: "Dog",
            breed: "Golden Retriever",
            gender: "Female",
            age: "Young",
            location: "Aveiro",
            desc: "Bella é uma golden retriever doce e leal. Adora nadar e brincar com bola."
        ),
        MockAnimal(
            name: "Oliver",
            species: "Cat",
            breed: "British Shorthair",
            gender: "Male",
            age: "Adult",
            location: "Évora",
            desc: "Oliver é um gato calmo e independente. Perfeito para quem procura um companheiro tranquilo."
        ),
        MockAnimal(
            name: "Charlie",
            species: "Dog",
            breed: "Beagle",
            gender: "Male",
            age: "Baby",
            location: "Viseu",
            desc: "Charlie é um beagle curioso e aventureiro. Ainda está a aprender mas é muito esperto."
        ),
        MockAnimal(
            name: "Nala",
            species: "Cat",
            breed: "Ragdoll",
            gender: "Female",
            age: "Adult",
            location: "Leiria",
            desc: "Nala é uma ragdoll carinhosa que adora colo. Muito gentil e tranquila."
        ),
        MockAnimal(
            name: "Thor",
            species: "Dog",
            breed: "German Shepherd",
            gender: "Male",
            age: "Adult",
            location: "Santarém",
            desc: "Thor é um pastor alemão inteligente e protetor. Precisa de bastante exercício diário."
        ),
        MockAnimal(
            name: "Chloe",
            species: "Rabbit",
            breed: "Holland Lop",
            gender: "Female",
            age: "Young",
            location: "Funchal",
            desc: "Chloe é uma coelhinha adorável e muito sociável. Adora cenouras e saltos."
        )
    ]
    
    // MARK: - Função para Popular Core Data
    static func populateCoreData(context: NSManagedObjectContext) {
        // Limpar dados existentes (opcional)
        clearCoreData(context: context)
        
        // Adicionar animais mock
        for mockAnimal in animals {
            let animal = Animal(context: context)
            animal.id = mockAnimal.id
            animal.name = mockAnimal.name
            animal.species = mockAnimal.species
            animal.breed = mockAnimal.breed
            animal.gender = mockAnimal.gender
            animal.age = mockAnimal.age
            animal.location = mockAnimal.location
            animal.desc = mockAnimal.desc
            animal.isFollowing = mockAnimal.isFollowing
            animal.lastUpdated = Date()
        }
        
        // Salvar contexto
        do {
            try context.save()
            print("✅ \(animals.count) animais mock adicionados ao Core Data")
        } catch {
            print("❌ Erro ao salvar dados mock: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Limpar Core Data
    static func clearCoreData(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Animal.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("🗑️ Core Data limpo")
        } catch {
            print("❌ Erro ao limpar Core Data: \(error.localizedDescription)")
        }
    }
}
