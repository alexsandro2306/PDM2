//
//  AnimalListView.swift
//  1M
//
//  Lista de animais com navegação para detalhes
//

import Foundation
import SwiftUI
import CoreData

struct AnimalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var filterManager = FilterManager.shared
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }	

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: isIPad ? 3 : 2)
    }
    
    @FetchRequest(
        entity: Animal.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Animal.name, ascending: true)]
    ) private var allAnimals: FetchedResults<Animal>
    
    // animais filtrados
    private var filteredAnimals: [Animal] {
        var animals = Array(allAnimals)
        
        if !filterManager.selectedSpecies.isEmpty {
            animals = animals.filter { filterManager.selectedSpecies.contains($0.species) }
        }
        
        if !filterManager.selectedBreeds.isEmpty {
            animals = animals.filter { filterManager.selectedBreeds.contains($0.breed) }
        }
        
        if !filterManager.selectedGenders.isEmpty {
            animals = animals.filter { filterManager.selectedGenders.contains($0.gender) }
        }
        
        if !filterManager.selectedAges.isEmpty {
            animals = animals.filter { filterManager.selectedAges.contains($0.age) }
        }
        
        if filterManager.showOnlyFavorites {
            animals = animals.filter { $0.isFollowing }
        }
        
        return animals
    }
    
    var body: some View {
        Group {
            if allAnimals.isEmpty {
                emptyStateView
            } else if filteredAnimals.isEmpty {
                noResultsView
            } else {
                animalList
            }
        }
        .navigationTitle("Explore")
        .navigationDestination(for: Animal.self) { animal in
            AnimalDetailView(animal: animal)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filterButton
            }
            ToolbarItem(placement: .navigationBarLeading) {
                
            }
        }
        .onAppear {
            // carregar dados mock automaticamente se não houver animais
            if allAnimals.isEmpty {
                loadMockData()
            }
        }
    }
    
    // botao de filtro
    private var filterButton: some View {
        NavigationLink {
            FilterView()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: filterManager.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                
                if filterManager.activeFilterCount > 0 {
                    Text("\(filterManager.activeFilterCount)")
                        
                }
            }
        }
    }
    
    // lista de Animais
    private var animalList: some View {
        VStack(spacing: 0) {
            if filterManager.hasActiveFilters {
                filterBanner
            }
            
            if isIPad {
                // grid para iPad
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(filteredAnimals, id: \.id) { animal in
                            NavigationLink(value: animal) {
                                AnimalCardView(animal: animal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            } else {
                // list para iPhone
                List {
                    ForEach(filteredAnimals, id: \.id) { animal in
                        NavigationLink(value: animal) {
                            AnimalRowView(animal: animal)
                        }
                    }
                }
            }
        }
    }
    
    //banner de filtros Ativos
    private var filterBanner: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
        
            
            Text("\(filteredAnimals.count) de \(allAnimals.count) animais")
     
            
            Spacer()
            
            Button("Clear") {
                filterManager.clearAll()
            }
    
        }

    }
    
    // sem Resultados
    private var noResultsView: some View {
        VStack(spacing: 20) {
        
      
            
            Text("No animals found")
        
            
       }
       
    }
    
    // sem animal
    private var emptyStateView: some View {
        VStack {
         
            
            Text("No animals found")
          

         
        }
       
    }
    
    // funcoes buscar dados
    private func loadMockData() {
        MockData.populateCoreData(context: viewContext)
    }
    

}

// view da Linha do Animal
struct AnimalRowView: View {
    let animal: Animal
    
    var body: some View {
        HStack {
                 // meter depois foto da api
                 ZStack {
                              Rectangle()
                                  .fill()
                                  
                                  .aspectRatio(1, contentMode: .fit)
                                  .frame(width: 70, height: 70)
                            
                              
                         }
        
                 
                 // informação animal
                 VStack(alignment: .leading, spacing: 6) {
                     HStack {
                         Text(animal.name)
                        }
                     
                     Text("\(animal.species) • \(animal.breed)")
                       
                     
                     HStack(spacing: 8) {
                         Label(animal.age, systemImage: "calendar")
                         Label(animal   .location, systemImage: "location.fill")
                     }
                }
                Spacer()
            }
        }
    }


struct AnimalCardView: View {
    let animal: Animal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(animal.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if animal.isFollowing {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Text("\(animal.species)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(animal.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}
#Preview {
    NavigationStack {
        AnimalListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
