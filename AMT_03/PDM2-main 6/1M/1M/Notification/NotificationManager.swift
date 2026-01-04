import Foundation
import UserNotifications
import CoreData

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // pedir permissao
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting permission: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    // agendar notificacao com animal aleatorio
    func scheduleDailyRandomAnimalNotification(hour: Int, minute: Int = 0) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyAnimal"])
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Buscar animal aleatório
        if let randomAnimal = getRandomAnimal() {
            let content = UNMutableNotificationContent()
            content.title = "Meet \(randomAnimal.pet_name ?? "a new friend")! 🐾"
            content.body = "\(randomAnimal.species?.capitalized ?? "Animal") • \(randomAnimal.age?.capitalized ?? "Unknown age") • \(randomAnimal.addr_city ?? "Unknown location")"
            content.sound = .default
            
            // passar o ID do animal 
            content.userInfo = [
                "type": "randomAnimal",
                "animalId": randomAnimal.pet_id ?? "",
                "animalName": randomAnimal.pet_name ?? "Unknown"
            ]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "dailyAnimal", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling daily notification: \(error.localizedDescription)")
                } else {
                    print("Daily notification scheduled for \(String(format: "%02d:%02d", hour, minute)) with animal: \(randomAnimal.pet_name ?? "Unknown")")
                }
            }
        }
    }
    
    // buscar animal aleatório ao coredata
    private func getRandomAnimal() -> Animal? {
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<Animal> = Animal.fetchRequest()
        
        do {
            let animals = try context.fetch(fetchRequest)
            return animals.randomElement()
        } catch {
            print("Error fetching random animal: \(error.localizedDescription)")
            return nil
        }
    }
    
    // mostrar mesmo com app aberto
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // quando user toca na notificação
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let animalId = userInfo["animalId"] as? String {
            // postar notificação para abrir o animal
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenAnimalDetail"),
                object: nil,
                userInfo: ["animalId": animalId]
            )
        }
        
        completionHandler()
    }
}
