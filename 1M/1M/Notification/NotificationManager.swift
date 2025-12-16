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
                print("Error requesting permission: \(error.localizedDescription)")
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
        content.title = "Animal of the Day 🐾"
        content.body = "Find a new friend to adopt today!"
        content.sound = .default
        content.userInfo = ["type": "randomAnimal"]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyAnimal", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error.localizedDescription)")
            } else {
                print("Daily notification scheduled for \(String(format: "%02d:%02d", hour, minute))")
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
