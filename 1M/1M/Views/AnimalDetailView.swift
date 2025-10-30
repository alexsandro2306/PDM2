
import SwiftUI
import CoreData

struct AnimalDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let animal: Animal
    
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Imagem do animal (placeholder)
                animalImageHeader
                
                // Informação principal
                VStack(alignment: .leading, spacing: 20) {
                    // Nome e botão de favorito
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(animal.name)
                                
                            
                            Text("\(animal.species) • \(animal.breed)")
                       
                        }
                        
                        Spacer()
                        
                        favoriteButton
                    }
                    
                    // Tags de informação rápida
                    infoTagsView
                    
                    Divider()
                    
                    // Descrição
                    if let description = animal.desc, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sobre")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                    }
                    
                    // Detalhes
                    detailsSection
                    
                    Divider()
                    
                    // Localização
                    locationSection
                    
                    // Botões de ação
                    actionButtons
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showShareSheet = true }) {
                        Label("Partilhar", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Eliminar Animal", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteAnimal()
            }
        } message: {
            Text("Tens a certeza que queres eliminar \(animal.name)?")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    // MARK: - Header com Imagem
    private var animalImageHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Placeholder de imagem
            Rectangle()
      
                    
            
            
            // Ícone grande do animal
            Image(systemName: iconName)
       
            

        }
      
    }
    
    // MARK: - Botão de Favorito
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            ZStack {
                Circle()
                    .fill(animal.isFollowing ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: animal.isFollowing ? "heart.fill" : "heart")
     
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tags de Informação
    private var infoTagsView: some View {
        HStack(spacing: 12) {
            InfoTag(icon: "calendar", text: animal.age, color: .blue)
            InfoTag(icon: genderIcon, text: animal.gender, color: genderColor)
            InfoTag(icon: "location.fill", text: animal.location, color: .green)
        }
    }
    
    // Detalhes
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalhes")
                .font(.headline)
            
            DetailRow(icon: "pawprint.fill", title: "Espécie", value: animal.species)
            DetailRow(icon: "tag.fill", title: "Raça", value: animal.breed)
            DetailRow(icon: "person.fill", title: "Género", value: animal.gender)
            DetailRow(icon: "calendar", title: "Idade", value: animal.age)
            
            if let lastUpdated = animal.lastUpdated {
                DetailRow(
                    icon: "clock.fill",
                    title: "Atualizado",
                    value: formatDate(lastUpdated)
                )
            }
        }
    }
    
    // localizao
    private var locationSection: some View {
        VStack {
            Text("Localização")
                .font(.headline)
            
            HStack {
                Image(systemName: "mappin.circle.fill")
             
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(animal.location)
                
                    
                   
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Ver no Mapa")
    
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // botoes acao
    private var actionButtons: some View {
        VStack {
       
            HStack {
       
                
                Button(action: { showShareSheet = true }) {
                    Label("Partilhar", systemImage: "square.and.arrow.up")
                
                        .frame(maxWidth: .infinity)
                                                
                }
            }
        }
       
    }
    
    // funções
    private func toggleFavorite() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animal.isFollowing.toggle()
            saveContext()
        }
    }
    
    private func deleteAnimal() {
        viewContext.delete(animal)
        saveContext()
        dismiss()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Erro ao salvar: \(error.localizedDescription)")
        }
    }
    
    private func generateShareText() -> String {
        """
        Conhece o \(animal.name)! 🐾
        
        \(animal.species) • \(animal.breed)
        Idade: \(animal.age)
        Localização: \(animal.location)
        
        \(animal.desc ?? "")
        
        Ajuda a encontrar um lar para este amigo!
        """
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // propriedades predefenidas
    private var iconName: String {
        switch animal.species.lowercased() {
        case "dog": return "pawprint.fill"
        case "cat": return "cat.fill"
        case "rabbit": return "hare.fill"
        case "bird": return "bird.fill"
        case "horse": return "horse"
        default: return "pawprint"
        }
    }
    

    // icones de generos
    private var genderIcon: String {
        switch animal.gender.lowercased() {
        case "male": return "figure.stand"
        case "female": return "figure.stand.dress"
        default: return "questionmark.circle"
        }
    }
    // cores dos generos
    private var genderColor: Color {
        switch animal.gender.lowercased() {
        case "male": return .blue
        case "female": return .pink
        default: return .gray
        }
    }
}



struct InfoTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
               
            Text(text)
               
        }
     
    }
}

// caixa detalhes
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                
            
            Text(title)
        
            
            Spacer()
            
            Text(value)
         
        }
    }
}

// partilha de animal
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
// teste para layout
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let animal = Animal(context: context)
    animal.id = UUID().uuidString
    animal.name = "Max"
    animal.species = "Dog"
    animal.breed = "Labrador"
    animal.gender = "Male"
    animal.age = "Adult"
    animal.location = "Lisboa"
    animal.desc = "Max é um labrador energético e amigável que adora brincar e correr no parque."
    animal.isFollowing = false
    
    return NavigationStack {
        AnimalDetailView(animal: animal)
            .environment(\.managedObjectContext, context)
    }
}
