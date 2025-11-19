//
//  MainTabView.swift
//  1M
//
//

import SwiftUI
struct MainTabView: View {
    var body: some View {
        TabView {
            
            NavigationStack {
                AnimalListView()
            }
            .tabItem {
                Label("Explore", systemImage: "magnifyingglass")
            }
            NavigationStack {
                FollowingView()
            }
            .tabItem {
                Label("Following", systemImage: "heart.fill")
            }
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
