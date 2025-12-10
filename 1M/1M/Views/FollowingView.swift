//
//  FollowingView.swift
//  1M
//
//  view de animais seguidos
//

import SwiftUI
import CoreData

struct FollowingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    @FetchRequest(
        entity: Animal.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Animal.pet_name, ascending: true)],
        predicate: NSPredicate(format: "isFollowing == true")
    ) private var followedAnimals: FetchedResults<Animal>
    
    var body: some View {
        Group {
            if followedAnimals.isEmpty {
                emptyStateView
            } else {
                animalsList
            }
        }
        .navigationTitle("Following")
    }
    
    // lista de animais
    private var animalsList: some View {
        VStack(spacing: 0) {
            headerView
            
            if isIPad {
                // Grid para iPad
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 16) {
                        ForEach(followedAnimals, id: \.pet_id) { animal in
                            NavigationLink(destination: AnimalDetailView(animal: animal)) {
                                AnimalCardView(animal: animal)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    unfollowAnimal(animal)
                                } label: {
                                    Label("Stop following", systemImage: "heart.slash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                // List para iPhone
                List {
                    ForEach(followedAnimals, id: \.pet_id) { animal in
                        NavigationLink(destination: AnimalDetailView(animal: animal)) {
                            FollowingAnimalRow(animal: animal)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                unfollowAnimal(animal)
                            } label: {
                                Label("Stop Following", systemImage: "heart.slash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // header
    private var headerView: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.title3)
            
            Text("\(followedAnimals.count) \(followedAnimals.count == 1 ? "animal" : "animals") followed")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
    }
    
    // se tiver vazio
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No animals followed")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Explore animals and mark your favorites")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink("Explore Animals") {
                AnimalListView()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // deixar de seguir
    private func unfollowAnimal(_ animal: Animal) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animal.isFollowing = false
            
            do {
                try viewContext.save()
            } catch {
                print("Error when unfollowing: \(error.localizedDescription)")
            }
        }
    }
}

// row de animal seguido
struct FollowingAnimalRow: View {
    let animal: Animal
    
    var body: some View {
        HStack {
            // Placeholder para foto da API
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .cornerRadius(8)
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            
            // informação animal
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(animal.pet_name ?? "Sem Nome")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Text("\(animal.species?.capitalized ?? "Unknown") • \(animal.primary_breed ?? "Mixed")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let age = animal.age {
                        Label(age.capitalized, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let city = animal.addr_city {
                        Label(city, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // Ícone baseado na espécie
    private var iconName: String {
        switch animal.species?.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "rabbit": return "hare.fill"
        case "bird": return "bird.fill"
        case "horse": return "horse"
        default: return "pawprint.fill"
        }
    }
}

// MARK: - AnimalCardView para Following (se precisar de versão específica)

struct FollowingAnimalCardView: View {
    let animal: Animal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Imagem placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                // Coração de favorito
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(8)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(animal.pet_name ?? "Sem Nome")
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(animal.species?.capitalized ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let city = animal.addr_city {
                    Text(city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let age = animal.age {
                        Text(age.capitalized)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let sex = animal.sex {
                        Text(sex == "m" ? "♂" : "♀")
                            .font(.caption2)
                            .padding(4)
                            .background(sex == "m" ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var iconName: String {
        switch animal.species?.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "rabbit": return "hare.fill"
        case "bird": return "bird.fill"
        case "horse": return "horse"
        default: return "pawprint.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Criar animais de exemplo para o preview
    let animal1 = Animal(context: context)
    animal1.pet_id = " 1"
    animal1.pet_name = "Buddy"
    animal1.species = "dog"
    animal1.primary_breed = "Labrador"
    animal1.age = "young"
    animal1.sex = "m"
    animal1.addr_city = "Lisboa"
    animal1.isFollowing = true
    
    let animal2 = Animal(context: context)
    animal2.pet_id = "2"
    animal2.pet_name = "Luna"
    animal2.species = "cat"
    animal2.primary_breed = "Siamese"
    animal2.age = "adult"
    animal2.sex = "f"
    animal2.addr_city = "Porto"
    animal2.isFollowing = true
    
    return NavigationStack {
        FollowingView()
            .environment(\.managedObjectContext, context)
    }
}
