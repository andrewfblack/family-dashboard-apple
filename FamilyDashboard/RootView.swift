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
        theme.backgroundColor
            .overlay {
                if let payload {
                    switch payload.background {
                    case "fall":
                        filledBackground(Image("FallBackground"))
                    case "winter":
                        filledBackground(Image("WinterBackground"))
                    case "spring":
                        filledBackground(Image("SpringBackground"))
                    case "summer":
                        filledBackground(Image("SummerBackground"))
                    case "custom_url":
                        if let url = URL(string: payload.backgroundURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case let .success(image):
                                    filledBackground(image)
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
                            filledBackground(uploadedImage)
                        } else {
                            filledBackground(Image("FallBackground"))
                        }
                    default:
                        filledBackground(Image("FallBackground"))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
            .opacity(0.9)
            .task(id: model.payload?.backgroundVersion ?? "") {
                await loadUploadedBackground()
            }
    }

    /// Draw a photo so it covers the screen without becoming the layout size.
    ///
    /// A resizable fill image reports its pixel size. Inside a stack that size
    /// pushes the cards off a portrait phone. An overlay keeps the photo visual
    /// only.
    private func filledBackground(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
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
