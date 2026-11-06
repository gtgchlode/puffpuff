import SwiftUI

private struct OceanTimeKey: EnvironmentKey { static let defaultValue = 0.0 }
extension EnvironmentValues {
    var oceanTime: Double {
        get { self[OceanTimeKey.self] }
        set { self[OceanTimeKey.self] = newValue }
    }
}

// One 30 Hz clock for the water, all membrane caustics, and hover reflections.
// Characters retain their own Rossark choreography. No per-particle timers.
struct OceanScene<Content: View>: View {
    var paused = false
    @ViewBuilder var content: Content
    var body: some View {
        ReefClock(period: 48000, paused: paused, frameInterval: 1.0 / 30) { time in
            ZStack {
                OceanBackdrop(time: time).ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
                content.environment(\.oceanTime, time)
            }
        }
    }
}

// A closed, periodic spline: gently irregular like a worn shell, never a box.
struct SeaGlassShape: Shape {
    var phase: Double = 0
    var seed: Double = 0
    var amplitude: Double = 0.025
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(phase, amplitude) }
        set { phase = newValue.first; amplitude = newValue.second }
    }
    func path(in rect: CGRect) -> Path {
        let count = 12
        let points: [CGPoint] = (0..<count).map { i in
            let a = Double(i) / Double(count) * .pi * 2
            let r = 0.455 + 0.018 * sin(3 * a + seed) + amplitude * sin(5 * a + phase + seed)
            return CGPoint(x: rect.midX + cos(a) * rect.width * r, y: rect.midY + sin(a) * rect.height * r)
        }
        var path = Path()
        path.move(to: points[0])
        for i in 0..<count {
            let a = points[(i + count - 1) % count], b = points[i]
            let c = points[(i + 1) % count], d = points[(i + 2) % count]
            path.addCurve(to: c,
                          control1: CGPoint(x: b.x + (c.x - a.x) / 6, y: b.y + (c.y - a.y) / 6),
                          control2: CGPoint(x: c.x - (d.x - b.x) / 6, y: c.y - (d.y - b.y) / 6))
        }
        path.closeSubpath()
        return path
    }
}

// Broad membranes use hand-curved lobes, with a thin living lip.
struct MembraneShape: Shape {
    var phase: Double = 0
    var animatableData: Double { get { phase } set { phase = newValue } }
    func path(in rect: CGRect) -> Path {
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        let drift = sin(phase) * 0.012
        var path = Path()
        path.move(to: p(0.04, 0.24))
        path.addCurve(to: p(0.50, 0.04 + drift), control1: p(0.10, -0.04), control2: p(0.29, 0.10))
        path.addCurve(to: p(0.96, 0.24), control1: p(0.76, -0.03), control2: p(0.94, 0.02))
        path.addCurve(to: p(0.94, 0.78), control1: p(1.04, 0.43), control2: p(0.88, 0.56))
        path.addCurve(to: p(0.51, 0.96 - drift), control1: p(0.97, 1.03), control2: p(0.71, 0.91))
        path.addCurve(to: p(0.06, 0.81), control1: p(0.27, 1.03), control2: p(0.03, 0.96))
        path.addCurve(to: p(0.04, 0.24), control1: p(-0.02, 0.64), control2: p(0.09, 0.44))
        path.closeSubpath()
        return path
    }
}

enum WaterDrawing {
    static func seed(_ i: Int, salt: Double = 0) -> Double {
        let value = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
        return value - floor(value)
    }

    // Interconnected warped cells suggest light focused through a moving surface.
    static func caustics(in context: GraphicsContext, size: CGSize, time: Double, strength: Double = 1) {
        let t = time / 48000 * .pi * 2
        let step = max(36, size.width / 6)
        func point(_ column: Int, _ row: Int) -> CGPoint {
            let x = Double(column) * step + (row % 2 == 0 ? 0 : step * 0.46)
            let y = Double(row) * step * 0.66
            return CGPoint(x: x + sin(Double(row) * 1.3 + Double(column) + t * 2) * step * 0.18,
                           y: y + cos(Double(column) * 1.8 + t * 3) * step * 0.12)
        }
        var lace = Path()
        for row in -1...Int(size.height / step * 1.6) + 1 {
            for column in -1...7 {
                let a = point(column, row), b = point(column + 1, row), c = point(column, row + 1)
                lace.move(to: a)
                lace.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 - step * 0.13))
                lace.move(to: a)
                lace.addQuadCurve(to: c, control: CGPoint(x: (a.x + c.x) / 2 + step * 0.15, y: (a.y + c.y) / 2))
            }
        }
        context.stroke(lace, with: .color(ReefTheme.glint.opacity(0.07 * strength)), lineWidth: 4)
        context.stroke(lace, with: .color(ReefTheme.glint.opacity(0.32 * strength)), lineWidth: 0.65)
    }
}

struct OceanBackdrop: View {
    let time: Double
    @Environment(\.colorScheme) private var colorScheme
    private var isDeepSea: Bool { colorScheme == .dark }
    var body: some View {
        Canvas { context, size in
            let bounds = Path(CGRect(origin: .zero, size: size))
            context.fill(bounds, with: .linearGradient(Gradient(colors: isDeepSea ? [Color(hex: 0x10383F), Color(hex: 0x082A33), Color(hex: 0x041923), Color(hex: 0x02121C)] : [Color(hex: 0xC5EBCF), Color(hex: 0x8AD4C4), Color(hex: 0x62B5AD), Color(hex: 0xA8CEAC)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            context.fill(bounds, with: .radialGradient(Gradient(colors: [ReefTheme.glint.opacity(isDeepSea ? 0.075 : 0.55), .clear]), center: CGPoint(x: size.width * 0.06, y: size.height * 0.16), startRadius: 0, endRadius: size.height * 0.66))
            context.drawLayer { rays in
                rays.addFilter(.blur(radius: 10))
                rays.blendMode = .plusLighter
                for i in 0..<6 {
                    let drift = sin(time / 48000 * .pi * 2 + Double(i)) * 0.035
                    let x = size.width * (Double(i) * 0.17 - 0.23 + drift)
                    var ray = Path()
                    ray.move(to: CGPoint(x: x, y: -30))
                    ray.addLine(to: CGPoint(x: x + 18, y: -30))
                    ray.addLine(to: CGPoint(x: x + size.width * 0.60 + 80, y: size.height * 0.83))
                    ray.addLine(to: CGPoint(x: x + size.width * 0.51, y: size.height * 0.83))
                    ray.closeSubpath()
                    rays.fill(ray, with: .linearGradient(Gradient(colors: [ReefTheme.glint.opacity((i % 2 == 0 ? 0.16 : 0.08) * (isDeepSea ? 0.5 : 1)), .clear]), startPoint: .zero, endPoint: CGPoint(x: size.width * 0.5, y: size.height * 0.8)))
                }
            }
            var surface = context
            surface.opacity = isDeepSea ? 0.09 : 0.55
            WaterDrawing.caustics(in: surface, size: size, time: time)
            for i in 0..<28 {
                let phase = (time / 48000 + WaterDrawing.seed(i)).truncatingRemainder(dividingBy: 1)
                let x = size.width * WaterDrawing.seed(i, salt: 2) + sin(phase * .pi * 2 + Double(i)) * 14
                let y = size.height * (1 - phase)
                let radius = 0.7 + WaterDrawing.seed(i, salt: 3) * 1.25
                let fade = sin(phase * .pi)
                let color = i % 6 == 0 ? (isDeepSea ? ReefTheme.honey : ReefTheme.sand) : ReefTheme.glint
                if isDeepSea {
                    context.fill(Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: radius * 2 + 8, height: radius * 2 + 8)),
                                 with: .radialGradient(Gradient(colors: [color.opacity(fade * 0.10), .clear]), center: CGPoint(x: x + radius, y: y + radius), startRadius: 0, endRadius: radius + 4))
                }
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(color.opacity(fade * (isDeepSea ? 0.6 : 0.42))))
                if i % 7 == 0 {
                    context.stroke(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: radius * 2 + 6, height: radius * 2 + 6)), with: .color(color.opacity(fade * 0.13)), lineWidth: 0.5)
                }
            }
            // A low, asymmetric sandbank frames the navigation without boxing it in.
            var shore = Path()
            shore.move(to: CGPoint(x: -20, y: size.height - 68))
            shore.addCurve(to: CGPoint(x: size.width + 20, y: size.height - 90),
                           control1: CGPoint(x: size.width * 0.32, y: size.height - 132),
                           control2: CGPoint(x: size.width * 0.61, y: size.height - 16))
            shore.addLine(to: CGPoint(x: size.width + 20, y: size.height + 20))
            shore.addLine(to: CGPoint(x: -20, y: size.height + 20))
            shore.closeSubpath()
            context.fill(shore, with: .linearGradient(Gradient(colors: [ReefTheme.sand.opacity(0.8), ReefTheme.sand]), startPoint: CGPoint(x: 0, y: size.height - 110), endPoint: CGPoint(x: 0, y: size.height)))
            for i in 0..<22 {
                let x = WaterDrawing.seed(i, salt: 11) * size.width
                let y = size.height - WaterDrawing.seed(i, salt: 17) * 35
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 1)), with: .color(ReefTheme.gold.opacity(0.16)))
            }
        }
    }
}

struct MembraneSurface: View {
    var tint = ReefTheme.cyan
    var intensity = 1.0
    var seed = 0.0
    var round = false
    var interaction = 0.0
    var showsBorder = true
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    private var isDeepSea: Bool { colorScheme == .dark }

    var body: some View {
        Canvas { context, size in
            let phase = time / 48000 * .pi * 2
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let outline = round ? SeaGlassShape(phase: phase * 2, seed: seed, amplitude: 0.018 + interaction * 0.025).path(in: rect) : MembraneShape(phase: phase).path(in: rect)
            var shadow = context
            shadow.translateBy(x: 0, y: 3)
            shadow.fill(outline, with: .color(ReefTheme.abyss.opacity(isDeepSea ? 0.25 : 0.09)))
            context.fill(outline, with: .color(ReefTheme.glass.opacity(reduceTransparency ? 1 : isDeepSea ? 0.72 : 0.42)))
            var inner = context
            inner.clip(to: outline)
            inner.fill(outline, with: .linearGradient(Gradient(colors: [ReefTheme.glint.opacity(isDeepSea ? 0.035 : 0.3), tint.opacity(0.025), tint.opacity((isDeepSea ? 0.035 : 0.09) * intensity)]), startPoint: .zero, endPoint: CGPoint(x: size.width * 0.8, y: size.height)))
            WaterDrawing.caustics(in: inner, size: size, time: time + seed * 1000, strength: intensity * (isDeepSea ? 0.13 : 0.35))
            let shimmer = reduceMotion ? 0.35 : (sin(phase * 6 + seed) + 1) / 2
            var reflection = Path()
            reflection.move(to: CGPoint(x: -20, y: size.height * (0.15 + shimmer * 0.4)))
            reflection.addCurve(to: CGPoint(x: size.width + 20, y: size.height * (0.46 + shimmer * 0.3)), control1: CGPoint(x: size.width * 0.25, y: size.height * (0.6 + interaction * 0.12)), control2: CGPoint(x: size.width * 0.75, y: -size.height * 0.05))
            inner.stroke(reflection, with: .color(tint.opacity((isDeepSea ? 0.035 : 0.09) + interaction * 0.19)), lineWidth: 6 + interaction * 9)
            inner.stroke(reflection, with: .color(ReefTheme.glint.opacity((isDeepSea ? 0.1 : 0.3) + interaction * 0.3)), lineWidth: 0.6)
            if showsBorder {
                context.stroke(outline, with: .linearGradient(Gradient(colors: [ReefTheme.glint.opacity(isDeepSea ? 0.42 : 0.85), ReefTheme.glint.opacity(isDeepSea ? 0.06 : 0.15), ReefTheme.cyan.opacity(0.25 * intensity), ReefTheme.glint.opacity(isDeepSea ? 0.22 : 0.6)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 1.1 + interaction * 0.5)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct TideDivider: View {
    var tint = ReefTheme.cyan
    @Environment(\.oceanTime) private var time
    var body: some View {
        Canvas { context, size in
            var line = Path()
            for i in 0...40 {
                let x = size.width * Double(i) / 40
                let y = size.height / 2 + sin(Double(i) / 40 * .pi * 2 + time / 48000 * .pi * 2) * 2
                if i == 0 { line.move(to: CGPoint(x: x, y: y)) } else { line.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(line, with: .linearGradient(Gradient(colors: [.clear, tint.opacity(0.6), .clear]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 0.75)
        }.frame(height: 8).accessibilityHidden(true)
    }
}
