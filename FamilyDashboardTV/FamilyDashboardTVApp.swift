import DashboardCore
import DashboardUI
import SwiftUI

/// The Family Dashboard app for Apple TV.
@main
struct FamilyDashboardTVApp: App {
    @State private var model = DashboardViewModel(
        session: DashboardSession(credentialStore: KeychainCredentialStore()),
        platform: "tvos"
    )

    var body: some Scene {
        WindowGroup {
            TVRootView()
                .environment(model)
                .environment(\.dashboardTheme, model.theme)
                .task {
                    await model.start()
                }
        }
    }
}
