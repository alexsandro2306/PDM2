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
                // imagem do animal
                animalImageHeader
                
                // informação principal
                VStack(alignment: .leading, spacing: 20) {
                    // nome e botão de favorito
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(animal.pet_name ?? "Sem Nome")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(animal.species ?? "Unknown") • \(animal.primary_breed ?? "Mixed")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        favoriteButton
                    }
                    
                    // tags de informação
                    infoTagsView
                    
                    Divider()
                    
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
            Text("Are you sure you want to delete \(animal.pet_name ?? "this animal")?")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    // MARK: - Header com Imagem
    
    private var animalImageHeader: some View {
        AsyncImage(url: URL(string: "")) { phase in
            switch phase {
            case .empty:
                // Carregando
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading image...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
            case .success(let image):
                // Imagem carregada com sucesso
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                
            case .failure:
                // Erro ao carregar - mostrar placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 12) {
                        Image(systemName: iconName)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("No image available")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 5)
                }
                
            @unknown default:
                // Fallback
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
            }
        }
        .frame(height: 300)
        .clipped()
    }
    
    // MARK: - Botão Favorito
    
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            ZStack {
                Circle()
                    .fill(animal.isFollowing ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: animal.isFollowing ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(animal.isFollowing ? .red : .gray)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tags de Informação
    
    private var infoTagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let age = animal.age {
                    InfoTag(icon: "calendar", text: age.capitalized, color: .blue)
                }
                
                if let sex = animal.sex {
                    InfoTag(icon: genderIcon, text: sex == "m" ? "Male" : "Female", color: genderColor)
                }
                
                if let size = animal.size {
                    InfoTag(icon: "ruler.fill", text: size.capitalized, color: .orange)
                }
                
                if let city = animal.addr_city {
                    InfoTag(icon: "location.fill", text: city, color: .green)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Detalhes
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            if let species = animal.species {
                DetailRow(icon: "pawprint.fill", title: "Species", value: species.capitalized)
            }
            
            if let breed = animal.primary_breed {
                DetailRow(icon: "tag.fill", title: "Breed", value: breed)
            }
            
            if let sex = animal.sex {
                DetailRow(icon: "person.fill", title: "Gender", value: sex == "m" ? "Male" : "Female")
            }
            
            if let age = animal.age {
                DetailRow(icon: "calendar", title: "Age", value: age.capitalized)
            }
            
            if let size = animal.size {
                DetailRow(icon: "ruler.fill", title: "Size", value: size.capitalized)
            }
            
            if let color = animal.color {
                DetailRow(icon: "paintpalette.fill", title: "Color", value: color)
            }
            
            if let lastModified = animal.last_modified {
                DetailRow(
                    icon: "clock.fill",
                    title: "Last Updated",
                    value: formatDate(lastModified)
                )
            }
        }
    }
    
    // MARK: - Localização
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            
            HStack(alignment: .top) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let city = animal.addr_city {
                        Text(city)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    if let state = animal.contact?.state {
                        Text(state)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let phone = animal.contact?.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    if let email = animal.contact?.email, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Botões de Ação
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Botão Contactar
                Button(action: contactShelter) {
                    Label("Contact", systemImage: "phone.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                // Botão Partilhar
                Button(action: { showShareSheet = true }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Funções
    
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
    
    private func contactShelter() {
        // Implementar lógica para contactar o abrigo
        print("Contactar abrigo para: \(animal.pet_name ?? "animal")")
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
        Meet \(animal.pet_name ?? "this amazing pet")! 🐾
        
        \(animal.species?.capitalized ?? "Pet") • \(animal.primary_breed ?? "Mixed Breed")
        Age: \(animal.age?.capitalized ?? "Unknown")
        Location: \(animal.addr_city ?? "Unknown")
        Gender: \(animal.sex == "m" ? "Male" : "Female")
        
        Help find a loving home for this friend! ❤️
        """
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Propriedades Computadas
    
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
    
    private var genderIcon: String {
        switch animal.sex {
        case "m": return "figure.stand"
        case "f": return "figure.stand.dress"
        default: return "questionmark.circle"
        }
    }
    
    private var genderColor: Color {
        switch animal.sex {
        case "m": return .blue
        case "f": return .pink
        default: return .gray
        }
    }
}

// MARK: - Views Auxiliares

struct InfoTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Extensões

extension Animal {
    var contact: ContactInfo? {
        // Se tiveres uma entidade Contact no Core Data, implementar aqui
        // Por agora, retorna nil
        return nil
    }
}

struct ContactInfo {
    let phone: String?
    let email: String?
    let state: String?
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let animal = Animal(context: context)
    animal.pet_id = "12345"
    animal.pet_name = "Buddy"
    animal.species = "dog"
    animal.primary_breed = "Labrador"
    animal.sex = "m"
    animal.age = "young"
    animal.size = "large"
    animal.color = "Golden"
    animal.addr_city = "Lisboa"
    animal.isFollowing = false
    animal.last_modified = Date()
    animal.imageURL = "https://example.com/dog.jpg"
    
    return NavigationStack {
        AnimalDetailView(animal: animal)
            .environment(\.managedObjectContext, context)
    }
}
