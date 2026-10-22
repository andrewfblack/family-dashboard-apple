import DashboardCore
import DashboardUI
import SwiftUI

/// The screen the Apple TV shows first: pairing, or the dashboard.
struct TVRootView: View {
    @Environment(DashboardViewModel.self) private var model

    var body: some View {
        Group {
            if model.isPaired, model.payload != nil {
                TVDashboardView()
            } else {
                TVConnectView()
            }
        }
        .background(TVBackgroundView())
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.clearError() } }
            ),
            actions: {
                Button("OK", role: .cancel) { model.clearError() }
            },
            message: {
                Text(model.errorMessage ?? "")
            }
        )
    }
}

/// The background the administrator chose.
struct TVBackgroundView: View {
    @Environment(DashboardViewModel.self) private var model

    var body: some View {
        let payload = model.payload
        let theme = model.theme
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
            if let payload {
                switch payload.background {
                case "fall":
                    Image("FallBackground").resizable().aspectRatio(contentMode: .fill)
                case "winter":
                    Image("WinterBackground").resizable().aspectRatio(contentMode: .fill)
                case "spring":
                    Image("SpringBackground").resizable().aspectRatio(contentMode: .fill)
                case "summer":
                    Image("SummerBackground").resizable().aspectRatio(contentMode: .fill)
                default:
                    EmptyView()
                }
            }
        }
        .opacity(0.85)
        .ignoresSafeArea()
    }
}
