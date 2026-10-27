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
            remoteCard(player)
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

    private func remoteCard(_ player: RemoteCard) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                playerSwitcher(player)
                Spacer(minLength: 8)
                Text(deviceType(player.kind))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.muted)
            }

            nowPlaying(player)
            divider
            powerAndSource(player)

            if !player.commands.isEmpty {
                directionPad(player)
                shortcutControls(player)
            }

            volumeControls(player)
            playbackControls(player)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.itemBackgroundColor, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.itemBorderColor, lineWidth: 1)
        )
    }

    private func playerSwitcher(_ player: RemoteCard) -> some View {
        Menu {
            ForEach(payload.remotes) { option in
                Button {
                    selectedPlayerID = option.entityID
                } label: {
                    if option.entityID == player.entityID {
                        Label(option.name, systemImage: "checkmark")
                    } else {
                        Text(option.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(player.name)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(theme.itemHeader)
        }
        .accessibilityLabel("Media player, \(player.name)")
    }

    private func nowPlaying(_ player: RemoteCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
            if let volume = player.volumeLevel {
                Text("Volume \(Int((volume * 100).rounded()))%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.muted)
            }
        }
    }

    private func powerAndSource(_ player: RemoteCard) -> some View {
        HStack(spacing: 14) {
            RemoteControlButton(
                symbol: "power",
                label: "Power",
                expands: true
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
                remoteButtonFace(
                    symbol: "rectangle.connected.to.line.below",
                    expands: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Source")
        } else if player.commands.contains("input") {
            RemoteControlButton(
                symbol: "rectangle.connected.to.line.below",
                label: "Source",
                expands: true
            ) {
                run(.remoteCommand(entityID: player.entityID, command: "input"))
            }
        } else {
            RemoteControlButton(
                symbol: "rectangle.connected.to.line.below",
                label: "Source",
                expands: true,
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
        let commands = ["back", "home", "menu", "replay", "options"]
            .filter { player.commands.contains($0) }
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 12) {
            ForEach(commands, id: \.self) { command in
                commandButton(command, symbol: symbol(forCommand: command), player: player)
            }
        }
    }

    private func volumeControls(_ player: RemoteCard) -> some View {
        HStack(spacing: 14) {
            RemoteControlButton(symbol: "speaker.minus.fill", label: "Volume down", expands: true) {
                run(.mediaVolume(entityID: player.entityID, command: "down"))
            }
            RemoteControlButton(
                symbol: player.isVolumeMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: "Mute",
                expands: true
            ) {
                run(.mediaVolume(entityID: player.entityID, command: "mute"))
            }
            RemoteControlButton(symbol: "speaker.plus.fill", label: "Volume up", expands: true) {
                run(.mediaVolume(entityID: player.entityID, command: "up"))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func playbackControls(_ player: RemoteCard) -> some View {
        HStack(spacing: 14) {
            RemoteControlButton(
                symbol: "backward.fill",
                label: "Rewind",
                expands: true,
                enabled: player.commands.contains("reverse")
            ) {
                run(.remoteCommand(entityID: player.entityID, command: "reverse"))
            }
            RemoteControlButton(
                symbol: "playpause.fill",
                label: "Play / Pause",
                expands: true
            ) {
                run(.mediaPlayPause(entityID: player.entityID))
            }
            RemoteControlButton(
                symbol: "forward.fill",
                label: "Fast forward",
                expands: true,
                enabled: player.commands.contains("forward")
            ) {
                run(.remoteCommand(entityID: player.entityID, command: "forward"))
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

    private var divider: some View {
        Rectangle()
            .fill(theme.itemBorderColor)
            .frame(height: 1)
    }

    private func remoteButtonFace(symbol: String, expands: Bool = false) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.semibold))
            .foregroundStyle(theme.remoteButtonTextColor)
            .frame(maxWidth: expands ? .infinity : 68, minHeight: 56)
            .background(
                theme.remoteButtonBackgroundColor,
                in: RoundedRectangle(cornerRadius: 12)
            )
    }

    private func run(_ action: DashboardAction) {
        Task { await model.run(action) }
    }

    private func stateLabel(_ state: String) -> String {
        state.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func deviceType(_ kind: String) -> String {
        switch kind {
        case "apple_tv": return "APPLE TV"
        case "roku": return "ROKU"
        case "lg": return "LG TV"
        default: return "MEDIA PLAYER"
        }
    }

    private func symbol(forCommand command: String) -> String {
        switch command {
        case "back": return "arrow.uturn.backward"
        case "home": return "house.fill"
        case "menu": return "list.bullet"
        case "replay": return "gobackward"
        case "options": return "asterisk"
        default: return "circle"
        }
    }
}

private struct RemoteControlButton: View {
    @Environment(\.dashboardTheme) private var theme
    let symbol: String
    let label: String
    var expands = false
    var enabled = true
    let action: () -> Void

    init(
        symbol: String,
        label: String,
        expands: Bool = false,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.label = label
        self.expands = expands
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.remoteButtonTextColor)
                .frame(maxWidth: expands ? .infinity : 68, minHeight: 56)
                .background(
                    theme.remoteButtonBackgroundColor,
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .accessibilityLabel(label)
    }
}
