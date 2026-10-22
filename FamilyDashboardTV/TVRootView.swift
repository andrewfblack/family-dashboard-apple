import DashboardCore
import DashboardUI
import SwiftUI
import UIKit

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
                    backgroundImage(named: "FallBackground")
                case "winter":
                    backgroundImage(named: "WinterBackground")
                case "spring":
                    backgroundImage(named: "SpringBackground")
                case "summer":
                    backgroundImage(named: "SummerBackground")
                case "custom_url":
                    if let url = URL(string: payload.backgroundURL), !payload.backgroundURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case let .success(image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .empty:
                                Color.clear
                            case .failure:
                                backgroundImage(named: "FallBackground")
                            @unknown default:
                                backgroundImage(named: "FallBackground")
                            }
                        }
                    } else {
                        backgroundImage(named: "FallBackground")
                    }
                case "uploaded":
                    if let uploadedImage {
                        uploadedImage.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        backgroundImage(named: "FallBackground")
                    }
                default:
                    backgroundImage(named: "FallBackground")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
        .task(id: model.payload?.backgroundVersion ?? "") {
            await loadUploadedBackground()
        }
    }

    @ViewBuilder
    private func backgroundImage(named name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(Color.black.opacity(Double(model.theme.backgroundOverlay) / 100))
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
