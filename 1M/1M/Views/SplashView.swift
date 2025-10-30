//
//  SplashView.swift
//  1M
//
//  Splash screen de entrada da app
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.5
    
    var body: some View {
        if isActive {
            // transição para a view principal
            RootView()
        } else {
            // splash Screen
            ZStack {
                // Background color
                Color.white.ignoresSafeArea()
    

                
                VStack(spacing: 20) {
                    // imagem matchPet
                    Image("Image1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 1242, height: 200)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // titulos
                    Text("matchPet")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .opacity(logoOpacity)
                    
                    Text("Adoção de Animais")
                        .font(.title3)
                        .foregroundColor(.black.opacity(0.9))
                        .opacity(logoOpacity)
                }
            }
            .onAppear {
                // Animação do logo
                withAnimation(.easeInOut(duration: 1.2)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                // Carregar dados iniciais e transicionar
                performInitialSetup()
            }
        }
    }
    
    private func performInitialSetup() {
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isActive = true
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
