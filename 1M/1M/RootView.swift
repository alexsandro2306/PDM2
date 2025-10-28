import SwiftUI

struct RootView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    RootView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
