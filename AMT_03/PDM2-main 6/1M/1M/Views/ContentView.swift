//
//  ContentView.swift
//  1M
//
//

import SwiftUI
//usar o coredata com a interface
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        MainTabView()
            .environment(\.managedObjectContext, viewContext)
    }
}


