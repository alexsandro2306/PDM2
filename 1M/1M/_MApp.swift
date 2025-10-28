import SwiftUI

@main
struct _1MApp: App {
    // Ccore data
    let persistenceController = PersistenceController.shared
    
    // tema
    @AppStorage("theme") private var theme: String = "Sistema"
    
    init() {
        // configurar notificacao
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // pedir permissao notificacao
        NotificationManager.shared.requestAuthorization { granted in
            print("Permissão de notificações: \(granted)")
        }
    }
    var body: some Scene {
         WindowGroup {
             SplashView()
                 .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
                 .preferredColorScheme(colorScheme)
         }
     }
     
    
    
    private var colorScheme: ColorScheme? {
        switch theme {
        case "Claro":
            return .light
        case "Escuro":
            return .dark
        default:
            return nil
        }
    }
}
