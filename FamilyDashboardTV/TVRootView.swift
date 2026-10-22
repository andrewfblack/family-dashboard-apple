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
                    backgroundImage(named: "FallBackground")
                case "winter":
                    backgroundImage(named: "WinterBackground")
                case "spring":
                    backgroundImage(named: "SpringBackground")
                case "summer":
                    backgroundImage(named: "SummerBackground")
                default:
                    EmptyView()
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func backgroundImage(named name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(Color.black.opacity(0.16))
    }
}
