
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
                // imagem do animal (placeholder)
                animalImageHeader
                
                // informação principal
                VStack(alignment: .leading, spacing: 20) {
                    // nome e botão de favorito
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(animal.name)
                                
                            
                            Text("\(animal.species) • \(animal.breed)")
                       
                        }
                        
                        Spacer()
                        
                        favoriteButton
                    }
                    
                    // tags de informação
                    infoTagsView
                    
                    Divider()
                    
                    // descrição
                    if let description = animal.desc, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                    }
                    
                    // detalhes
                    detailsSection
                    
                    Divider()
                    
                    // localização
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
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete animal", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAnimal()
            }
        } message: {
            Text("Are you sure you want to delete \(animal.name)?")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    // header com imagem
    private var animalImageHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Pplaceholder de imagem
            Rectangle()
                .frame(height: 250)
}
      
    }
    
    // botao favorito
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
    
    // tags de informacao
    private var infoTagsView: some View {
        HStack(spacing: 12) {
            InfoTag(icon: "calendar", text: animal.age, color: .blue)
            InfoTag(icon: genderIcon, text: animal.gender, color: genderColor)
            InfoTag(icon: "location.fill", text: animal.location, color: .green)
        }
    }
    
    // detalhes
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalails")
                .font(.headline)
            
            DetailRow(icon: "pawprint.fill", title: "Species", value: animal.species)
            DetailRow(icon: "tag.fill", title: "Breed", value: animal.breed)
            DetailRow(icon: "person.fill", title: "Gender", value: animal.gender)
            DetailRow(icon: "calendar", title: "Age", value: animal.age)
            
            if let lastUpdated = animal.lastUpdated {
                DetailRow(
                    icon: "clock.fill",
                    title: "Updated",
                    value: formatDate(lastUpdated)
                )
            }
        }
    }
    
    // localizao
    private var locationSection: some View {
        VStack {
            Text("Location")
                .font(.headline)
            
            HStack {
                Image(systemName: "mappin.circle.fill")
             
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(animal.location)
                
                    
                   
                }
                
                Spacer()
                

            }
     
        }
    }
    
    // botoes acao
    private var actionButtons: some View {
        VStack {
       
            HStack {
       
                
                Button(action: { showShareSheet = true }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                
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
            print("Error saving: \(error.localizedDescription)")
        }
    }
    
    private func generateShareText() -> String {
        """
        Meet \(animal.name)! 🐾
        
        \(animal.species) • \(animal.breed)
        Age: \(animal.age)
        Location: \(animal.location)
        
        \(animal.desc ?? "")
        "Help find a home for this friend!"
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
    animal.desc = "Max is an energetic and friendly Labrador who loves to play and run in the park."
    animal.isFollowing = false
    
    return NavigationStack {
        AnimalDetailView(animal: animal)
            .environment(\.managedObjectContext, context)
    }
}
