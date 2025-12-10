//
//  AnimalListView.swift
//  1M
//
//  Lista de animais com dados da API
//

import Foundation
import SwiftUI
import CoreData

struct AnimalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var filterManager = FilterManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let species: String?
    
    // State para controlar o loading e erros
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: isIPad ? 3 : 2)
    }
    
    // MODIFICADO: FetchRequest dinâmico baseado na espécie
    @FetchRequest private var allAnimals: FetchedResults<Animal>
    
    init(species: String? = nil) {
        self.species = species
        
        // Criar predicado baseado na espécie
        let predicate: NSPredicate?
        if let species = species {
            // ✅ MUDANÇA: Usar [c] para case-insensitive
            predicate = NSPredicate(format: "species ==[c] %@", species)
            print("🔍 Criando predicado para espécie: \(species)")
        } else {
            predicate = nil
            print("🔍 Sem predicado - mostrar todas as espécies")
        }
        
        _allAnimals = FetchRequest(
            entity: Animal.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Animal.pet_name, ascending: true)],
            predicate: predicate,
            animation: .default
        )
    }
    
    // Service para buscar dados da API
    private var animalService: AnimalService {
        AnimalService(context: viewContext)
    }
    
    // animais filtrados
    private var filteredAnimals: [Animal] {
        var animals = Array(allAnimals)
        
        if !filterManager.selectedSpecies.isEmpty {
            animals = animals.filter { animal in
                guard let species = animal.species else { return false }
                return filterManager.selectedSpecies.contains(species)
            }
        }
        
        if !filterManager.selectedBreeds.isEmpty {
            animals = animals.filter { animal in
                guard let breed = animal.primary_breed else { return false }
                return filterManager.selectedBreeds.contains(breed)
            }
        }
        
        if !filterManager.selectedGenders.isEmpty {
            animals = animals.filter { animal in
                guard let gender = animal.sex else { return false }
                return filterManager.selectedGenders.contains(gender)
            }
        }
        
        if !filterManager.selectedAges.isEmpty {
            animals = animals.filter { animal in
                guard let age = animal.age else { return false }
                return filterManager.selectedAges.contains(age)
            }
        }
        
        if filterManager.showOnlyFavorites {
            animals = animals.filter { $0.isFollowing }
        }
        
        return animals
    }
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if allAnimals.isEmpty {
                emptyStateView
            } else if filteredAnimals.isEmpty {
                noResultsView
            } else {
                animalList
            }
        }
        .navigationTitle(navigationTitle)
        .navigationDestination(for: Animal.self) { animal in
            AnimalDetailView(animal: animal)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    refreshButton
                    filterButton
                }
            }
        }
        .alert("Erro", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
            Button("Tentar Novamente") {
                loadAnimalsFromAPI()
            }
        } message: {
            Text(errorMessage ?? "Erro desconhecido")
        }
        .onAppear {
            print("🔄 AnimalListView apareceu - Espécie: \(species ?? "todas") - Animais no Core Data: \(allAnimals.count)")
            
            if allAnimals.isEmpty {
                print("📥 A carregar animais da API...")
                loadAnimalsFromAPI()
            } else {
                print("✅ Já existem \(allAnimals.count) animais de \(species ?? "todas as espécies")")
            }
        }
        .refreshable {
            await refreshAnimals()
        }
    }
    
    // NOVO: Título dinâmico baseado na espécie
    private var navigationTitle: String {
        switch species?.lowercased() {
        case "dog":
            return "Dogs"
        case "cat":
            return "Cats"
        case "rabbit":
            return "Rabbits"
        case "bird":
            return "Birds"
        default:
            return "Explore"
        }
    }
    
    // Views
    
    // botao de filtro
    private var filterButton: some View {
        NavigationLink {
            FilterView()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: filterManager.hasActiveFilters ?
                      "line.3.horizontal.decrease.circle.fill" :
                      "line.3.horizontal.decrease.circle")
                    .font(.title3)
                
                if filterManager.activeFilterCount > 0 {
                    Text("\(filterManager.activeFilterCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
    
    // botao de refresh
    private var refreshButton: some View {
        Button {
            loadAnimalsFromAPI()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(isLoading)
    }
    
    // loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("A carregar animais...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            
            Text("\(allAnimals.count) animais carregados")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        ForEach(filteredAnimals, id: \.pet_id) { animal in
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
                    ForEach(filteredAnimals, id: \.pet_id) { animal in
                        NavigationLink(value: animal) {
                            AnimalRowView(animal: animal)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // banner de filtros Ativos
    private var filterBanner: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundColor(.blue)
            
            Text("\(filteredAnimals.count) de \(allAnimals.count) animais")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Limpar") {
                filterManager.clearAll()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    // sem Resultados
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Nenhum animal encontrado")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Tente ajustar os filtros")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Limpar Filtros") {
                filterManager.clearAll()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // sem animal
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: speciesIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Nenhum animal disponível")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Toque para carregar animais da API")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Carregar Animais") {
                loadAnimalsFromAPI()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // NOVO: Ícone baseado na espécie
    private var speciesIcon: String {
        switch species?.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "rabbit": return "hare.fill"
        case "bird": return "bird.fill"
        default: return "pawprint"
        }
    }
    
    // funções
    
    // MODIFICADO: Passa a espécie para o serviço
    private func loadAnimalsFromAPI() {
        isLoading = true
        errorMessage = nil
        
        print("🚀 A carregar animais da API para espécie: \(species ?? "todas")")
        
        animalService.fetchAnimals(species: species) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let animals):
                    print("✅ \(animals.count) animais carregados da API")
                    print("🔍 Espécies dos animais: \(animals.map { $0.species ?? "N/A" })")
                    
                    // ✅ ADICIONA ISTO: Verificar o que está no Core Data
                    let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
                    do {
                        let allCoreDataAnimals = try self.viewContext.fetch(fetchRequest)
                        print("📦 Total de animais no Core Data: \(allCoreDataAnimals.count)")
                        print("🐱 Gatos no Core Data: \(allCoreDataAnimals.filter { $0.species?.lowercased() == "cat" }.count)")
                        print("🐶 Cães no Core Data: \(allCoreDataAnimals.filter { $0.species?.lowercased() == "dog" }.count)")
                    } catch {
                        print("❌ Erro ao verificar Core Data: \(error)")
                    }
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                    print("❌ Erro ao carregar animais: \(error)")
                }
            }
        }
    }
    
    private func refreshAnimals() async {
        await withCheckedContinuation { continuation in
            animalService.fetchAnimals(species: species) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let animals):
                        print("🔄 \(animals.count) animais de \(species ?? "todas as espécies") atualizados")
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                    continuation.resume()
                }
            }
        }
    }
}

// views Auxiliares

// view da Linha do Animal
struct AnimalRowView: View {
    let animal: Animal
    
    var body: some View {
        HStack {
            // Placeholder para foto
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .cornerRadius(8)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            
            // informação animal
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(animal.pet_name ?? "Sem Nome")
                        .font(.headline)
                    
                    Spacer()
                    
                    if animal.isFollowing {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 8) {
                    if let age = animal.age {
                        Label(age, systemImage: "calendar")
                            .font(.caption)
                    }
                    
                    if let city = animal.addr_city {
                        Label(city, systemImage: "location.fill")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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
                    Text(animal.pet_name ?? "Sem Nome")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if animal.isFollowing {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text("\(animal.species ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let city = animal.addr_city {
                    Text(city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let age = animal.age {
                        Text(age)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let sex = animal.sex {
                        Text(sex == "m" ? "♂" : "♀")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.pink.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let size = animal.size {
                        Text(size)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    NavigationStack {
        AnimalListView(species: "dog")
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
