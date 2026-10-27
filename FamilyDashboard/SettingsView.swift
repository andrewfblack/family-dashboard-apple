import DashboardCore
import DashboardUI
import SwiftUI

/// The settings of this app.
struct SettingsView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var address = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Home Assistant") {
                    TextField("Address", text: $address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button("Change address") {
                        Task {
                            await model.setServer(address)
                            dismiss()
                        }
                    }
                    .disabled(address == model.serverAddress)
                }

                Section("This device") {
                    LabeledContent("Name", value: model.deviceName)
                    LabeledContent("Platform", value: model.platform)
                    LabeledContent("Address", value: model.serverAddress)
                }

                if model.platform == "ios", model.payload != nil {
                    Section("Personalize") {
                        NavigationLink("Reorder dashboard tabs") {
                            TabOrderSettingsView()
                        }
                        if !(model.payload?.remotes.isEmpty ?? true) {
                            NavigationLink("Reorder remote players") {
                                RemoteOrderSettingsView()
                            }
                        }
                    } footer: {
                        Text("Ordering is saved on this device and does not change other dashboard clients.")
                    }
                }

                Section {
                    Button("Unpair this device", role: .destructive) {
                        Task {
                            await model.unpair()
                            dismiss()
                        }
                    }
                } footer: {
                    Text("Unpairing removes the credential from this device. The device has to approve itself again before it can read the dashboard.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                address = model.serverAddress
            }
        }
    }
}

private struct TabOrderSettingsView: View {
    @Environment(DashboardViewModel.self) private var model
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            ForEach(model.tabs) { tab in
                Label(tab.title, systemImage: tab.symbol)
            }
            .onMove { indices, destination in
                var tabs = model.tabs
                tabs.move(fromOffsets: indices, toOffset: destination)
                model.setTabOrder(tabs)
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("Dashboard Tabs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
    }
}

private struct RemoteOrderSettingsView: View {
    @Environment(DashboardViewModel.self) private var model
    @State private var editMode: EditMode = .inactive

    private var remotes: [RemoteCard] {
        model.payload.map { model.orderedRemotes($0.remotes) } ?? []
    }

    var body: some View {
        List {
            ForEach(remotes) { remote in
                HStack {
                    Image(systemName: icon(for: remote.kind))
                        .foregroundStyle(.secondary)
                    Text(remote.name)
                }
            }
            .onMove { indices, destination in
                var ordered = remotes
                ordered.move(fromOffsets: indices, toOffset: destination)
                model.setRemoteOrder(ordered)
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("Remote Players")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
    }

    private func icon(for kind: String) -> String {
        switch kind {
        case "apple_tv": return "appletv.fill"
        case "roku": return "play.tv.fill"
        case "lg": return "tv.fill"
        default: return "av.remote.fill"
        }
    }
}
