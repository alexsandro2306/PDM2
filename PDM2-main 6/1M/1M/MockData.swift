import Foundation
import CoreData

struct MockData {
    
    // estrutura mock animal
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
    
    //dados
    static let animals: [MockAnimal] = [
        MockAnimal(
            name: "Max",
            species: "Dog",
            breed: "Labrador",
            gender: "Male",
            age: "Adult",
            location: "Lisboa",
            desc: "Max is an energetic and friendly Labrador who loves to play and run in the park. He gets along well with children and other dogs."
        ),
        MockAnimal(
            name: "Luna",
            species: "Cat",
            breed: "Persian",
            gender: "Female",
            age: "Young",
            location: "Porto",
            desc: "Luna is an elegant and calm Persian cat. She loves affection and spending time on the sofa."
        ),
        MockAnimal(
            name: "Buddy",
            species: "Dog",
            breed: "Poodle",
            gender: "Male",
            age: "Senior",
            location: "Coimbra",
            desc: "Buddy is a gentle and affectionate poodle. Despite his age, he still has plenty of energy to spare."
        ),
        MockAnimal(
            name: "Mia",
            species: "Cat",
            breed: "Siamese",
            gender: "Female",
            age: "Baby",
            location: "Braga",
            desc: "Mia is an adorable and playful Siamese kitten. She is looking for a loving family."
        ),
        MockAnimal(
            name: "Rocky",
            species: "Dog",
            breed: "Bulldog",
            gender: "Male",
            age: "Adult",
            location: "Faro",
            desc: "Rocky is a strong but very docile bulldog. He loves attention and is perfect for apartment living."
        ),
        MockAnimal(
            name: "Whiskers",
            species: "Cat",
            breed: "Maine Coon",
            gender: "Male",
            age: "Young",
            location: "Setúbal",
            desc: "Whiskers is a large, fluffy Maine Coon. He is very sociable and playful."
        ),
        MockAnimal(
            name: "Bella",
            species: "Dog",
            breed: "Golden Retriever",
            gender: "Female",
            age: "Young",
            location: "Aveiro",
            desc: "Bella is a sweet and loyal golden retriever. She loves swimming and playing with balls."
        ),
        MockAnimal(
            name: "Oliver",
            species: "Cat",
            breed: "British Shorthair",
            gender: "Male",
            age: "Adult",
            location: "Évora",
            desc: "Oliver is a calm and independent cat. Perfect for those looking for a quiet companion."
        ),
        MockAnimal(
            name: "Charlie",
            species: "Dog",
            breed: "Beagle",
            gender: "Male",
            age: "Baby",
            location: "Viseu",
            desc: "Charlie is a curious and adventurous beagle. He is still learning, but he is very smart."
        ),
        MockAnimal(
            name: "Nala",
            species: "Cat",
            breed: "Ragdoll",
            gender: "Female",
            age: "Adult",
            location: "Leiria",
            desc: "Nala is an affectionate ragdoll who loves to be held. She is very gentle and calm."
        ),
        MockAnimal(
            name: "Thor",
            species: "Dog",
            breed: "German Shepherd",
            gender: "Male",
            age: "Adult",
            location: "Santarém",
            desc: "Thor is an intelligent and protective German Shepherd. He needs plenty of daily exercise."
        ),
        MockAnimal(
            name: "Chloe",
            species: "Rabbit",
            breed: "Holland Lop",
            gender: "Female",
            age: "Young",
            location: "Funchal",
            desc: "Chloe is an adorable and very sociable bunny. She loves carrots and jumping."
        )
    ]
    
    // função para popular core data
    static func populateCoreData(context: NSManagedObjectContext) {
      
        
        // adicionar animais mock
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
        
        // salvar contexto
        do {
            try context.save()
            print(" \(animals.count) mock animals added to Core Data")
        } catch {
            print(" Error saving mock data: \(error.localizedDescription)")
        }
    }
    
}
