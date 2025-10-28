//
//  NotificationManager.swift
//  1M
//
//  Created by user255085 on 10/16/25.
//
import Foundation
import UserNotifications
import CoreData

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        // defenir como delegado
        UNUserNotificationCenter.current().delegate = self
    }
    
    // pedir permissao
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Erro ao pedir permissão: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    // agendar notificacao
    func scheduleDailyRandomAnimalNotification(hour: Int, minute: Int = 0) {
        // Remove agendamento anterior (mesmo identificador)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyAnimal"])
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = "Animal do Dia 🐾"
        content.body = "Descobre um novo amigo para adoção hoje!"
        content.sound = .default
        content.userInfo = ["type": "randomAnimal"]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyAnimal", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação diária: \(error.localizedDescription)")
            } else {
                print("Notificação diária agendada para as \(String(format: "%02d:%02d", hour, minute))")
            }
        }
    }
    
    // notificação para teste
    func scheduleImmediateRandomAnimalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Animal Aleatório"
        content.body = "Toca para conhecer o animal sugerido!"
        content.sound = .default
        content.userInfo = ["type": "randomAnimal"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação: \(error.localizedDescription)")
            } else {
                print("Notificação aleatória agendada com sucesso!")
            }
        }
    }
    
    // mostrar mesmo com app aberto
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
