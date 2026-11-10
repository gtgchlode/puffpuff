import SwiftUI

struct PipView: View {
    var paused = false
    var happy = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ReefClock(period: PipChoreography.period, paused: paused, frameInterval: 1.0 / 30) { time in
            PipPoseArtwork(inflation: happy ? 0 : 1, joy: happy ? 1 : 0, time: time)
                .animation(reduceMotion ? nil : .timingCurve(0.23, 1, 0.32, 1, duration: 0.7), value: happy)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(happy ? "PuffPuff, relaxed and smiling" : "PuffPuff, a puffed-up golden pufferfish")
        .allowsHitTesting(false)
    }
}

struct PipPoseArtwork: View, Animatable {
    var inflation: Double
    var joy: Double
    var time = 0.0
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(inflation, joy) }
        set { inflation = newValue.first; joy = newValue.second }
    }
    var body: some View {
        Canvas { context, size in
            PipRenderer.drawPose(in: context, size: size, time: time, inflation: inflation, joy: joy)
        }
    }
}

enum PipRenderer {
    static let outline: UInt32 = 0x292119
    static let gold: UInt32 = 0xD99C3B
    static let cream: UInt32 = 0xFFE29A
    static let green: UInt32 = 0x69BF45

    static func draw(in context: GraphicsContext, size: CGSize, time: Double, puff: Double = 1, happy: Bool = false) {
        drawPose(in: context, size: size, time: time, inflation: happy ? 0 : puff, joy: happy ? 1 : 0)
    }

    static func drawPose(in context: GraphicsContext, size: CGSize, time: Double, inflation: Double, joy: Double, chew: Double = 0) {
        var root = context
        let scale = min(size.width / 320, size.height / 270)
        root.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 270 * scale) / 2)
        root.scaleBy(x: scale, y: scale)
        let wave = ReefMotion.wave(time, period: PipChoreography.breathPeriod)
        root.fill(PipPaths.ellipse(172, 249, 60 - wave * 2, 5.5), with: .color(color(0x206C69).opacity(0.15)))
        root.translateBy(x: 173, y: 144 + wave * 1.8)
        root.rotate(by: .degrees(1.1 * ReefMotion.wave(time, period: 8000)))
        root.scaleBy(x: 1 - 0.004 * wave, y: 1 + 0.006 * wave)
        root.translateBy(x: -173, y: -144)
        for part in parts(time: time, inflation: inflation, joy: joy, chew: chew) {
            var layer = root
            layer.concatenate(part.transform)
            layer.opacity = part.opacity
            if let fill = part.fill { layer.fill(part.path, with: .color(color(fill))) }
            if let stroke = part.stroke {
                layer.stroke(part.path, with: .color(color(stroke)), style: StrokeStyle(lineWidth: part.width, lineCap: .round, lineJoin: .round))
            }
        }
    }

    // Official Affinity paths are the resting pose; motion is added relative to it.
    static func parts(time: Double = 0, inflation: Double, joy: Double, chew: Double = 0) -> [PipVectorPart] {
        let artwork = PipPaths.parts(inflation: inflation)
        let lid = ReefMotion.track(time, PipChoreography.blink)
        let look = (ReefMotion.track(time, PipChoreography.look)
                    - ReefMotion.track(0, PipChoreography.look)) * 0.55
        let eyeCenters = Dictionary(uniqueKeysWithValues: artwork.compactMap { part -> (String, CGPoint)? in
            guard part.name == "left-eye-white" || part.name == "right-eye-white" else { return nil }
            let bounds = part.path.applying(part.transform).boundingRect
            return (part.name.hasPrefix("left") ? "left" : "right", CGPoint(x: bounds.midX, y: bounds.midY))
        })
        func waveDelta(period: Double, phase: Double = 0) -> Double {
            ReefMotion.wave(time, period: period, phase: phase) - ReefMotion.wave(0, period: period, phase: phase)
        }
        return artwork.filter { $0.opacity > 0 }.map { original in
            var part = original
            if chew>0 && (part.name.contains("mouth") || part.name.contains("smile")) {
                let b=part.path.applying(part.transform).boundingRect
                part.transform=part.transform.concatenating(CGAffineTransform(translationX:b.midX,y:b.midY).scaledBy(x:1+chew*0.07,y:1-chew*0.35).translatedBy(x:-b.midX,y:-b.midY))
            }
            var attachment: CGPoint?
            var degrees = 0.0
            if part.name == "tail" {
                attachment = CGPoint(x: 105, y: 154)
                degrees = 5 * waveDelta(period: 4000, phase: -110.0 / 4000)
            } else if part.name.hasPrefix("left-side-fin") {
                attachment = .zero
                degrees = 5 * waveDelta(period: 2000, phase: 0.505)
            } else if part.name.hasPrefix("right-side-fin") {
                attachment = CGPoint(x: 252, y: 164)
                degrees = (4 + 3 * joy) * waveDelta(period: 2000, phase: 0.1)
            }
            if let attachment {
                let anchor = attachment.applying(part.transform)
                part.transform = part.transform.concatenating(pivot(x: anchor.x, y: anchor.y, degrees: degrees))
            }
            for side in ["left", "right"] {
                let eyeLayer = part.name.hasPrefix("\(side)-eye-") || part.name == "\(side)-iris" || part.name == "\(side)-pupil"
                guard eyeLayer, let center = eyeCenters[side] else { continue }
                if part.name != "\(side)-eye-white" {
                    part.transform = part.transform.concatenating(CGAffineTransform(translationX: look, y: 0))
                }
                let blink = CGAffineTransform(translationX: center.x, y: center.y)
                    .scaledBy(x: 1, y: 1 - lid * 0.96).translatedBy(x: -center.x, y: -center.y)
                part.transform = part.transform.concatenating(blink)
            }
            return part
        }
    }

    static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
    private static func pivot(x: Double, y: Double, degrees: Double) -> CGAffineTransform {
        CGAffineTransform(translationX: x, y: y).rotated(by: degrees * .pi / 180).translatedBy(x: -x, y: -y)
    }
}
