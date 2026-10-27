import DashboardCore
import DashboardUI
import SwiftUI

/// iPhone and iPad controls for the media players selected in Home Assistant.
struct RemoteTab: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme
    @State private var selectedPlayerID: String?

    let payload: DashboardPayload

    private var player: RemoteCard? {
        payload.remotes.first(where: { $0.entityID == selectedPlayerID })
            ?? payload.remotes.first
    }

    var body: some View {
        if let player {
            DashboardCard("Remote", symbol: symbol(for: player.kind)) {
                VStack(alignment: .leading, spacing: 20) {
                    playerPicker
                    nowPlaying(player)
                    divider
                    powerAndSource(player)

                    if !player.commands.isEmpty {
                        sectionTitle("Navigation")
                        directionPad(player)

                        sectionTitle("Shortcuts")
                        shortcutControls(player)
                    }

                    sectionTitle("Volume")
                    volumeControls(player)

                    sectionTitle("Playback")
                    playbackControls(player)
                }
            }
            .onAppear {
                if selectedPlayerID == nil {
                    selectedPlayerID = payload.remotes.first?.entityID
                }
            }
        } else {
            DashboardCard("Remote", symbol: "av.remote.fill") {
                Text("Select media players in the Family Dashboard integration in Home Assistant.")
                    .foregroundStyle(theme.muted)
            }
        }
    }

    private var playerPicker: some View {
        Picker("Media player", selection: Binding(
            get: { selectedPlayerID ?? payload.remotes.first?.entityID ?? "" },
            set: { selectedPlayerID = $0 }
        )) {
            ForEach(payload.remotes) { player in
                Text(player.name).tag(player.entityID)
            }
        }
        .pickerStyle(.menu)
        .tint(theme.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nowPlaying(_ player: RemoteCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.itemHeader)
            Text(player.mediaTitle ?? player.source ?? stateLabel(player.state))
                .font(.headline)
                .foregroundStyle(theme.body)
            if let artist = player.mediaArtist, !artist.isEmpty {
                Text(artist)
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
            } else if player.mediaTitle != nil, let source = player.source {
                Text(source)
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
            }
            HStack(spacing: 10) {
                Text(player.kind.replacingOccurrences(of: "_", with: " ").uppercased())
                if let volume = player.volumeLevel {
                    Text("Volume \(Int((volume * 100).rounded()))%")
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(theme.muted)
        }
    }

    private func powerAndSource(_ player: RemoteCard) -> some View {
        HStack(spacing: 14) {
            LabeledRemoteButton(
                symbol: "power",
                label: "Power",
                tint: theme.accentColor
            ) {
                run(.mediaPower(entityID: player.entityID))
            }
            sourceControl(player)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func sourceControl(_ player: RemoteCard) -> some View {
        if !player.sourceList.isEmpty {
            Menu {
                ForEach(player.sourceList, id: \.self) { source in
                    Button(source) {
                        run(.mediaSource(entityID: player.entityID, source: source))
                    }
                }
            } label: {
                Label("Source", systemImage: "rectangle.connected.to.line.below")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)
            .tint(theme.itemHeader)
        } else if player.commands.contains("input") {
            LabeledRemoteButton(
                symbol: "rectangle.connected.to.line.below",
                label: "Source"
            ) {
                run(.remoteCommand(entityID: player.entityID, command: "input"))
            }
        } else {
            LabeledRemoteButton(
                symbol: "rectangle.connected.to.line.below",
                label: "Source",
                enabled: false,
                action: {}
            )
        }
    }

    private func directionPad(_ player: RemoteCard) -> some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Color.clear.frame(width: 68, height: 58)
                commandButton("up", symbol: "chevron.up", player: player)
                Color.clear.frame(width: 68, height: 58)
            }
            GridRow {
                commandButton("left", symbol: "chevron.left", player: player)
                commandButton("select", symbol: "circle.inset.filled", label: "Select", player: player)
                commandButton("right", symbol: "chevron.right", player: player)
            }
            GridRow {
                Color.clear.frame(width: 68, height: 58)
                commandButton("down", symbol: "chevron.down", player: player)
                Color.clear.frame(width: 68, height: 58)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func shortcutControls(_ player: RemoteCard) -> some View {
        let commands = ["back", "home", "menu", "replay", "info"]
            .filter { player.commands.contains($0) }
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 12) {
            ForEach(commands, id: \.self) { command in
                commandButton(command, symbol: symbol(forCommand: command), player: player)
            }
        }
    }

    private func volumeControls(_ player: RemoteCard) -> some View {
        HStack(spacing: 14) {
            LabeledRemoteButton(symbol: "speaker.minus.fill", label: "Down") {
                run(.mediaVolume(entityID: player.entityID, command: "down"))
            }
            LabeledRemoteButton(
                symbol: player.isVolumeMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: "Mute"
            ) {
                run(.mediaVolume(entityID: player.entityID, command: "mute"))
            }
            LabeledRemoteButton(symbol: "speaker.plus.fill", label: "Up") {
                run(.mediaVolume(entityID: player.entityID, command: "up"))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func playbackControls(_ player: RemoteCard) -> some View {
        HStack {
            Spacer()
            LabeledRemoteButton(
                symbol: "playpause.fill",
                label: "Play / Pause",
                tint: theme.accentColor
            ) {
                run(.mediaPlayPause(entityID: player.entityID))
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func commandButton(
        _ command: String,
        symbol: String,
        label: String? = nil,
        player: RemoteCard
    ) -> some View {
        if player.commands.contains(command) {
            RemoteControlButton(symbol: symbol, label: label ?? command.capitalized) {
                run(.remoteCommand(entityID: player.entityID, command: command))
            }
        } else {
            Color.clear.frame(width: 68, height: 58)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.itemBorderColor)
            .frame(height: 1)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.muted)
    }

    private func run(_ action: DashboardAction) {
        Task { await model.run(action) }
    }

    private func stateLabel(_ state: String) -> String {
        state.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func symbol(for kind: String) -> String {
        switch kind {
        case "apple_tv": return "appletv.fill"
        case "roku": return "play.tv.fill"
        case "lg": return "tv.fill"
        default: return "av.remote.fill"
        }
    }

    private func symbol(forCommand command: String) -> String {
        switch command {
        case "back": return "arrow.uturn.backward"
        case "home": return "house.fill"
        case "menu": return "list.bullet"
        case "replay": return "gobackward"
        case "info": return "info.circle"
        default: return "circle"
        }
    }
}

private struct RemoteControlButton: View {
    @Environment(\.dashboardTheme) private var theme
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .frame(minWidth: 52, minHeight: 52)
        }
        .buttonStyle(.bordered)
        .tint(theme.itemHeader)
        .accessibilityLabel(label)
    }
}

private struct LabeledRemoteButton: View {
    @Environment(\.dashboardTheme) private var theme
    let symbol: String
    let label: String
    var tint: Color? = nil
    var enabled = true
    let action: () -> Void

    init(
        symbol: String,
        label: String,
        tint: Color? = nil,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.label = label
        self.tint = tint
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.bordered)
        .tint(tint ?? theme.itemHeader)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
