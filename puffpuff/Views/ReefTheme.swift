import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }

    // Resolve with the view's appearance, including Canvas and presented sheets.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: Double((hex >> 16) & 255) / 255,
                           green: Double((hex >> 8) & 255) / 255,
                           blue: Double(hex & 255) / 255, alpha: 1)
        }))
        #else
        return Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: Double((hex >> 16) & 255) / 255,
                           green: Double((hex >> 8) & 255) / 255,
                           blue: Double(hex & 255) / 255, alpha: 1)
        })
        #endif
    }

}

enum ReefTheme {
    static let abyss = Color(hex: 0x031C24)
    static let deep = Color.adaptive(light: 0x79B9AC, dark: 0x0B343B)
    static let ink = Color.adaptive(light: 0x143F42, dark: 0xE5F2EA)
    static let muted = Color.adaptive(light: 0x376963, dark: 0xA3C0BC)
    static let cyan = Color.adaptive(light: 0x226E68, dark: 0x7DD9CD)
    static let green = cyan
    static let gold = Color.adaptive(light: 0x80501F, dark: 0xF3C68B)
    // Hint light is luminous gold; the darker gold above remains readable text.
    static let hintGold = Color(hex: 0xFFD23F)
    static let hintCore = Color(hex: 0xFFF6BD)
    static let bone = Color.adaptive(light: 0x6F9990, dark: 0x527A79)
    static let glass = Color.adaptive(light: 0xC9E8D8, dark: 0x123D44)
    static let glint = Color.adaptive(light: 0xF4FFE9, dark: 0x93E6D8)
    static let sand = Color.adaptive(light: 0xEDDFB0, dark: 0x0A2930)
    static let honey = Color(hex: 0xF2BA76)
    static let coral = Color(hex: 0xF49B87)
    static let rose = Color(hex: 0xEB8196)
    static let bloom = Color(hex: 0xFFD6A0)
    static let sleepyCoral = Color.adaptive(light: 0x77978E, dark: 0x3C5C63)
    static let sleepyTip = Color.adaptive(light: 0x779A99, dark: 0x6C9390)
}

enum ReefControlKind { case action, quiet, orb, coral, navigation }

struct ReefPauseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "pause.fill").frame(width: 44, height: 44)
        }.buttonStyle(ReefButtonStyle(kind: .navigation)).accessibilityLabel("Pause game")
    }
}

struct ReefButtonStyle: ButtonStyle {
    var filled = false
    var kind: ReefControlKind = .action
    func makeBody(configuration: Configuration) -> some View {
        LiquidControlBody(label: configuration.label, pressed: configuration.isPressed, filled: filled, kind: kind)
    }
}

private struct LiquidControlBody<Label: View>: View {
    let label: Label
    let pressed: Bool
    let filled: Bool
    let kind: ReefControlKind
    @State private var hovered = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.oceanTime) private var time
    private var active: Bool { enabled && (hovered || pressed) }
    private var tint: Color { filled ? ReefTheme.honey : ReefTheme.cyan }

    var body: some View {
        label
            .reefFont(.subheadline, weight: .semibold)
            .padding(.horizontal, kind == .action ? 24 : kind == .quiet ? 9 : 0)
            .padding(.vertical, kind == .action ? 14 : kind == .quiet ? 8 : 0)
            .frame(minWidth: 44, minHeight: 44)
            .foregroundStyle(enabled ? ReefTheme.ink : ReefTheme.muted.opacity(0.5))
            .background {
                if kind == .action || kind == .orb {
                    MembraneSurface(tint: tint, intensity: filled ? 1.25 : 0.7, round: true, interaction: active && !reduceMotion ? 1 : 0)
                }
            }
            .overlay {
                if active && kind != .coral {
                    // A refracted bubble crescent slides over the surface, not over the text.
                    SeaGlassShape(phase: reduceMotion ? 0 : time / 4000, amplitude: reduceMotion ? 0.02 : 0.045)
                        .trim(from: 0.03, to: 0.40)
                        .stroke(tint.opacity(0.6), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                        .padding(2).allowsHitTesting(false)
                }
            }
            .shadow(color: tint.opacity(active ? 0.22 : 0), radius: 12)
            .scaleEffect(x: reduceMotion ? 1 : pressed ? 0.975 : hovered ? 1.008 : 1,
                         y: reduceMotion ? 1 : pressed ? 1.015 : hovered ? 0.996 : 1)
            .contentShape(Rectangle())
            .onHover { hovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: active)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: pressed)
    }
}

struct OceanMembrane<Content: View>: View {
    var tint = ReefTheme.cyan
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(.horizontal, 26).padding(.vertical, 24).frame(maxWidth: .infinity)
            .background(MembraneSurface(tint: tint))
    }
}

struct ResourceOrb: View {
    let kind: ReefIconKind
    let count: Int
    let label: String
    private var tint: Color { label == "Glow" ? ReefTheme.gold : ReefTheme.cyan }
    var body: some View {
        HStack(spacing: 5) {
            ReefIcon(kind, size: 30)
            Text("\(count)").reefFont(size: 18, weight: .semibold).monospacedDigit()
        }
        .foregroundStyle(ReefTheme.ink)
        .padding(.horizontal, 6).frame(minWidth: 48, minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(label)")
    }
}

struct CoralShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        path.move(to: p(0.49, 0.90))
        path.addCurve(to: p(0.52, 0.12), control1: p(0.42, 0.66), control2: p(0.59, 0.39))
        path.move(to: p(0.49, 0.66))
        path.addCurve(to: p(0.18, 0.22), control1: p(0.17, 0.64), control2: p(0.28, 0.40))
        path.move(to: p(0.27, 0.48))
        path.addQuadCurve(to: p(0.08, 0.40), control: p(0.13, 0.51))
        path.move(to: p(0.51, 0.43))
        path.addCurve(to: p(0.80, 0.14), control1: p(0.80, 0.43), control2: p(0.71, 0.27))
        path.move(to: p(0.49, 0.76))
        path.addCurve(to: p(0.86, 0.47), control1: p(0.80, 0.76), control2: p(0.74, 0.60))
        return path
    }
}

struct SectionHeading: View {
    var eyebrow: String = ""
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !eyebrow.isEmpty { Text(eyebrow).reefFont(size: 9, weight: .medium).tracking(2.1).foregroundStyle(ReefTheme.muted) }
            Text(title).reefFont(.largeTitle, weight: .light).tracking(-0.7).foregroundStyle(ReefTheme.ink)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

// All four directions use fonts supplied by the OS. No downloads or font files.
enum ReefTypography {
    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let strong = weight == .medium || weight == .semibold || weight == .bold || weight == .heavy
        return .custom(strong ? "ChalkboardSE-Bold" : "ChalkboardSE-Regular", fixedSize: size)
    }
}

private struct ReefDiscoveryPresentationKey: EnvironmentKey {
    static let defaultValue: (UUID) -> Void = { _ in }
}
extension EnvironmentValues {
    var presentReefDiscovery: (UUID) -> Void {
        get { self[ReefDiscoveryPresentationKey.self] }
        set { self[ReefDiscoveryPresentationKey.self] = newValue }
    }
}

private struct ReefFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let display: Bool
    init(size: CGFloat, weight: Font.Weight, display: Bool) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: display ? .title : .body)
        self.weight = weight
        self.display = display
    }
    func body(content: Content) -> some View {
        content.font(ReefTypography.font(size: size, weight: weight))
    }
}

extension View {
    func reefFont(size: CGFloat, weight: Font.Weight = .regular, display: Bool = false) -> some View {
        modifier(ReefFontModifier(size: size, weight: weight, display: display))
    }
    func reefFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline: size = 17
        case .subheadline: size = 15
        case .callout: size = 16
        case .caption: size = 12
        case .caption2: size = 11
        case .footnote: size = 13
        default: size = 17
        }
        return reefFont(size: size, weight: weight, display: [.largeTitle, .title, .title2, .title3].contains(style))
    }
}

struct ReefSettingsView: View {
    @State private var showDesignLab = false
    @State private var showReset = false
    @Binding var appearance: ReefAppearance
    @AppStorage("puffpuff.celebrationAnimations") private var celebrationAnimations = true
    @AppStorage("puffpuff.confirmHintUse") private var confirmHintUse = true
    @Environment(\.dismiss) private var dismiss
    @Environment(ReefStore.self) private var store
    var body: some View {
        OceanScene {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Text("Settings").reefFont(size: 30, weight: .semibold, display: true)
                        Spacer()
                        Button("Done") { dismiss() }.buttonStyle(ReefButtonStyle(kind: .quiet))
                    }.padding(.bottom, 4)
                    BloomLivesButton()
                    ReefAppearanceOptions(selection: $appearance).padding(.bottom, 6)
                    Toggle(isOn: $celebrationAnimations) {
                        Text("Bloom celebrations").reefFont(size: 15, weight: .semibold)
                    }
                    .toggleStyle(.switch).tint(ReefTheme.cyan)
                    .padding(.horizontal, 9).frame(minHeight: 44)
                    Toggle(isOn: $confirmHintUse) {
                        Text("Confirm hints & Future Teller").reefFont(size: 15, weight: .semibold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .toggleStyle(.switch).tint(ReefTheme.cyan)
                    .padding(.horizontal, 9).frame(minHeight: 44)
                    if store.testingToolsEnabled {
                    Button("Playground · golf & paths") { showDesignLab = true }
                        .buttonStyle(ReefButtonStyle(kind: .action))
                    ReefDebugRefills().padding(.bottom, 6)
                    ReefBloomStartOptions { dismiss() }
                    Button("Restart everything") {showReset=true}
                        .buttonStyle(ReefButtonStyle(kind:.quiet)).disabled(store.isSaveBlocked)
                    }
                }.padding(22).frame(maxWidth: 460).frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden).foregroundStyle(ReefTheme.ink)
        }
        .alert("Restart everything?",isPresented:$showReset) {
            Button("Cancel",role:.cancel) {}
            Button("Restart everything",role:.destructive) {
                if store.restartEverything() {
                    for key in ["verticalCoral", "diagonalCoral", "lineCoral", "burstCoral"] {
                        UserDefaults.standard.removeObject(forKey:"puffpuff.tutorial." + key)
                    }
                    dismiss()
                }
            }
        } message: {Text("All levels, Trail progress and supplies will restart. A backup of this game is kept.")}
        .sheet(isPresented: $showDesignLab) {
            if store.testingToolsEnabled { ReefDesignLab().presentationDetents([.large]).presentationBackground(.clear) }
        }
        .task { await store.refreshTestingAccess() }
        .onChange(of: store.testingToolsEnabled) { _, enabled in
            if !enabled { showDesignLab = false; showReset = false }
        }
        .environment(\.colorScheme, appearance.colorScheme)
        .preferredColorScheme(appearance.colorScheme)
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 460, minHeight: 680)
        #endif
    }
}

/// Inventory tools stay in settings so gameplay has its player-facing layout.
private struct ReefDebugRefills: View {
    @Environment(ReefStore.self) private var store
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 8) {
            Button { expanded.toggle() } label: {
                HStack(spacing: 8) {
                    Label("Debug refills", systemImage: "plus.circle")
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }.reefFont(size: 15, weight: .semibold)
            }
            .buttonStyle(ReefButtonStyle(kind: .quiet))
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(ReefDebugSupply.allCases) { supply in
                        Button { store.addDebugSupply(supply) } label: {
                            VStack(spacing: 5) {
                                Text("+\(supply.amount) \(supply.name)")
                                    .reefFont(size: 12, weight: .semibold)
                                ReefIconLabel("\(store.progress[keyPath: supply.balance])", supply.iconKind)
                                    .reefFont(size: 11).foregroundStyle(ReefTheme.muted)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(ReefButtonStyle(kind: .orb))
                        .disabled(store.isSaveBlocked)
                        .accessibilityLabel("Add \(supply.amount) \(supply.name)")
                        .accessibilityValue("\(store.progress[keyPath: supply.balance]) available")
                    }
                }
            }
        }
    }
}


enum ReefAppearance: String, CaseIterable, Identifiable {
    case lagoon, deepSea
    var id: String { rawValue }
    var name: String { self == .lagoon ? "Lagoon" : "Deep Sea" }
    var symbol: String { self == .lagoon ? "sun.max" : "moon.stars" }
    var colorScheme: ColorScheme { self == .lagoon ? .light : .dark }
}

struct ReefAppearanceOptions: View {
    @Binding var selection: ReefAppearance
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ReefAppearance.allCases) { appearance in
                Button { selection = appearance } label: {
                    HStack(spacing: 7) {
                        Image(systemName: appearance.symbol).font(.system(size: 16))
                        Text(appearance.name).reefFont(size: 14, weight: .medium)
                    }
                    .foregroundStyle(selection == appearance ? ReefTheme.ink : ReefTheme.muted)
                    .frame(maxWidth: .infinity).frame(minHeight: 52)
                    .background {
                        if selection == appearance {
                            MembraneSurface(tint: ReefTheme.cyan, intensity: 1.1, round: true)
                        }
                    }
                }.buttonStyle(ReefButtonStyle(kind: .navigation))
                    .accessibilityLabel("\(appearance.name) appearance")
                    .accessibilityAddTraits(selection == appearance ? [.isSelected] : [])
            }
        }
    }
}

extension ReefDebugSupply {
    var iconKind: ReefIconKind {
        switch self {
        case .glow: .glow
        case .shots: .shot
        case .hints: .hint
        case .futureTellers: .futureTeller
        case .lives: .life
        case .lighters: .lighter
        case .boosts: .boostStored
        case .currents: .current
        case .currentAdders: .currentAdder
        case .bouncyBlocks: .bouncyBlock
        }
    }
}
