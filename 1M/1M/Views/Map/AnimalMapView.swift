import SwiftUI
import MapKit
import CoreLocation

// MARK: - Vista do Mapa (SwiftUI moderna - iOS 17+)
@available(iOS 17.0, *)
struct AnimalMapViewModern: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Animal.pet_name, ascending: true)],
        animation: .default)
    private var animals: FetchedResults<Animal>
    
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.1579, longitude: -8.6291),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )
    @State private var selectedAnimal: Animal?
    @State private var showingAnimalDetail = false
    
    var filteredAnimals: [Animal] {
        animals.filter { $0.addr_city != nil }
    }
    
    var animalLocations: [AnimalLocation] {
        filteredAnimals.compactMap { animal in
            guard let city = animal.addr_city,
                  let coordinate = geocodeCity(city) else { return nil }
            return AnimalLocation(animal: animal, coordinate: coordinate)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Mapa SwiftUI
                Map(position: $position, selection: $selectedAnimal) {
                    // Localização do usuário
                    UserAnnotation()
                    
                    // Animais no mapa
                    ForEach(animalLocations) { location in
                        Annotation(
                            location.animal.pet_name ?? "Animal",
                            coordinate: location.coordinate
                        ) {
                            ZStack {
                                Circle()
                                    .fill(speciesColor(location.animal.species))
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 3)
                                
                                Image(systemName: "pawprint.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                        }
                        .tag(location.animal)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Controles e Card
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button(action: showAllAnimals) {
                                Image(systemName: "map")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Card do animal selecionado
                    if let animal = selectedAnimal {
                        AnimalMapCard(animal: animal, showingDetail: $showingAnimalDetail)
                            .padding()
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationTitle("Mapa de Animais")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(filteredAnimals.count) animais")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingAnimalDetail) {
                if let animal = selectedAnimal {
                    AnimalDetailView(animal: animal)
                }
            }
            .onChange(of: selectedAnimal) { oldValue, newValue in
                if let animal = newValue, let city = animal.addr_city,
                   let coordinate = geocodeCity(city) {
                    withAnimation {
                        position = .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                        )
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
            if let userLocation = locationManager.location {
                position = .region(
                    MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    )
                )
            }
        }
    }
    
    private func speciesColor(_ species: String?) -> Color {
        guard let species = species?.lowercased() else { return .green }
        if species.contains("cat") {
            return .orange
        } else if species.contains("dog") {
            return .blue
        }
        return .green
    }
    
    private func showAllAnimals() {
        guard !animalLocations.isEmpty else { return }
        
        var minLat = 90.0
        var maxLat = -90.0
        var minLon = 180.0
        var maxLon = -180.0
        
        for location in animalLocations {
            minLat = min(minLat, location.coordinate.latitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            minLon = min(minLon, location.coordinate.longitude)
            maxLon = max(maxLon, location.coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.5, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.5, (maxLon - minLon) * 1.5)
        )
        
        withAnimation {
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}

// MARK: - Animal Location Model
struct AnimalLocation: Identifiable {
    let id = UUID()
    let animal: Animal
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

// MARK: - Geocoding Helper (coordenadas fixas para cidades portuguesas)
func geocodeCity(_ city: String?) -> CLLocationCoordinate2D? {
    guard let city = city?.lowercased() else { return nil }
    
    let portugueseCities: [String: CLLocationCoordinate2D] = [
        "porto": CLLocationCoordinate2D(latitude: 41.1579, longitude: -8.6291),
        "lisbon": CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
        "lisboa": CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
        "braga": CLLocationCoordinate2D(latitude: 41.5454, longitude: -8.4265),
        "coimbra": CLLocationCoordinate2D(latitude: 40.2033, longitude: -8.4103),
        "faro": CLLocationCoordinate2D(latitude: 37.0194, longitude: -7.9322),
        "aveiro": CLLocationCoordinate2D(latitude: 40.6443, longitude: -8.6455),
        "setúbal": CLLocationCoordinate2D(latitude: 38.5244, longitude: -8.8882),
        "évora": CLLocationCoordinate2D(latitude: 38.5715, longitude: -7.9079),
        "guimarães": CLLocationCoordinate2D(latitude: 41.4416, longitude: -8.2918),
        "viseu": CLLocationCoordinate2D(latitude: 40.6566, longitude: -7.9122),
        "leiria": CLLocationCoordinate2D(latitude: 39.7437, longitude: -8.8071),
        "santarém": CLLocationCoordinate2D(latitude: 39.2369, longitude: -8.6867),
        "beja": CLLocationCoordinate2D(latitude: 38.0150, longitude: -7.8632),
        "castelo branco": CLLocationCoordinate2D(latitude: 39.8196, longitude: -7.4914),
        "portalegre": CLLocationCoordinate2D(latitude: 39.2968, longitude: -7.4281),
        "vila real": CLLocationCoordinate2D(latitude: 41.3006, longitude: -7.7442),
        "bragança": CLLocationCoordinate2D(latitude: 41.8060, longitude: -6.7570),
        "viana do castelo": CLLocationCoordinate2D(latitude: 41.6938, longitude: -8.8347),
        "funchal": CLLocationCoordinate2D(latitude: 32.6669, longitude: -16.9241),
        "ponta delgada": CLLocationCoordinate2D(latitude: 37.7412, longitude: -25.6756)
    ]
    
    return portugueseCities[city]
}

// MARK: - Card do Animal no Mapa
struct AnimalMapCard: View {
    let animal: Animal
    @Binding var showingDetail: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Imagem do animal
            if let imageURL = animal.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Informações
            VStack(alignment: .leading, spacing: 5) {
                Text(animal.pet_name ?? "Sem nome")
                    .font(.headline)
                
                HStack {
                    if let species = animal.species {
                        Label(species.capitalized, systemImage: "pawprint.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let age = animal.age {
                        Label(age, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let city = animal.addr_city {
                    Label(city, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button(action: { showingDetail = true }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 10)
    }
}

// MARK: - Instruções de Configuração
struct MapSetupInstructions: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Configuração do Mapa")
                    .font(.title)
                    .bold()
                
                Group {
                    Text("1. Info.plist")
                        .font(.headline)
                    
                    Text("Adiciona esta chave ao Info.plist:")
                        .foregroundColor(.secondary)
                    
                    Text("""
                    <key>NSLocationWhenInUseUsageDescription</key>
                    <string>Precisamos da tua localização para mostrar animais próximos.</string>
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                Group {
                    Text("2. Como Usar")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("Adiciona `AnimalMapView()` à tua navegação")
                        }
                        
                        HStack {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("Para iOS 17+, usa `AnimalMapViewModern()`")
                        }
                        
                        HStack {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            Text("Toca nos pins para ver detalhes")
                        }
                        
                        HStack {
                            Image(systemName: "4.circle.fill")
                                .foregroundColor(.blue)
                            Text("Usa os botões para navegar")
                        }
                    }
                }
                
                Divider()
                
                Group {
                    Text("3. Integração com TabView")
                        .font(.headline)
                    
                    Text("""
                    TabView {
                        AnimalListView()
                            .tabItem {
                                Label("Animais", systemImage: "list.bullet")
                            }
                        
                        AnimalMapView()
                            .tabItem {
                                Label("Mapa", systemImage: "map")
                            }
                        
                        FavoritesView()
                            .tabItem {
                                Label("Favoritos", systemImage: "heart.fill")
                            }
                    }
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                Group {
                    Text("4. Funcionalidades")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mostra todos os animais no mapa", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Filtra por localização (cidade)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Cores diferentes para cães e gatos", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Centrar na tua localização", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("Detalhes ao tocar no animal", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Setup do Mapa")
    }
}
