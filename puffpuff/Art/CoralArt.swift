import SwiftUI

/// Three decorative corals plus distinct vertical and horizontal current corals.
enum CoralSpecies: Int, CaseIterable {
    case peachSprig, rosyFan, honeyCups, tideSpires, driftShelf, burstAnemone

    var color: UInt32 { [0xF49B87, 0xEB8196, 0xF2BA76, 0x70C7B5, 0xE9A279, 0xE997AD][rawValue] }
    var tip: UInt32 { [0xFFD0AF, 0xFFB4BD, 0xFFE0A4, 0xD8F3BC, 0xFFE0AE, 0xFFE0C7][rawValue] }
    var left: Path { [CoralPaths.peachSprigLeft, CoralPaths.rosyFanLeft, CoralPaths.honeyCupsLeft, CoralPaths.tideSpiresLeft, CoralPaths.driftShelfLeft, CoralPaths.burstAnemoneLeft][rawValue] }
    var right: Path { [CoralPaths.peachSprigRight, CoralPaths.rosyFanRight, CoralPaths.honeyCupsRight, CoralPaths.tideSpiresRight, CoralPaths.driftShelfRight, CoralPaths.burstAnemoneRight][rawValue] }
    var body: Path { [CoralPaths.peachSprigBody, CoralPaths.rosyFanBody, CoralPaths.honeyCupsBody, CoralPaths.tideSpiresBody, CoralPaths.driftShelfBody, CoralPaths.burstAnemoneBody][rawValue] }
    var veins: Path { [CoralPaths.peachSprigVeins, CoralPaths.rosyFanVeins, CoralPaths.honeyCupsVeins, CoralPaths.tideSpiresVeins, CoralPaths.driftShelfVeins, CoralPaths.burstAnemoneVeins][rawValue] }
    var dots: [(Double, Double, Double)] {
        switch self {
        case .peachSprig: return [(44,18,2),(24,32,1.6),(78,32,1.6),(37,80,1.6),(61,81,1.5)]
        case .rosyFan: return [(48,21,1.8),(32,32,1.6),(66,30,1.7),(17,45,1.5),(83,46,1.5)]
        case .honeyCups: return [(21,60,1.6),(40,48,1.4),(61,53,1.7),(80,54,1.5),(36,80,1.6),(52,76,1.5)]
        case .tideSpires: return [(36,20,1.4),(25,24,1.2),(65,22,1.3),(74,25,1.2),(56,13,1.4),(46,77,1.4),(55,86,1.1)]
        case .burstAnemone: return [(16,40,1.5),(24,28,1.4),(37,24,1.4),(64,23,1.3),(82,40,1.5),(85,59,1.2),(25,70,1.6),(39,72,1.5),(61,69,1.3),(49,86,1.3)]
        case .driftShelf: return [(16,39,1.4),(28,39,1.2),(72,39,1.3),(86,38,1.3),(35,54,1.2),(63,54,1.3),(55,85,1.1)]
        }
    }
}

struct CoralArt: View {
    let species: CoralSpecies
    var lit = true
    var bloom = 0.0
    var swell = 0.0
    var seed = 0.0
    var linkedFill: UInt32? = nil
    var linkedTip: UInt32? = nil
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width, size.height) / 100
            context.translateBy(x: (size.width - unit * 100) / 2, y: (size.height - unit * 100) / 2)
            context.scaleBy(x: unit, y: unit)
            let fill = lit ? Self.blend(linkedFill ?? species.color, 0xFFD6A0, bloom)
                : linkedFill.map { Self.blend($0, 0x345F5D, 0.70) } ?? ReefTheme.sleepyCoral
            let tip = lit ? Self.blend(linkedTip ?? species.tip, 0xFFF0C9, bloom)
                : linkedTip.map { Self.blend($0, 0x56706D, 0.62) } ?? ReefTheme.sleepyTip
            let moving = !reduceMotion && lit
            let sway = moving ? ReefMotion.wave(time, period: 8000, phase: seed * 0.13) : 0
            let ripple = moving ? ReefMotion.wave(time, period: 12000, phase: seed * 0.13 + 0.18) : 0
            let breath = moving ? ReefMotion.wave(time, period: 6000, phase: seed * 0.09) : 0
            let stretch = reduceMotion ? 0 : swell

            context.fill(Path(ellipseIn: CGRect(x: 22, y: 84, width: 56, height: 10)), with: .color(ReefTheme.abyss.opacity(0.16)))
            context.translateBy(x: 50, y: 89)
            context.rotate(by: .degrees(sway * (species == .rosyFan ? 1.65 : 1.15)))
            // A tiny flexible bend keeps the foot planted in the sand.
            context.concatenate(CGAffineTransform(a: 1, b: 0, c: ripple * 0.012, d: 1, tx: 0, ty: 0))
            context.scaleBy(x: 1 - stretch * 0.025 + breath * 0.004, y: 1 + stretch * 0.07 - breath * 0.003)
            context.translateBy(x: -50, y: -89)
            for (branch, direction) in [(species.left, -1.0), (species.right, 1.0)] {
                var arm = context
                arm.translateBy(x: 50, y: 82)
                arm.rotate(by: .degrees((sway * 0.8 + ripple * 0.5 + stretch * 2.4) * direction))
                arm.translateBy(x: -50, y: -82)
                arm.fill(branch, with: .color(fill))
            }
            context.fill(species.body, with: .color(fill))
            if lit {
                context.stroke(species.veins, with: .color(tip.opacity(0.95)), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
                for (x, y, r) in species.dots {
                    context.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)), with: .color(tip))
                }
            }

        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    static func blend(_ from: UInt32, _ to: UInt32, _ amount: Double) -> Color {
        let t = min(1, max(0, amount))
        func component(_ shift: UInt32) -> Double {
            let a = Double((from >> shift) & 255), b = Double((to >> shift) & 255)
            return (a + (b-a) * t) / 255
        }
        return Color(red: component(16), green: component(8), blue: component(0))
    }
}

/// A bounded, single celebration driven by the board's shared Rossark clock.
struct BloomRipple: View {
    let time: Double
    let origin: UnitPoint

    var body: some View {
        Canvas { context, size in
            guard time > 0, time < 1850 else { return }
            let center = CGPoint(x: size.width * origin.x, y: size.height * origin.y)
            let reach = hypot(size.width, size.height)
            for offset in [0.0, 200.0] {
                let p = min(1, max(0, (time-offset) / 1150))
                let radius = 7 + reach * p * 0.85
                let circle = Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2))
                context.stroke(circle, with: .color(ReefTheme.bloom.opacity(sin(p * .pi) * 0.45)), lineWidth: 1.3)
            }
            for i in 0..<18 {
                let p = min(1, max(0, (time - Double(i % 5)*65) / 1450))
                let angle = Double(i) * 2.39996
                let distance = 12 + p * (45 + Double(i % 4)*18)
                let x = center.x + cos(angle) * distance
                let y = center.y + sin(angle) * distance * 0.7 - p*p*55
                let r = 1.2 + Double(i % 3)*0.7
                let bubble = Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2))
                let color = (i % 2 == 0 ? ReefTheme.bloom : ReefTheme.coral).opacity(sin(p * .pi) * 0.85)
                context.stroke(bubble, with: .color(color), lineWidth: 1)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A resting tile is matte and still. It has no membrane, glint or tap response.
struct RestingPebbleTile: View {
    var seed = 0.0

    var body: some View {
        ZStack {
            SeaGlassShape(seed: seed, amplitude: 0)
                .fill(Color.adaptive(light: 0xA5B5AE, dark: 0x34494B))
            Canvas { context, size in
                let unit = min(size.width, size.height) / 100
                context.translateBy(x: (size.width - unit * 100) / 2, y: (size.height - unit * 100) / 2)
                context.scaleBy(x: unit, y: unit)
                context.fill(Path(ellipseIn: CGRect(x: 18, y: 66, width: 65, height: 9)), with: .color(Color.adaptive(light: 0x8A9E96, dark: 0x2C3E40)))
                var pebble = Path()
                pebble.move(to: CGPoint(x: 21, y: 65))
                pebble.addCurve(to: CGPoint(x: 34, y: 34), control1: CGPoint(x: 17, y: 54), control2: CGPoint(x: 23, y: 39))
                pebble.addCurve(to: CGPoint(x: 63, y: 33), control1: CGPoint(x: 44, y: 28), control2: CGPoint(x: 55, y: 27))
                pebble.addCurve(to: CGPoint(x: 81, y: 60), control1: CGPoint(x: 75, y: 40), control2: CGPoint(x: 85, y: 49))
                pebble.addCurve(to: CGPoint(x: 60, y: 72), control1: CGPoint(x: 79, y: 69), control2: CGPoint(x: 69, y: 73))
                pebble.addCurve(to: CGPoint(x: 21, y: 65), control1: CGPoint(x: 43, y: 76), control2: CGPoint(x: 25, y: 74))
                pebble.closeSubpath()
                context.fill(pebble, with: .color(Color.adaptive(light: 0x7F958C, dark: 0x687D79)))
                var curve = Path()
                curve.move(to: CGPoint(x: 30, y: 49))
                curve.addCurve(to: CGPoint(x: 58, y: 38), control1: CGPoint(x: 35, y: 38), control2: CGPoint(x: 48, y: 34))
                context.stroke(curve, with: .color(Color.adaptive(light: 0xB5C5BB, dark: 0x9AAEA4)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                var seam = Path()
                seam.move(to: CGPoint(x: 27, y: 65))
                seam.addCurve(to: CGPoint(x: 73, y: 62), control1: CGPoint(x: 42, y: 72), control2: CGPoint(x: 65, y: 71))
                context.stroke(seam, with: .color(Color.adaptive(light: 0x6E857B, dark: 0x506661)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                for (x, y, r) in [(35.0, 57.0, 1.5), (39.0, 61.0, 1.0), (67.0, 48.0, 1.2)] {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(Color.adaptive(light: 0x9DB2A7, dark: 0x839990)))
                }
            }
        }.aspectRatio(1, contentMode: .fit).allowsHitTesting(false).accessibilityHidden(true)
    }
}
