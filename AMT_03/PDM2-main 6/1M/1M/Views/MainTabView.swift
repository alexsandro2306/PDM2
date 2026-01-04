import SwiftUI
import CoreData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var animalToShow: Animal?
    @State private var showAnimalDetail = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AnimalListView(species: "dog")
                    .navigationDestination(isPresented: $showAnimalDetail) {
                        if let animal = animalToShow {
                            AnimalDetailView(animal: animal)
                        }
                    }
            }
            .tabItem {
                Label("Dogs", systemImage: "dog.fill")
            }
            .tag(0)
            
            NavigationStack {
                AnimalListView(species: "cat")
                    .navigationDestination(isPresented: $showAnimalDetail) {
                        if let animal = animalToShow {
                            AnimalDetailView(animal: animal)
                        }
                    }
            }
            .tabItem {
                Label("Cats", systemImage: "cat.fill")
            }
            .tag(1)
            
            NavigationStack {
                FollowingView()
                    .navigationDestination(isPresented: $showAnimalDetail) {
                        if let animal = animalToShow {
                            AnimalDetailView(animal: animal)
                        }
                    }
            }
            .tabItem {
                Label("Following", systemImage: "heart.fill")
            }
            .tag(2)
            
            NavigationStack {
                AnimalMapViewModern()
                    .navigationDestination(isPresented: $showAnimalDetail) {
                        if let animal = animalToShow {
                            AnimalDetailView(animal: animal)
                        }
                    }
            }
            .tabItem {
                Label("Mapa", systemImage: "map")
            }
            .tag(3)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(4)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenAnimalDetail"))) { notification in
            if let animalId = notification.userInfo?["animalId"] as? String {
                fetchAndShowAnimal(animalId: animalId)
            }
        }
    }
    
    private func fetchAndShowAnimal(animalId: String) {
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pet_id == %@", animalId)
        
        do {
            if let animal = try context.fetch(fetchRequest).first {
                animalToShow = animal
                selectedTab = 0 // muda para a primeira tab
                showAnimalDetail = true
            }
        } catch {
            print("Error fetching animal: \(error.localizedDescription)")
        }
    }
}
