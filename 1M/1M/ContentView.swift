//
//  ContentView.swift
//  1M
//
//  Created by user255085 on 10/16/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        MainTabView()
            .environment(\.managedObjectContext, viewContext)
    }
}


