

import UserNotifications
import UIKit
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        // Verificar userInfo["type"] e payload, e navegar para detalhe.
        // A navegação depende do seu router / environment.
    }
    // Foreground presentation
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async ->
    UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}

