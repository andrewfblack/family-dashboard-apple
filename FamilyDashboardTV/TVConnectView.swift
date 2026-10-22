import DashboardCore
import DashboardUI
import SwiftUI

/// The pairing screen for Apple TV.
///
/// There is no keyboard on a television, so this screen never asks for one.
/// The device shows a code and waits for the user to approve it in Home
/// Assistant.
struct TVConnectView: View {
    @Environment(DashboardViewModel.self) private var model

    var body: some View {
        let theme = model.theme
        VStack(spacing: 32) {
            VStack(spacing: 10) {
                Text("Family Dashboard")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(theme.header)
                Text("Connect this Apple TV to your Home Assistant.")
                    .font(.title3)
                    .foregroundStyle(theme.muted)
            }

            if let pairingCode = model.pairingCode {
                VStack(spacing: 18) {
                    Text("Enter this code in Home Assistant, under Family Dashboard, then press Approve.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.muted)
                        .frame(maxWidth: 800)
                    Text(pairingCode)
                        .font(.system(size: 88, weight: .bold, design: .monospaced))
                        .tracking(12)
                        .foregroundStyle(theme.accentColor)
                    ProgressView()
                        .controlSize(.large)
                        .tint(theme.accentColor)
                }
            } else {
                VStack(spacing: 18) {
                    Text("Open the Family Dashboard panel in Home Assistant on your phone or tablet, then approve this Apple TV when it asks.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.muted)
                        .frame(maxWidth: 800)
                    Button {
                        Task { await model.requestPairing() }
                    } label: {
                        if model.isWaitingForApproval {
                            ProgressView().frame(width: 320)
                        } else {
                            Text("Show a code to approve")
                                .font(.title2.weight(.semibold))
                                .frame(width: 320)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accentColor)
                    .disabled(model.isWaitingForApproval)
                }
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
