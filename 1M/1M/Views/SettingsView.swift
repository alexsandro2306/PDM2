//
//  SettingsView.swift
//  1M
//
//  Created by user255085 on 10/16/25.
//
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("theme") private var theme: String = "System"
    @AppStorage("notificationHour") private var notificationHour: Int = 9
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @AppStorage("cacheTTLHours") private var cacheTTLHours: Int = 24
    
    var body: some View {
        Form {
            // aparência
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
                .pickerStyle(.segmented)
            }
            
            // dados  nao funcional ainda
            Section("Data") {
                
                Stepper("Cache (horas): \(cacheTTLHours)", value: $cacheTTLHours, in: 1...168)
            }
            
            // notificações
            Section("Notifications") {
                // hora
                Picker("Daily notification time", selection: $notificationHour) {
                    ForEach(0..<24) { h in
                        Text(String(format: "%02d:00", h)).tag(h)
                    }
                }
                .onChange(of: notificationHour) { _ in
                    scheduleNotification()
                }
                
                // minuto
                Picker("Minute", selection: $notificationMinute) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .onChange(of: notificationMinute) { _ in
                    scheduleNotification()
                }
                
                // mostrar hora configurada
                HStack {
                    Text("Set time:")
                    Spacer()
                    Text(String(format: "%02d:%02d", notificationHour, notificationMinute))
                        .foregroundColor(.secondary)
                }
                
                Button("Schedule Daily Notification") {
                    scheduleNotification()
                }
 
            }
        }
        
        .navigationTitle("Settings")
    }
    
    // funcao para agendar com hora e minuto
    private func scheduleNotification() {
        NotificationManager.shared.scheduleDailyRandomAnimalNotification(
            hour: notificationHour,
            minute: notificationMinute
        )
    }
}
