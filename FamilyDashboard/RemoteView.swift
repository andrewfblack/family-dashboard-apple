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
        VStack(alignment: .leading, spacing: 16) {
            if payload.remotes.isEmpty {
                DashboardCard("Remote", symbol: "av.remote.fill") {
                    Text("Select media players in the Family Dashboard integration in Home Assistant.")
                        .foregroundStyle(theme.muted)
                }
            } else {
                playerPicker
                if let player {
                    nowPlaying(player)
                    if !player.commands.isEmpty {
                        directionPad(player)
                    }
                    mediaControls(player)
                    extraControls(player)
                }
            }
        }
        .onAppear {
            if selectedPlayerID == nil {
                selectedPlayerID = payload.remotes.first?.entityID
            }
        }
    }

    private var playerPicker: some View {
        DashboardCard("Player", symbol: "tv") {
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
        }
    }

    private func nowPlaying(_ player: RemoteCard) -> some View {
        DashboardCard(player.name, symbol: symbol(for: player.kind)) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.mediaTitle ?? player.source ?? stateLabel(player.state))
                        .font(.title3.weight(.semibold))
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
                    Text(player.kind.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.itemHeader)
                    if let volume = player.volumeLevel {
                        Text("Volume \(Int((volume * 100).rounded()))%")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                Spacer()
                RemoteControlButton(symbol: "power", label: "Power", tint: theme.accentColor) {
                    run(.mediaPower(entityID: player.entityID))
                }
            }
        }
    }

    private func directionPad(_ player: RemoteCard) -> some View {
        DashboardCard("Navigation", symbol: "circle.grid.cross") {
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
    }

    private func mediaControls(_ player: RemoteCard) -> some View {
        DashboardCard("Playback and volume", symbol: "play.fill") {
            HStack(spacing: 12) {
                RemoteControlButton(symbol: "speaker.minus.fill", label: "Volume down") {
                    run(.mediaVolume(entityID: player.entityID, command: "down"))
                }
                RemoteControlButton(
                    symbol: player.isVolumeMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    label: "Mute"
                ) {
                    run(.mediaVolume(entityID: player.entityID, command: "mute"))
                }
                RemoteControlButton(symbol: "speaker.plus.fill", label: "Volume up") {
                    run(.mediaVolume(entityID: player.entityID, command: "up"))
                }
                RemoteControlButton(symbol: "playpause.fill", label: "Play or pause", tint: theme.accentColor) {
                    run(.mediaPlayPause(entityID: player.entityID))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func extraControls(_ player: RemoteCard) -> some View {
        let extras = player.commands.filter { ["back", "home", "menu", "replay", "info", "input"].contains($0) }
        if !extras.isEmpty || !player.sourceList.isEmpty {
            DashboardCard("More", symbol: "ellipsis.circle") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 12) {
                    ForEach(extras, id: \.self) { command in
                        commandButton(command, symbol: symbol(forCommand: command), player: player)
                    }
                    if !player.sourceList.isEmpty {
                        Menu {
                            ForEach(player.sourceList, id: \.self) { source in
                                Button(source) {
                                    run(.mediaSource(entityID: player.entityID, source: source))
                                }
                            }
                        } label: {
                            Label("Source", systemImage: "rectangle.connected.to.line.below")
                                .frame(minWidth: 72, minHeight: 52)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.itemHeader)
                    }
                }
            }
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
        case "input": return "rectangle.connected.to.line.below"
        default: return "circle"
        }
    }
}

private struct RemoteControlButton: View {
    @Environment(\.dashboardTheme) private var theme
    let symbol: String
    let label: String
    var tint: Color?
    let action: () -> Void

    init(symbol: String, label: String, tint: Color? = nil, action: @escaping () -> Void) {
        self.symbol = symbol
        self.label = label
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .frame(minWidth: 52, minHeight: 52)
        }
        .buttonStyle(.bordered)
        .tint(tint ?? theme.itemHeader)
        .accessibilityLabel(label)
    }
}
