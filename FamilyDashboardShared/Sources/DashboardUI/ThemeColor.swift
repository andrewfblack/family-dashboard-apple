#if canImport(SwiftUI)
import SwiftUI

extension Color {
    /// Build a colour from a `#RRGGBB` string.
    ///
    /// The server sends every colour ready to use, so nothing has to be
    /// converted by hand.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
        switch cleaned.count {
        case 3:
            red = Double((value >> 8) & 0xF) / 15
            green = Double((value >> 4) & 0xF) / 15
            blue = Double(value & 0xF) / 15
            alpha = 1
        case 8:
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        default:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        }
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Theme {
    /// The colour of the screen title.
    public var header: Color { Color(hex: headerText) }
    /// The colour of a card heading.
    public var itemHeader: Color { Color(hex: itemHeaderText) }
    /// The colour of body text.
    public var body: Color { Color(hex: bodyText) }
    /// The colour of secondary text.
    public var muted: Color { Color(hex: mutedText) }
    /// The accent colour.
    public var accentColor: Color { Color(hex: accent) }
    /// The colour behind a card.
    public var itemBackgroundColor: Color { Color(hex: itemBackground).opacity(Double(itemOpacity) / 100) }
    /// The colour behind a selected card.
    public var selectedBackgroundColor: Color { Color(hex: selectedBackground) }
    /// The colour of a selected card's border.
    public var selectedBorderColor: Color { Color(hex: selectedBorder) }
    /// The colour of a card's border.
    public var itemBorderColor: Color { Color(hex: itemBorder) }
    /// The fallback background colour.
    public var backgroundColor: Color { Color(hex: background) }
}
#endif
