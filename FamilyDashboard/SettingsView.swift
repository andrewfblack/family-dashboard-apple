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
