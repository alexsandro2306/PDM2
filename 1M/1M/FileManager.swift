import Foundation
import Combine

class FilterManager: ObservableObject {
    static let shared = FilterManager()
    
    @Published var selectedSpecies: Set<String> = []
    @Published var selectedBreeds: Set<String> = []
    @Published var selectedGenders: Set<String> = []
    @Published var selectedAges: Set<String> = []
    @Published var showOnlyFavorites: Bool = false
    
    // Verificar se há filtros ativos
    var hasActiveFilters: Bool {
        !selectedSpecies.isEmpty ||
        !selectedBreeds.isEmpty ||
        !selectedGenders.isEmpty ||
        !selectedAges.isEmpty ||
        showOnlyFavorites
    }
    
    // Limpar todos os filtros
    func clearAll() {
        selectedSpecies.removeAll()
        selectedBreeds.removeAll()
        selectedGenders.removeAll()
        selectedAges.removeAll()
        showOnlyFavorites = false
    }
    
    // Contar filtros ativos
    var activeFilterCount: Int {
        var count = 0
        if !selectedSpecies.isEmpty { count += 1 }
        if !selectedBreeds.isEmpty { count += 1 }
        if !selectedGenders.isEmpty { count += 1 }
        if !selectedAges.isEmpty { count += 1 }
        if showOnlyFavorites { count += 1 }
        return count
    }
}
