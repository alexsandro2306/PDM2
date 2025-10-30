//
//  SettingsView.swift
//  1M
//
//  Created by user255085 on 10/16/25.
//
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("theme") private var theme: String = "Sistema"
    @AppStorage("animalsPerPage") private var animalsPerPage: Int = 20
    @AppStorage("notificationHour") private var notificationHour: Int = 9
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @AppStorage("cacheTTLHours") private var cacheTTLHours: Int = 24
    
    var body: some View {
        Form {
            // aparência
            Section("Aparência") {
                Picker("Tema", selection: $theme) {
                    Text("Sistema").tag("Sistema")
                    Text("Claro").tag("Claro")
                    Text("Escuro").tag("Escuro")
                }
                .pickerStyle(.segmented)
            }
            
            // dados
            Section("Dados") {
                Stepper("Animais por página: \(animalsPerPage)", value: $animalsPerPage, in: 5...100, step: 5)
                Stepper("Cache (horas): \(cacheTTLHours)", value: $cacheTTLHours, in: 1...168)
            }
            
            // notificações
            Section("Notificações") {
                // Hora
                Picker("Hora da notificação diária", selection: $notificationHour) {
                    ForEach(0..<24) { h in
                        Text(String(format: "%02d:00", h)).tag(h)
                    }
                }
                .onChange(of: notificationHour) { _ in
                    scheduleNotification()
                }
                
                // Minuto
                Picker("Minuto", selection: $notificationMinute) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .onChange(of: notificationMinute) { _ in
                    scheduleNotification()
                }
                
                // mostrar hora configurada
                HStack {
                    Text("Hora configurada:")
                    Spacer()
                    Text(String(format: "%02d:%02d", notificationHour, notificationMinute))
                        .foregroundColor(.secondary)
                }
                
                Button("Agendar Notificação Diária") {
                    scheduleNotification()
                }
 
            }
        }
        
        .navigationTitle("Definições")
    }
    
    // funcao para agendar com hora e minuto
    private func scheduleNotification() {
        NotificationManager.shared.scheduleDailyRandomAnimalNotification(
            hour: notificationHour,
            minute: notificationMinute
        )
    }
}
