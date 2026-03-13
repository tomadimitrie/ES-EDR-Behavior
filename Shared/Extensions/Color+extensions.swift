import SwiftUI
import AppKit

public extension Color {
    func tune(hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, opacity: CGFloat = 1) -> Color {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB)!
        return Color(
            hue: nsColor.hueComponent + hue,
            saturation: nsColor.saturationComponent + saturation,
            brightness: nsColor.brightnessComponent + brightness,
            opacity: opacity
        )
    }
}
