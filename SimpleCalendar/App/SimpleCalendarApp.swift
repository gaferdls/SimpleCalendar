import SwiftUI

@main
struct SimpleCalendarApp: App {
    
    @StateObject private var viewModel: AppViewModel

    init() {
        let persistenceManager = PersistenceManager.shared
        _viewModel = StateObject(wrappedValue: AppViewModel(persistenceManager: persistenceManager))
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(viewModel)
                .modelContainer(for: Task.self)
        }
    }
}
