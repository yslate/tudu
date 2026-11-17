import SwiftUI

enum AppStyle: String, CaseIterable, Identifiable {
    case system
    case white
    case black
    case warmWhite
    case warmBlack

    var id: Self { self }

    var title: String {
        switch self {
        case .system: return "System"
        case .white: return "White"
        case .black: return "Black"
        case .warmWhite: return "Warm White"
        case .warmBlack: return "Warm Black"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .white, .warmWhite: return .light
        case .black, .warmBlack: return .dark
        }
    }

    func tint(_ scheme: ColorScheme) -> NSColor {
        switch self {
        case .system: return scheme == .dark ? .black : .white
        case .white: return .white
        case .black: return .black
        case .warmWhite: return NSColor(srgbRed: 0.98, green: 0.95, blue: 0.89, alpha: 1)
        case .warmBlack: return NSColor(srgbRed: 0.12, green: 0.10, blue: 0.08, alpha: 1)
        }
    }
}

// NSVisualEffectView can't set a blur radius, the window server can. Private API,
// fine outside the App Store (iTerm2 uses the same call).
@_silgen_name("CGSDefaultConnectionForThread")
private func CGSDefaultConnectionForThread() -> Int32
@_silgen_name("CGSSetWindowBackgroundBlurRadius")
private func CGSSetWindowBackgroundBlurRadius(_ cid: Int32, _ wid: UInt32, _ radius: Int32) -> Int32

/// Turns the hosting window into tinted glass and keeps it in sync with the settings.
struct GlassWindow: NSViewRepresentable {
    var tint: NSColor
    var opacity: Double
    var blur: Double
    var pinned: Bool

    final class Probe: NSView {
        var configure: (NSWindow) -> Void = { _ in }
        override func viewDidMoveToWindow() {
            if let window { configure(window) }
        }
    }

    func makeNSView(context: Context) -> Probe { Probe() }

    func updateNSView(_ probe: Probe, context: Context) {
        probe.configure = { window in
            window.isOpaque = false
            window.backgroundColor = tint.withAlphaComponent(opacity)
            window.level = pinned ? .floating : .normal
            _ = CGSSetWindowBackgroundBlurRadius(CGSDefaultConnectionForThread(), UInt32(window.windowNumber), Int32(blur))
        }
        if let window = probe.window { probe.configure(window) }
    }
}
