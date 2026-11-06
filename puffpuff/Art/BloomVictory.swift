import SwiftUI

/// Short, one-shot swims selected from authored puzzle complexity.
/// Rendering never grants rewards or mutates a board.
enum BloomVictoryStyle: String, CaseIterable {
    case hop, doubleHop, wiggle, swoop, bob, drift, lap, bubbleSpin

    static func choose(level: Int, size: Int, feature: String, pearlTarget: Int?) -> Self {
        if feature == "star" || feature == "mixed" || (pearlTarget ?? 0) >= 12 { return .bubbleSpin }
        if feature == "stone" || feature == "current" || feature == "vertical" || size >= 5 { return .lap }
        let gentle: [Self] = [.hop, .wiggle, .swoop, .doubleHop, .bob, .drift]
        return gentle[(max(1, level) - 1) % gentle.count]
    }

    static let departureDuration = 250.0
    static let returnDuration = 500.0
    static let reinflationDuration = 1100.0
    var isInPlace: Bool { self == .hop || self == .doubleHop }
    var duration: Double { isInPlace ? swimDuration : Self.departureDuration + swimDuration + Self.returnDuration }

    var swimDuration: Double {
        switch self {
        case .hop: 1100
        case .doubleHop: 1450
        case .wiggle: 1300
        case .swoop: 1500
        case .bob: 1350
        case .drift: 1400
        case .lap: 1900
        case .bubbleSpin: 2500
        }
    }

    var label: String {
        switch self {
        case .hop: "Happy hop"
        case .doubleHop: "Two little hops"
        case .wiggle: "Little wiggle"
        case .swoop: "Happy swoop"
        case .bob: "Little bob"
        case .drift: "Gentle drift"
        case .lap: "Victory lap"
        case .bubbleSpin: "Bubble spin"
        }
    }

    func position(_ progress: Double) -> CGPoint {
        let t = min(1,max(0,progress)), a = t * .pi * 2
        switch self {
        case .hop, .doubleHop:
            return .init(x:0.5,y:0.5)
        case .wiggle:
            return .init(x: 0.78 - 0.52*sin(.pi*t), y: 0.27 + 0.08*sin(a*2))
        case .swoop:
            return .init(x: 0.78 - 0.51*sin(.pi*t), y: 0.23 + 0.30*pow(sin(.pi*t),2))
        case .bob:
            return .init(x: 0.72 - 0.18*sin(.pi*t), y: 0.20 + 0.16*pow(sin(.pi*t),2))
        case .drift:
            return .init(x: 0.78 - 0.32*sin(.pi*t), y: 0.26 + 0.08*sin(a) + 0.05*sin(.pi*t))
        case .lap:
            return .init(x: 0.5 + 0.32*cos(a - .pi/4), y: 0.48 + 0.30*sin(a - .pi/4))
        case .bubbleSpin:
            return .init(x: 0.5 + 0.31*cos(a), y: 0.48 + 0.25*sin(a*2))
        }
    }
}

/// Resolve both destinations in the same scrolling content coordinate space.
struct BloomFishAnchors: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct BloomFishLayer: View {
    let board: CGRect
    let restingFrame: CGRect
    let style: BloomVictoryStyle
    let time: Double
    let happy: Bool
    let celebrating: Bool
    var reinflating = false
    @Environment(\.oceanTime) private var oceanTime
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, _ in
            BloomVictoryArt.draw(in: context, board: board, restingFrame: restingFrame,
                                 style: style, time: time, poseTime: reduceMotion ? 0 : oceanTime,
                                 happy: happy, celebrating: celebrating && !reduceMotion,
                                 reinflating: reinflating && !reduceMotion)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A tap is a little greeting, with no inventory or puzzle side effects.
struct BloomTapBubbles: View {
    let restingFrame: CGRect

    var body: some View {
        ReefClock(duration: 900, frameInterval: 1.0/30) { time in
            Canvas { context, _ in
                Self.draw(in: context, restingFrame: restingFrame, time: time)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }

    static func draw(in context: GraphicsContext, restingFrame: CGRect, time: Double) {
        let scale = min(restingFrame.width/320, restingFrame.height/270)
        let mouth = CGPoint(x: restingFrame.midX + 23*scale, y: restingFrame.midY + 29*scale)
        for i in 0..<5 {
            let t = (time - Double(i)*55)/680
            guard t > 0, t < 1 else { continue }
            let radius = (2.0 + Double(i % 3)*0.8) * (0.65 + t*0.6)
            let x = mouth.x + t*(18 + Double(i)*4) + sin(t * .pi * 2 + Double(i))*3*t
            let y = mouth.y - t*t*(27 + Double(i)*4)
            let bubble = Path(ellipseIn: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2))
            var layer = context
            layer.opacity = min(1, t*9) * min(1, (1-t)*4)
            layer.fill(bubble, with: .color(ReefTheme.glint.opacity(0.18)))
            layer.stroke(bubble, with: .color(ReefTheme.cyan.opacity(0.55)), lineWidth: 1.8)
            layer.stroke(bubble, with: .color(ReefTheme.glint.opacity(0.95)), lineWidth: 0.8)
        }
    }
}

/// Pure presentation of rewards already committed by the store.
enum BloomBubbleReward: String, Identifiable {
    case glow, pearl, hint, shot, doubleShot, instant, refill, stored, lighter
    var id: String { rawValue }
    var kind: ReefIconKind {
        switch self {
        case .glow, .pearl: .glow
        case .hint: .hint
        case .lighter: .lighter
        case .shot, .doubleShot: .shot
        case .refill: .life
        case .instant: .boostLive
        case .stored: .boostStored
        }
    }
    var title: String {
        switch self {
        case .glow: "+3 Glow"
        case .pearl: "+4 Glow"
        case .hint: "+1 hint"
        case .lighter: "+1 lighter"
        case .shot: "+1 shot"
        case .doubleShot: "+2 shots"
        case .refill: "Life refill"
        case .instant, .stored: "15 min"
        }
    }
    var compactTitle: String {
        switch self {
        case .glow: "+3"
        case .pearl: "+4"
        case .hint, .shot, .lighter: "+1"
        case .doubleShot: "+2"
        case .refill: "Full"
        case .instant, .stored: "15 min"
        }
    }
    var detail: String? {
        switch self {
        case .instant: "Lives refilled"
        case .stored: "Saved"
        default: nil
        }
    }
    var accessibility: String {
        switch self {
        case .glow: "3 Glow earned"
        case .pearl: "4 Glow earned, including 1 extra Glow for the pearl target"
        case .refill: "Lives refilled to at least five. No unlimited time added."
        case .instant: "15 minutes of unlimited lives activated. Lives refilled."
        case .stored: "Rare 15-minute unlimited-lives boost saved for later."
        default: title
        }
    }
    static func forGift(_ gift:BloomLifeGift)->Self {
        switch gift {case .instant:.instant;case .refill:.refill;case .stored:.stored}
    }
    static func earned(pearl: Bool, hint: Bool, shot: Bool, gift: BloomLifeGift?, lighter: Bool = false, shots: Int? = nil) -> [Self] {
        var rewards: [Self] = [pearl ? .pearl:.glow]
        if hint { rewards.append(.hint) }
        let count=shots ?? (shot ? 1:0)
        if count>0 { rewards.append(count>1 ? .doubleShot:.shot) }
        if let gift { rewards.append(forGift(gift)) }
        if lighter { rewards.append(.lighter) }
        return rewards
    }
}

struct BloomRewardBubble: View {
    let reward: BloomBubbleReward
    var diameter: CGFloat = 80
    var compact = false
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            if reward == .stored || reward == .instant {
                ReefBoostIcon(stored: reward == .stored, size: diameter * 0.46)
            } else {
                ReefIcon(reward.kind, size: diameter * 0.46)
            }
            Text(compact ? reward.compactTitle : reward.title).reefFont(size: compact ? 12 : diameter * 0.16, weight: .semibold)
                .lineLimit(1).minimumScaleFactor(0.8)
            if let detail = reward.detail, !compact {
                Text(detail).reefFont(size: diameter * 0.105).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(ReefTheme.ink)
        .frame(width: diameter, height: diameter)
        .background {
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
                let phase = reduceMotion ? 0 : time / 6000
                let bubble = SeaGlassShape(phase: phase, seed: 3, amplitude: 0.025).path(in: rect)
                let tint = reward == .stored ? Color(hex: 0xFFD36B) : Color(hex: 0x91E5D4)
                context.fill(bubble, with: .radialGradient(Gradient(colors: [ReefTheme.glass.opacity(0.94), tint.opacity(0.48)]),
                    center: CGPoint(x: size.width * 0.35, y: size.height * 0.3), startRadius: 0, endRadius: size.width))
                context.stroke(bubble, with: .linearGradient(Gradient(colors: [.white.opacity(0.94), tint.opacity(0.25), tint.opacity(0.8)]),
                    startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 1.8)
                var crescent = Path()
                crescent.addArc(center: CGPoint(x: size.width/2, y: size.height/2), radius: size.width*0.40,
                    startAngle: .degrees(205), endAngle: .degrees(255), clockwise: false)
                context.stroke(crescent, with: .color(.white.opacity(0.88)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            }
            .shadow(color: (reward == .stored ? ReefTheme.honey : ReefTheme.glint).opacity(0.45), radius: 10)
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(reward.accessibility)
    }
}

/// Reserve actual header destinations. The same bubble layer flies there and stays.
struct BloomRewardDock: View {
    let rewards: [BloomBubbleReward]
    private func row(_ items: [BloomBubbleReward]) -> some View {
        HStack(spacing: 6) {
            ForEach(items) { reward in
                Color.clear.frame(width: 60, height: 60)
                    .anchorPreference(key: BloomFishAnchors.self, value: .bounds) { ["reward-\(reward.id)": $0] }
                    .accessibilityElement(children: .ignore).accessibilityLabel(reward.accessibility)
            }
        }
    }
    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(rewards)
            VStack(alignment: .trailing, spacing: 4) {
                row(Array(rewards.prefix((rewards.count+1)/2)))
                row(Array(rewards.suffix(rewards.count/2)))
            }
        }
    }
}

/// One continuous, pausable flight into the real taps-left header, with no fade-out
/// or replacement layer on arrival. Reopened wins start at the final destinations.
struct BloomRewardFlight: View {
    let rewards: [BloomBubbleReward]
    let board: CGRect
    let docks: [String: CGRect]
    let time: Double
    let duration: Double

    var body: some View {
        ForEach(Array(rewards.enumerated()), id: \.element.id) { index, reward in
            if let dock = docks["reward-\(reward.id)"] {
                let start = 120 + Double(index)*110
                let t = min(1, max(0, (time-start)/max(300, duration-100-start)))
                let eased = t*t*(3-2*t)
                let column = (CGFloat(index)+0.5)/CGFloat(max(1, rewards.count))
                let fromX = board.minX + 8 + column*(board.width-16)
                let fromY = board.minY + board.height*0.72
                let diameter = dock.width + (72-dock.width)*sin(t * .pi)
                BloomRewardBubble(reward: reward, diameter: diameter, compact: true)
                    .position(x: fromX+(dock.midX-fromX)*eased+sin(t * .pi*2)*5*(1-t),
                              y: fromY+(dock.midY-fromY)*eased)
                    .opacity(min(1, t*8))
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct BloomSuccessBackdrop: View {
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Canvas { context, size in
            var water = context
            water.clip(to: MembraneShape(phase: time/48000 * .pi*2)
                .path(in: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)))
            BloomSuccessWater.draw(in: water, size: size, time: reduceMotion ? 0 : time)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Pearl-lit water behind a finished reef, with no rings added to the coral.
enum BloomSuccessWater {
    static func draw(in context: GraphicsContext, size: CGSize, time: Double) {
        let rect = CGRect(origin: .zero, size: size)
        let phase = time / 12000 * .pi * 2
        let center = CGPoint(x: size.width*(0.45+0.10*sin(phase)), y: size.height*0.38)
        context.fill(Path(rect), with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF1BE).opacity(0.65),
            Color(hex: 0xA8F7E1).opacity(0.22), .clear]), center: center, startRadius: 0, endRadius: size.width*0.8))
        for i in 0..<3 {
            let x = size.width*(Double(i)*0.43-0.2+0.12*sin(phase+Double(i)))
            var ribbon = Path()
            ribbon.move(to: CGPoint(x: x, y: 0))
            ribbon.addLine(to: CGPoint(x: x+size.width*0.15, y: 0))
            ribbon.addLine(to: CGPoint(x: x+size.width*0.72, y: size.height))
            ribbon.addLine(to: CGPoint(x: x+size.width*0.39, y: size.height)); ribbon.closeSubpath()
            var ray = context
            ray.addFilter(.blur(radius: size.width*0.025))
            ray.fill(ribbon, with: .linearGradient(Gradient(colors: [.white.opacity(0.4), Color(hex: 0xFFDA86).opacity(0.05)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        }
        for i in 0..<16 {
            let x = size.width * (0.05 + Double((i*37)%91)/100)
            let y = size.height * (0.04 + Double((i*53)%93)/100)
            let glow = (sin(phase*3 + Double(i)*2.4)+1)/2
            let r = 1.2 + glow*3.2
            var star = Path()
            star.move(to: CGPoint(x: x, y: y-r*1.7))
            star.addQuadCurve(to: CGPoint(x: x+r, y: y), control: CGPoint(x: x, y: y))
            star.addQuadCurve(to: CGPoint(x: x, y: y+r*1.7), control: CGPoint(x: x, y: y))
            star.addQuadCurve(to: CGPoint(x: x-r, y: y), control: CGPoint(x: x, y: y))
            star.addQuadCurve(to: CGPoint(x: x, y: y-r*1.7), control: CGPoint(x: x, y: y))
            var sparkle = context
            sparkle.addFilter(.shadow(color: Color(hex: 0xFFD571).opacity(0.6), radius: 5))
            sparkle.fill(star, with: .color(Color(hex: 0xFFFADE).opacity(0.3+0.7*glow)))
        }
    }
}

enum BloomVictoryArt {
    struct Pose {
        let position: CGPoint
        let size: CGSize
        let rotation: Double
        let inflation: Double
        let joy: Double
    }

    /// This matches PipRenderer's centered 320 × 270 artwork, including its
    /// small vertical letterbox inside the 104 × 88 header slot.
    static func bodyAnchor(in frame: CGRect) -> CGPoint {
        let scale = min(frame.width / 320, frame.height / 270)
        return CGPoint(x: frame.midX + 13 * scale, y: frame.midY + 9 * scale)
    }

    private static func ease(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return t*t*t*(t*(t*6-15)+10)
    }
    private static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a+(b-a)*t }
    private static func curve(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, _ t: Double) -> CGPoint {
        let u = 1-t
        return CGPoint(x: a.x*u*u*u + 3*b.x*u*u*t + 3*c.x*u*t*t + d.x*t*t*t,
                       y: a.y*u*u*u + 3*b.y*u*u*t + 3*c.y*u*t*t + d.y*t*t*t)
    }
    static func pose(board: CGRect, restingFrame: CGRect, style: BloomVictoryStyle, time: Double) -> Pose {
        let dock = bodyAnchor(in: restingFrame)
        if style.isInPlace {
            let t=min(1,max(0,time/style.duration))
            let phase=style == .doubleHop ? (t<0.55 ? t/0.55:(t-0.55)/0.45):t
            let height=min(16,restingFrame.height*0.18)*(style == .doubleHop && t>=0.55 ? 0.65:1)
            let lift=height*pow(sin(.pi*phase),2)
            let joy=ease(time/225)
            return Pose(position:.init(x:dock.x,y:dock.y-lift),size:restingFrame.size,
                        rotation:0,inflation:1-joy,joy:joy)
        }
        let width = min(108, max(58, board.width*0.34))
        let swimSize = CGSize(width: width, height: width*270/320)
        func point(_ t: Double) -> CGPoint {
            let unit = style.position(t)
            return CGPoint(x: board.minX+unit.x*board.width, y: board.minY+unit.y*board.height)
        }
        let depart = BloomVictoryStyle.departureDuration
        let returnAt = depart+style.swimDuration
        let position: CGPoint
        let size: CGSize
        var rotation = 0.0
        if time <= depart {
            let t = ease(time/depart), end = point(0)
            position = curve(dock, CGPoint(x:dock.x-35,y:dock.y+25),
                             CGPoint(x:end.x+25,y:end.y-35), end, t)
            size = CGSize(width:mix(restingFrame.width,swimSize.width,t), height:mix(restingFrame.height,swimSize.height,t))
        } else if time < returnAt {
            // Ease into/out of the authored loop so all joins have zero velocity.
            let t = ease((time-depart)/style.swimDuration)
            position = point(t)
            size = swimSize
            let tilt = style == .bob ? 0.08 : style == .drift ? 0.10 : 0.16
            rotation = sin(t * .pi * 2)*tilt
            if style == .bubbleSpin { rotation += ease((t-0.34)/0.39) * .pi * 2 }
        } else {
            let t = ease((time-returnAt)/BloomVictoryStyle.returnDuration), start = point(1)
            position = curve(start, CGPoint(x:start.x+30,y:start.y-45),
                             CGPoint(x:dock.x-18,y:dock.y+35), dock, t)
            size = CGSize(width:mix(swimSize.width,restingFrame.width,t), height:mix(swimSize.height,restingFrame.height,t))
        }
        let deflate = ease(time/275)
        return Pose(position:position,size:size,rotation:rotation,inflation:1-deflate,joy:deflate)
    }

    static func restingPose(in frame: CGRect, happy: Bool, reinflating: Bool, time: Double) -> Pose {
        let inflation = happy ? 0 : reinflating ? ease(time/BloomVictoryStyle.reinflationDuration) : 1
        return Pose(position:bodyAnchor(in:frame),size:frame.size,
                    rotation:0,inflation:inflation,joy:1-inflation)
    }

    static func draw(in context: GraphicsContext, board: CGRect, restingFrame: CGRect,
                     style: BloomVictoryStyle, time: Double, poseTime: Double,
                     happy: Bool, celebrating: Bool, reinflating: Bool = false) {
        let swimming = celebrating && time >= 0 && time < style.duration
        let pose = swimming ? pose(board:board,restingFrame:restingFrame,style:style,time:time)
            : restingPose(in:restingFrame,happy:happy,reinflating:reinflating,time:time)
        if swimming {
            let count = style == .bubbleSpin ? 10 : style == .lap ? 7 : 4
            // Only the wake fades. Puff Puff stays fully visible throughout.
            let fade = min(1,time/90)*min(1,(style.duration-time)/200)
            for i in 1...count {
                let past = max(0,time-Double(i)*32.5)
                let p = self.pose(board:board,restingFrame:restingFrame,style:style,time:past).position
                let r = 1.5+Double(count-i)*0.32
                var bubble = context
                bubble.opacity *= fade*max(0,1-Double(i)/Double(count+1))*0.7
                bubble.stroke(Path(ellipseIn:CGRect(x:p.x-r,y:p.y-r-Double(i)*0.8,width:r*2,height:r*2)),
                              with:.color(Color(red:1,green:0.91,blue:0.59)),lineWidth:1)
            }
            let t = (time-BloomVictoryStyle.departureDuration)/style.swimDuration
            if style == .bubbleSpin && t > 0.43 && t < 0.93 {
                let burst = min(1,(t-0.43)/0.5)
                for i in 0..<18 {
                    let a = Double(i)*2.399, radius = burst*board.width*0.43
                    let x = board.midX+cos(a)*radius
                    let y = board.minY+board.height*0.48+sin(a)*radius-burst*22
                    let r = 1.5+Double(i%3)*0.9
                    var sparkle = context; sparkle.opacity *= (1-burst)*0.8
                    sparkle.stroke(Path(ellipseIn:CGRect(x:x-r,y:y-r,width:r*2,height:r*2)),
                                   with:.color(i.isMultiple(of:2) ? Color(red:1,green:0.82,blue:0.29) : Color(red:0.57,green:0.89,blue:0.83)),lineWidth:1.3)
                }
            }
        }
        var fish = context
        let localAnchor = bodyAnchor(in:CGRect(origin:.zero,size:pose.size))
        fish.translateBy(x:pose.position.x,y:pose.position.y)
        fish.rotate(by:.radians(pose.rotation))
        fish.translateBy(x:-localAnchor.x,y:-localAnchor.y)
        // The same ambient phase supplies fins, eyes and breathing while swimming
        // and at rest; finishing never swaps renderers or restarts the idle clock.
        PipRenderer.drawPose(in:fish,size:pose.size,
                             time:poseTime.truncatingRemainder(dividingBy:PipChoreography.period),
                             inflation:pose.inflation,joy:pose.joy)
    }
}

/// Shared vector pickup artwork. Its clock pauses with the ocean and never grants items.
struct ReefBoostIcon: View {
    var stored = false
    var size: CGFloat = 56
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ReefIcon(stored ? .boostStored : .boostLive, size: size)
            .overlay {
                Canvas { context, bounds in
                    for (i, point) in (stored ? [CGPoint(x: 0.16, y: 0.22), CGPoint(x: 0.84, y: 0.13), CGPoint(x: 0.85, y: 0.77)] : []).enumerated() {
                        let wave = reduceMotion ? 0.6 : (sin(time / 4000 * .pi * 2 + Double(i) * 2.1) + 1) / 2
                        let r = size * (0.025 + 0.025 * wave)
                        let x = point.x * bounds.width, y = point.y * bounds.height
                        var star = Path()
                        star.move(to: CGPoint(x: x, y: y-r))
                        star.addLine(to: CGPoint(x: x+r*0.3, y: y-r*0.3))
                        star.addLine(to: CGPoint(x: x+r, y: y))
                        star.addLine(to: CGPoint(x: x+r*0.3, y: y+r*0.3))
                        star.addLine(to: CGPoint(x: x, y: y+r))
                        star.addLine(to: CGPoint(x: x-r*0.3, y: y+r*0.3))
                        star.addLine(to: CGPoint(x: x-r, y: y))
                        star.addLine(to: CGPoint(x: x-r*0.3, y: y-r*0.3)); star.closeSubpath()
                        var shine = context
                        shine.addFilter(.shadow(color: .yellow.opacity(0.5), radius: 3))
                        shine.fill(star, with: .color(Color(hex: 0xFFF5CC).opacity(0.55 + wave*0.45)))
                    }
                }.allowsHitTesting(false)
            }.accessibilityHidden(true)
    }
}
struct BloomLifeGiftBanner: View {
    let gift: BloomLifeGift
    private var reward:BloomBubbleReward { .forGift(gift) }
    var body: some View {
        HStack(spacing: 10) {
            if gift == .refill {ReefIcon(.life,size:40)}
            else {ReefBoostIcon(stored: gift == .stored)}
            VStack(alignment: .leading, spacing: 3) {
                Text(reward.title).reefFont(size: 21, weight: .semibold)
                if let detail=reward.detail {Text(detail).reefFont(size: 12)}
            }
        }.foregroundStyle(ReefTheme.gold)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(reward.accessibility)
    }
}
