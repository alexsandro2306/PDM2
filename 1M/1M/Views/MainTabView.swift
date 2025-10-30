//
//  MainTabView.swift
//  1M
//
//  Created by user255085 on 10/16/25.
//

import SwiftUI
struct MainTabView: View {
    var body: some View {
        TabView {
            
            NavigationStack {
                AnimalListView()
            }
            .tabItem {
                Label("Explorar", systemImage: "magnifyingglass")
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
