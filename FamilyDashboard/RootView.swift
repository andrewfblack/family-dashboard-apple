import DashboardCore
import DashboardUI
import SwiftUI
import UIKit

/// The screen the app shows first: pairing, or the dashboard.
struct RootView: View {
    @Environment(DashboardViewModel.self) private var model

    var body: some View {
        Group {
            if model.isPaired {
                DashboardShell()
            } else {
                ConnectView()
            }
        }
        .background(BackgroundView())
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
    @State private var uploadedImage: Image?

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
                case "uploaded":
                    if let uploadedImage {
                        uploadedImage.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Image("FallBackground").resizable().aspectRatio(contentMode: .fill)
                    }
                default:
                    Image("FallBackground").resizable().aspectRatio(contentMode: .fill)
                }
            }
        }
        .opacity(0.9)
        .ignoresSafeArea()
        .task(id: model.payload?.backgroundVersion ?? "") {
            await loadUploadedBackground()
        }
    }

    private func loadUploadedBackground() async {
        guard let payload = model.payload,
              payload.background == "uploaded",
              payload.hasUploadedBackground,
              let request = await model.backgroundRequest(),
              let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data)
        else {
            uploadedImage = nil
            return
        }
        uploadedImage = Image(uiImage: image)
    }
}
