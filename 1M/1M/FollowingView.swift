//
//  FollowingView.swift
//  1M
//
//  Vista de animais seguidos
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
        sortDescriptors: [NSSortDescriptor(keyPath: \Animal.name, ascending: true)],
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
        .navigationTitle("Seguindo")
    }
    
    // lista de animais
    private var animalsList: some View {
        VStack(spacing: 0) {
            headerView
            
            if isIPad {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 16) {
                        ForEach(followedAnimals, id: \.id) { animal in
                            NavigationLink(destination: AnimalDetailView(animal: animal)) {
                                AnimalCardView(animal: animal)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    unfollowAnimal(animal)
                                } label: {
                                    Label("Deixar de Seguir", systemImage: "heart.slash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                List {
                    ForEach(followedAnimals, id: \.id) { animal in
                        NavigationLink(destination: AnimalDetailView(animal: animal)) {
                            FollowingAnimalRow(animal: animal)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                unfollowAnimal(animal)
                            } label: {
                                Label("Deixar de Seguir", systemImage: "heart.slash.fill")
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
                
            
            Text("\(followedAnimals.count) \(followedAnimals.count == 1 ? "animal" : "animais") seguidos")
            
            
            Spacer()
        }
      
    }
    
    // se tiver vazio
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "heart.slash")
           
            Text("Nenhum animal seguido")
               
            
            Text("Explora animais e marca os teus favoritos")
          
        }
       
    }
    
    // deixar de seguir
    private func unfollowAnimal(_ animal: Animal) {
        withAnimation {
            animal.isFollowing = false
            
            do {
                try viewContext.save()
            } catch {
                print("erro ao deixar de seguir: \(error.localizedDescription)")
            }
        }
    }
}

// row de animal seguido
struct FollowingAnimalRow: View {
    let animal: Animal
    
    var body: some View {
        HStack {
            // meter depois foto da api
            ZStack {
                
                
          
            }
            
            // informação animal
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(animal.name)
                       
                    
                    Image(systemName: "heart.fill")
                    
                }
                
                Text("\(animal.species) • \(animal.breed)")
                  
                
                HStack(spacing: 12) {
                    Label(animal.age, systemImage: "calendar")
                    Label(animal.location, systemImage: "location.fill")
                }
           
            }
            
            Spacer()
            
        
              
        }
        
    }
    
  
    
}
// preview para testes
#Preview {
    NavigationStack {
        FollowingView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
