import DashboardCore
import DashboardUI
import SwiftUI

/// The screen that pairs this device with Home Assistant.
struct ConnectView: View {
    @Environment(DashboardViewModel.self) private var model

    @State private var code = ""
    @State private var address = ""
    @State private var isSearching = false
    @FocusState private var codeFocused: Bool

    var body: some View {
        let theme = model.theme
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Family Dashboard")
                        .font(.largeTitle.bold())
                        .foregroundStyle(theme.header)
                    Text("Connect this device to your Home Assistant.")
                        .font(.subheadline)
                        .foregroundStyle(theme.muted)
                }

                if let pairingCode = model.pairingCode {
                    DashboardCard("Approve this device", symbol: "link") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter this code in Home Assistant, under Family Dashboard, then press Approve.")
                                .font(.subheadline)
                                .foregroundStyle(theme.muted)
                            Text(pairingCode)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .tracking(6)
                                .foregroundStyle(theme.accentColor)
                            ProgressView()
                                .tint(theme.accentColor)
                        }
                    }
                } else {
                    DashboardCard("Pair this device", symbol: "link") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Home Assistant shows a code for you to approve. Press the button below and the code appears here.")
                                .font(.subheadline)
                                .foregroundStyle(theme.muted)
                            Button {
                                Task { await model.requestPairing() }
                            } label: {
                                if model.isWaitingForApproval {
                                    ProgressView().frame(maxWidth: .infinity)
                                } else {
                                    Text("Show a code to approve").frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.accentColor)
                            .disabled(model.isWaitingForApproval)
                        }
                    }

                    DashboardCard("Or enter the pairing code", symbol: "number") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Pairing code", text: $code)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($codeFocused)
                                .font(.system(.title3, design: .monospaced))
                                .padding(12)
                                .background(theme.itemBorderColor.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                            Button {
                                Task { await model.pair(with: code) }
                            } label: {
                                Text("Pair").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.accentColor)
                            .disabled(code.count < 4 || model.isWaitingForApproval)
                        }
                    }
                }

                DashboardCard("Home Assistant address", symbol: "server.rack") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            isSearching = true
                            model.startDiscovery()
                        } label: {
                            Label("Find Home Assistant on this network", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.accentColor)

                        if isSearching && model.discoveredServers.isEmpty {
                            ProgressView("Searching…")
                                .font(.caption)
                        }

                        ForEach(model.discoveredServers) { server in
                            Button {
                                address = server.address
                                Task { await model.useServer(server) }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(server.name)
                                        .font(.headline)
                                    Text(server.address)
                                        .font(.caption)
                                        .foregroundStyle(theme.muted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .tint(theme.accentColor)
                        }

                        TextField("http://homeassistant.local:8123", text: $address)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(12)
                            .background(theme.itemBorderColor.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                        Button {
                            Task { await model.setServer(address) }
                        } label: {
                            Text("Use this address").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.accentColor)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            address = model.serverAddress
        }
        .onDisappear {
            model.stopDiscovery()
        }
    }
}
