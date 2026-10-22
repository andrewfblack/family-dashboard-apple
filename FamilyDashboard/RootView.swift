import DashboardCore
import DashboardUI
import SwiftUI

/// The screen the app shows first: pairing, or the dashboard.
struct RootView: View {
    @Environment(DashboardViewModel.self) private var model

    var body: some View {
        ZStack {
            BackgroundView()
                .zIndex(0)
            Group {
                if model.isPaired, model.payload != nil {
                    DashboardShell()
                } else {
                    ConnectView()
                }
            }
            .zIndex(1)
        }
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
struct BackgroundView: View {
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
                case "custom_url":
                    if let url = URL(string: payload.backgroundURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case let .success(image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .failure:
                                EmptyView()
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                default:
                    EmptyView()
                }
            }
        }
        .opacity(0.9)
        .ignoresSafeArea()
    }
}
