//
//  MainTabView.swift
//  1M
//
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab para CÃES 🐕
            NavigationStack {
                AnimalListView(species: "dog")
            }
            .tabItem {
                Label("Dogs", systemImage: "dog.fill")
            }
            
            // Tab para GATOS 🐈
            NavigationStack {
                AnimalListView(species: "cat")
            }
            .tabItem {
                Label("Cats", systemImage: "cat.fill")
            }
            
            // Tab para Following
            NavigationStack {
                FollowingView()
            }
            .tabItem {
                Label("Following", systemImage: "heart.fill")
            }
            
            // Tab para Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
