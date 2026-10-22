import DashboardCore
import DashboardUI
import SwiftUI

/// The Family Dashboard app for iPhone and iPad.
@main
struct FamilyDashboardApp: App {
    @State private var model = DashboardViewModel(
        session: DashboardSession(credentialStore: KeychainCredentialStore()),
        platform: "ios"
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(\.dashboardTheme, model.theme)
                .task {
                    await model.start()
                }
        }
    }
}
