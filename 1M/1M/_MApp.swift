import SwiftUI

@main
struct _1MApp: App {
    // Ccore data
    let persistenceController = PersistenceController.shared
    
    // tema
    @AppStorage("theme") private var theme: String = "System"
    
    init() {
        // configurar notificacao
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // pedir permissao notificacao
        NotificationManager.shared.requestAuthorization { granted in
            print("Notification permission: \(granted)")
        }
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext,
                            persistenceController.container.viewContext)
                .preferredColorScheme(colorScheme)
        }
    }
     
    
    
    private var colorScheme: ColorScheme? {
        switch theme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default:
            return nil
        }
    }
}
