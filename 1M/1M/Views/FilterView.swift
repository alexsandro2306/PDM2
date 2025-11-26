import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var filterManager = FilterManager.shared
    
    // estados locais temporários para cancelar sem aplicar
    @State private var tempSpecies: Set<String> = []
    @State private var tempBreeds: Set<String> = []
    @State private var tempGenders: Set<String> = []
    @State private var tempAges: Set<String> = []
    @State private var tempShowOnlyFavorites = false
    
    // filtros disponiveis
    let availableSpecies = ["Dog", "Cat", "Rabbit", "Bird", "Horse"]
    let availableBreeds = ["Labrador", "Poodle", "Bulldog", "Persian", "Siamese",
                          "Golden Retriever", "Beagle", "German Shepherd",
                          "Maine Coon", "British Shorthair", "Ragdoll", "Holland Lop"]
    let availableGenders = ["Male", "Female", "Unknown"]
    let availableAges = ["Baby", "Young", "Adult", "Senior"]
    
    var body: some View {
        Form {
            // espécies
            Section("Species") {
                ForEach(availableSpecies, id: \.self) { species in
                    Toggle(species, isOn: Binding(
                        get: { tempSpecies.contains(species) },
                        set: { isSelected in
                            if isSelected {
                                tempSpecies.insert(species)
                            } else {
                                tempSpecies.remove(species)
                            }
                        }
                    ))
                }
            }
            
            // raças
            Section("Breeds") {
                ForEach(availableBreeds, id: \.self) { breed in
                    Toggle(breed, isOn: Binding(
                        get: { tempBreeds.contains(breed) },
                        set: { isSelected in
                            if isSelected {
                                tempBreeds.insert(breed)
                            } else {
                                tempBreeds.remove(breed)
                            }
                        }
                    ))
                }
            }
            
            // género
            Section("Gender") {
                ForEach(availableGenders, id: \.self) { gender in
                    Toggle(gender, isOn: Binding(
                        get: { tempGenders.contains(gender) },
                        set: { isSelected in
                            if isSelected {
                                tempGenders.insert(gender)
                            } else {
                                tempGenders.remove(gender)
                            }
                        }
                    ))
                }
            }
            
            // idade
            Section("Age") {
                ForEach(availableAges, id: \.self) { age in
                    Toggle(age, isOn: Binding(
                        get: { tempAges.contains(age) },
                        set: { isSelected in
                            if isSelected {
                                tempAges.insert(age)
                            } else {
                                tempAges.remove(age)
                            }
                        }
                    ))
                }
            }
            
            // Favoritos
            Section("Favorites") {
                Toggle("Show only favorites", isOn: $tempShowOnlyFavorites)
            }
            
            // ações
            Section {
                Button("Clear All Filters", role: .destructive) {
                    clearFilters()
                }
                
                Button("Apply Filters") {
                    applyFilters()
                    dismiss()
                }
                .disabled(!hasChanges)
            }
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadCurrentFilters()
        }
    }
    
    // carregar filtros atuais
    private func loadCurrentFilters() {
        tempSpecies = filterManager.selectedSpecies
        tempBreeds = filterManager.selectedBreeds
        tempGenders = filterManager.selectedGenders
        tempAges = filterManager.selectedAges
        tempShowOnlyFavorites = filterManager.showOnlyFavorites
    }
    
    // verificar se há mudanças
    private var hasChanges: Bool {
        tempSpecies != filterManager.selectedSpecies ||
        tempBreeds != filterManager.selectedBreeds ||
        tempGenders != filterManager.selectedGenders ||
        tempAges != filterManager.selectedAges ||
        tempShowOnlyFavorites != filterManager.showOnlyFavorites
    }
    
    // limpar filtros
    private func clearFilters() {
        tempSpecies.removeAll()
        tempBreeds.removeAll()
        tempGenders.removeAll()
        tempAges.removeAll()
        tempShowOnlyFavorites = false
    }
    
    // aplicar filtros
    private func applyFilters() {
        filterManager.selectedSpecies = tempSpecies
        filterManager.selectedBreeds = tempBreeds
        filterManager.selectedGenders = tempGenders
        filterManager.selectedAges = tempAges
        filterManager.showOnlyFavorites = tempShowOnlyFavorites
        
        print("applied filters:")
        print("Species: \(tempSpecies)")
        print("Breeds: \(tempBreeds)")
        print("Gender: \(tempGenders)")
        print("Age: \(tempAges)")
        print("Favorites only: \(tempShowOnlyFavorites)")
    }
}

#Preview {
    FilterView()
}
