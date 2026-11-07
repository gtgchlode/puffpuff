import SwiftUI

/// Exploration uses the saved course coordinates, viewed from inside each cove.
/// The bonus round keeps its separate overview and physics unchanged.
struct ReefQuestView: View {
    let progress: FirstReefProgress
    let departure: FirstReefProgress?
    let journey: ReefJourney?
    let elapsed: Double
    let time: Double
    let reduceMotion: Bool
    let enabled: Bool
    let onVisit: (FirstReef.Destination) -> Void
    var onMap: () -> Void = {}

    static func duration(_ journey: ReefJourney) -> Double {
        if let id=journey.coveDiscovery,let object=ReefCove.objects(in:journey.outcome.location ?? "start").first(where:{$0.id==id}) {return CoveActionTiming(object).duration}
        return min(2.4,max(1.8,journey.duration*1.35+0.45))
    }
    static func areaName(_ id: String) -> String {
        switch id {
        case "start": "Lagoon edge"
        case "south": "Bubble fork"
        case "food-sand": "Sandy shallows"
        case "sand": "Sand drift"
        case "lower": "Coral crossing"
        case "kelp": "Kelp grove"
        case "food-garden": "Coral garden"
        case "enemy": "Fish passage"
        case "north": "Sunbeam glade"
        case "food-middle": "Honey garden"
        case "home": "Coral cottage"
        case "hint-shell": "Shell nook"
        case "shot-pearl": "Pearl pocket"
        case "coral-cache": "Golden grotto"
        case "ribbon-cove": "Ribbon cove"
        case "ribbon-kelp": "Tangled channel"
        case "shell-shelf": "Shell shelf"
        case "shell-sand": "Hidden sandbank"
        case "fin-lookout": "Fin lookout"
        case "fin-school": "Homeward current"
        case "frond-cache": "Frond hollow"
        case "lantern-cache": "Buried lantern"
        case "pearl-cache": "Pearl hideaway"
        default: "Quiet cove"
        }
    }

    private var location: String { progress.location ?? "start" }
    private var exits: [FirstReef.Destination] {
        FirstReef.neighbors(location, state: progress).filter {
            !FirstReef.isBlocked(location, state: progress) || progress.visited?.contains($0) == true
        }.map(FirstReef.node)
    }

    var body: some View {
        GeometryReader { geometry in
            let scene = ReefQuestFrame(progress: progress, journey: journey, elapsed: elapsed,
                                       size: geometry.size, reduceMotion: reduceMotion)
            ZStack {
                Canvas { context, size in
                    ReefQuestArt.draw(in: context, size: size, scene: scene, progress: progress,
                                      departure: departure, journey: journey, time: time,
                                      reduceMotion: reduceMotion)
                }.accessibilityHidden(true)
                if journey == nil {
                    if FirstReef.isBlocked(location, state: progress) {
                        let destination = FirstReef.node(location)
                        let center = scene.project(destination.point + ReefPoint(x: 0, y: -27))
                        let actionY = max(41, center.y - 50 * scene.scale - 41)
                        let actionX = actionY < 161 ? max(center.x, min(geometry.size.width - 100, 208)) : center.x
                        Button { onVisit(destination) } label: {
                            Color.clear.frame(width: 100 * scene.scale, height: 100 * scene.scale)
                                .contentShape(Ellipse())
                        }.buttonStyle(.plain).position(center)
                            .accessibilityHidden(true).disabled(!enabled)
                        Button { onVisit(destination) } label: {
                            ReefClearanceLabel(destination: destination, cost: destination.glowCost)
                        }
                        .buttonStyle(ReefButtonStyle(kind: .coral))
                        // Keep the action above its artwork and away from Puff Puff below.
                        .position(x: actionX, y: actionY)
                        .accessibilityLabel("\(destination.actionLabel), \(destination.glowCost) Glow")
                        .accessibilityHint(destination.kind == .treasure ? "Spends Glow to uncover this hidden find." : "Spends Glow to open this passage and light its corals.")
                        .disabled(!enabled)
                    }
                    // Retreat arrows stay above obstacle hit areas and are always usable.
                    ForEach(Array(exits.enumerated()), id: \.element.id) { index, destination in
                        exitButton(destination)
                            .position(exitPosition(index, size: geometry.size))
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                ReefMiniMap(progress: journey == nil ? progress : departure ?? progress,
                            position: scene.position, onExpand: onMap)
                    .padding(8)
            }
            .clipped()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Self.areaName(location))
        }
    }

    private func exitButton(_ destination: FirstReef.Destination) -> some View {
        let known = progress.visited?.contains(destination.id) == true
        let cost = FirstReef.cost(to: destination, from: progress)
        let delta = destination.point - progress.position
        return Button { onVisit(destination) } label: {
            VStack(spacing: 5) {
                ZStack {
                    SeaGlassShape(seed: Double(destination.id.count))
                        .fill(ReefTheme.glass.opacity(0.88))
                    SeaGlassShape(seed: Double(destination.id.count))
                        .stroke(ReefTheme.glint.opacity(0.85), lineWidth: 1.5)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .rotationEffect(.radians(atan2(delta.y, delta.x) + .pi / 2))
                }.frame(width: 44, height: 44)
                if cost > 0 {
                    ReefClearanceLabel(destination: destination, cost: cost, compact: true)
                } else {
                    Text(known ? Self.areaName(destination.id) : "Explore")
                        .reefFont(size: 11, weight: .semibold).lineLimit(1).minimumScaleFactor(0.85)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(MembraneShape().fill(ReefTheme.glass.opacity(0.94)))
                }
            }.frame(width: cost > 0 ? 156 : 132, height: cost > 0 ? 116 : 88)
        }
        .buttonStyle(ReefButtonStyle(kind: .navigation))
        .disabled(!enabled)
        .accessibilityLabel(cost > 0 ? "\(destination.actionLabel), \(cost) Glow" : known ? "Swim to \(Self.areaName(destination.id))" : "Explore an unknown path")
    }

    /// Separate adjacent exits into eight shore positions, keeping targets clear of the fish.
    private func exitPosition(_ index: Int, size: CGSize) -> CGPoint {
        var used = Set<Int>()
        var chosen = 0
        for destination in exits.prefix(index + 1) {
            let delta = destination.point - progress.position
            let angle = atan2(delta.y, delta.x)
            // Keep the upper-left shore free for the little explored-area chart.
            chosen = (0..<8).filter { $0 != 5 && !used.contains($0) }.min {
                cos(Double($0) * .pi / 4 - angle) > cos(Double($1) * .pi / 4 - angle)
            } ?? 0
            used.insert(chosen)
        }
        let angle = Double(chosen) * .pi / 4
        // Leave room for the padded labels as well as the arrow's touch target.
        let paid = FirstReef.cost(to: exits[index], from: progress) > 0
        var x = size.width / 2 + cos(angle) * max(40, size.width / 2 - (paid ? 86 : 74))
        if chosen == 6 { x = max(x, min(size.width - (paid ? 86 : 74), paid ? 194 : 182)) }
        return CGPoint(x: x,
                       y: size.height / 2 + sin(angle) * max(45, size.height / 2 - (paid ? 68 : 54)))
    }
}

/// Action and price stay together, including on a return path to a known blockage.
private struct ReefClearanceLabel: View {
    let destination: FirstReef.Destination
    let cost: Int
    var compact = false

    var body: some View {
        VStack(spacing: 4) {
            Text(destination.actionLabel)
                .reefFont(size: compact ? 11 : 13, weight: .semibold)
                .lineLimit(2).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            ReefIconLabel("\(cost) Glow", .glow, size: 22)
                .reefFont(size: 12, weight: .medium)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(width: compact ? 156 : 184, height: 66)
        .background(MembraneShape().fill(ReefTheme.glass.opacity(0.96)))
        .overlay(MembraneShape().stroke(ReefTheme.glint.opacity(0.75), lineWidth: 1))
    }
}

struct ReefQuestFrame {
    let scale: Double
    let size: CGSize
    let position: ReefPoint
    let camera: ReefPoint
    let travel: Double
    let landing: Double
    let frame: ReefFlightFrame?

    init(progress: FirstReefProgress, journey: ReefJourney?, elapsed: Double, size: CGSize, reduceMotion: Bool) {
        self.size = size
        scale = size.width / 215
        let duration = journey.map(ReefQuestView.duration) ?? 0
        travel = journey == nil || reduceMotion ? 1 : min(1, max(0, elapsed / duration))
        let eased = travel * travel * travel * (travel * (travel * 6 - 15) + 10)
        let playback = (journey?.duration ?? 0) * eased
        frame = journey?.frame(at: playback)
        position = frame?.position ?? progress.position
        let behind = max(0, playback - 0.12 * sin(travel * .pi))
        let follow = journey?.frame(at: behind).position ?? position
        camera = follow + ReefPoint(x: 0, y: -15)
        landing = reduceMotion ? 2 : journey == nil ? 2 : max(0, elapsed - duration)
    }

    func project(_ point: ReefPoint) -> CGPoint {
        CGPoint(x: size.width / 2 + (point.x - camera.x) * scale,
                y: size.height / 2 + (point.y - camera.y) * scale)
    }
}

/// Bloom-earned Glow wakes the coral beds along the passage that was cleared.
/// Lighting derives from saved clearances; it cannot charge or grant anything.
enum ReefLight {
    static func isLit(_ area: String, in state: FirstReefProgress) -> Bool {
        if let searches=state.coveSearches {return searches.contains(where: { $0.hasPrefix("\(area):") })}
        if state.treasures.contains(area) { return true }
        switch area {
        case "ribbon-cove", "ribbon-kelp", "frond-cache": return state.cleared.contains("ribbon-kelp")
        case "shell-shelf", "shell-sand", "lantern-cache": return state.cleared.contains("shell-sand")
        case "fin-lookout", "fin-school", "pearl-cache": return state.cleared.contains("fin-school")
        case "start", "south": return true
        case "sand", "food-sand", "hint-shell", "dead-end": return state.cleared.contains("sand")
        case "kelp", "food-garden", "food-middle", "coral-cache": return state.cleared.contains("kelp")
        case "enemy", "shot-pearl": return state.cleared.contains("enemy")
        case "home": return !state.cleared.isDisjoint(with: ["kelp", "enemy"])
        default: return !state.cleared.isEmpty
        }
    }

    static func amount(_ area: String, from before: FirstReefProgress, to after: FirstReefProgress, reveal: Double) -> Double {
        let a = isLit(area, in: before) ? 1.0 : 0.0
        let b = isLit(area, in: after) ? 1.0 : 0.0
        let t = min(1, max(0, reveal))
        return a + (b - a) * t * t * (3 - 2 * t)
    }
}

enum ReefQuestArt {
    static func draw(in context: GraphicsContext, size: CGSize, scene: ReefQuestFrame,
                     progress: FirstReefProgress, departure: FirstReefProgress?, journey: ReefJourney?,
                     time: Double, reduceMotion: Bool) {
        let bounds = Path(CGRect(origin: .zero, size: size))
        context.fill(bounds, with: .linearGradient(Gradient(colors: [ReefTheme.deep, ReefTheme.glass, ReefTheme.deep]),
                                                   startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
        var world = context
        world.translateBy(x: size.width / 2, y: size.height / 2)
        world.scaleBy(x: scene.scale, y: scene.scale)
        world.translateBy(x: -scene.camera.x, y: -scene.camera.y)
        let source = departure ?? progress
        let reveal = reduceMotion || journey?.clearedObstacle == nil ? 1 : scene.travel
        func light(_ id: String) -> Double { ReefLight.amount(id, from: source, to: progress, reveal: reveal) }

        // Large planted islands and open sandy glades; no course outline in exploration.
        for (index, node) in FirstReef.destinations.enumerated() {
            guard abs(node.point.x - scene.camera.x) < 230,
                  abs(node.point.y - scene.camera.y) < size.height / scene.scale / 2 + 130 else { continue }
            let sand = SeaGlassShape(seed: Double(index)).path(in: CGRect(x: node.point.x - 75, y: node.point.y - 46, width: 150, height: 120))
            world.fill(sand, with: .color(ReefTheme.sand.opacity(0.23)))
            for plant in 0..<5 {
                let angle = Double(plant) * 1.256 + Double(index % 3) * 0.43
                let point = node.point + ReefPoint(x: cos(angle) * 90, y: sin(angle) * 70)
                let species = CoralSpecies.allCases[(index + plant) % 3]
                coral(species, in: world, at: point, size: 43 + Double((index + plant) % 3) * 12,
                      time: time, seed: Double(index * 5 + plant), moving: !reduceMotion,
                      light: light(node.id))
            }
            if ["kelp", "hint-shell", "enemy"].contains(node.id) {
                var grove = world; grove.opacity = 0.65
                TrailArt.draw(.kelpForest, in: grove, at: CGPoint(x: node.point.x - 100, y: node.point.y - 38), size: 145, time: time)
                TrailArt.draw(.kelpForest, in: grove, at: CGPoint(x: node.point.x + 102, y: node.point.y + 42), size: 120, time: time)
            }
        }
        var caustics = context; caustics.opacity = 0.55
        WaterDrawing.caustics(in: caustics, size: size, time: time, strength: 0.5)

        // A few bubbles invite a local choice without drawing the whole network.
        let current = source.location ?? "start"
        if journey == nil {
            for id in FirstReef.neighbors(current, state: source)
            where !FirstReef.isBlocked(current, state: source) || source.visited?.contains(id) == true {
                let delta = FirstReef.node(id).point - source.position
                let unit = delta * (1 / max(1, delta.length))
                for n in 0..<4 {
                    let p = source.position + unit * (38 + Double(n) * 12)
                    let bob = reduceMotion ? 0 : sin(time / 2000 + Double(n)) * 1.2
                    world.stroke(circle(p + ReefPoint(x: 0, y: bob), 1.4 + Double(n % 2)),
                                 with: .color(ReefTheme.glint.opacity(0.8)), lineWidth: 0.7)
                }
            }
        }
        let revealed = scene.travel < 0.7 ? source.visited ?? ["start"] : progress.visited ?? ["start"]
        // Each close-up cove owns its blocker/find. Nearby graph coordinates must
        // not pile another cove's cottage, fish and treasure over this interaction.
        for node in FirstReef.destinations where revealed.contains(node.id)
            && (node.id == progress.location || (journey != nil && node.id == source.location)) {
            let p = node.point + ReefPoint(x: 0, y: -27)
            switch node.kind {
            case .clearance:
                if !progress.cleared.contains(node.id) || journey?.clearedObstacle == node.id && scene.travel < 0.7 {
                    let asset: TrailArt.Asset = node.barrierKind == .kelp ? .kelpForest : node.barrierKind == .sand ? .sandpit : .enemySchool
                    TrailArt.draw(asset, in: world, at: CGPoint(x: p.x, y: p.y), size: 100, time: time)
                }
            case .treasure:
                let found = (scene.frame?.treasures ?? progress.treasures).contains(node.id)
                let asset = node.chestArt(open: found)
                TrailArt.draw(asset, in: world, at: CGPoint(x: p.x + (found ? 0 : 24), y: p.y + (found ? 0 : 10)), size: found ? 70 : 48, time: time)
                if !found {
                    let barrier: TrailArt.Asset = node.barrierKind == .kelp ? .kelpForest : node.barrierKind == .sand ? .sandpit : .enemySchool
                    TrailArt.draw(barrier, in: world, at: CGPoint(x: p.x - 7, y: p.y), size: 90, time: time)
                }
            case .food:
                if !(scene.frame?.food ?? progress.food).contains(node.id) {
                    TrailArt.draw(.food, in: world, at: CGPoint(x: p.x, y: p.y), size: 68, time: time)
                }
            case .home:
                CoralHomeArt.draw(in: world, at: CGPoint(x: node.point.x, y: node.point.y), scale: 0.47, open: progress.food.count == 3)
            case .path: break
            }
        }

        // Darkness belongs to the reef, not the controls. Coral beds open pools
        // of visibility; Puff Puff carries a small halo to keep dark routes usable.
        context.drawLayer { shade in
            shade.fill(bounds, with: .color(ReefTheme.abyss.opacity(0.9)))
            shade.blendMode = .destinationOut
            for node in FirstReef.destinations where light(node.id) > 0 {
                let center = scene.project(node.point)
                let radius = 108 * scene.scale
                guard center.x > -radius, center.x < size.width + radius,
                      center.y > -radius, center.y < size.height + radius else { continue }
                let glow = Gradient(stops: [
                    .init(color: .white.opacity(light(node.id)), location: 0),
                    .init(color: .white.opacity(light(node.id) * 0.92), location: 0.45),
                    .init(color: .clear, location: 1)
                ])
                shade.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                           with: .radialGradient(glow, center: center, startRadius: 0, endRadius: radius))
            }
            let halo = scene.project(scene.position + ReefPoint(x: 0, y: 15))
            shade.fill(bounds, with: .radialGradient(Gradient(colors: [.white.opacity(0.54), .clear]),
                                                      center: halo, startRadius: 8, endRadius: 84 * scene.scale))
        }
        // The coral itself is the light source: soft halos and tiny bright tips.
        for (index, node) in FirstReef.destinations.enumerated() where light(node.id) > 0 {
            guard abs(node.point.x - scene.camera.x) < 230,
                  abs(node.point.y - scene.camera.y) < size.height / scene.scale / 2 + 130 else { continue }
            for plant in 0..<5 {
                let angle = Double(plant) * 1.256 + Double(index % 3) * 0.43
                let point = node.point + ReefPoint(x: cos(angle) * 90, y: sin(angle) * 70 - 24)
                let pulse = reduceMotion ? 1 : 0.88 + sin(time / 8000 * .pi * 2 + Double(plant)) * 0.12
                let strength = light(node.id) * pulse
                world.fill(circle(point, 25), with: .radialGradient(Gradient(colors: [ReefTheme.honey.opacity(0.23 * strength), .clear]),
                                                                    center: CGPoint(x: point.x, y: point.y), startRadius: 0, endRadius: 25))
                world.fill(circle(point, 1.3), with: .color(ReefTheme.bloom.opacity(0.85 * strength)))
            }
        }
        if let cleared = journey?.clearedObstacle, !reduceMotion, scene.travel < 1 {
            let origin = FirstReef.node(cleared).point
            let radius = 12 + scene.travel * 120
            world.stroke(circle(origin, radius), with: .color(ReefTheme.honey.opacity(sin(scene.travel * .pi) * 0.8)), lineWidth: 1.5)
        }
        let arrived = progress.completed && progress.location == "home"
        let leaving = journey != nil && departure?.completed == true && departure?.location == "home"
        let emerge = leaving ? min(1, scene.travel / 0.25) : 1
        let enter = arrived ? ReefMotion.segment(scene.landing * 1000, from: 550, to: 1400) : 0
        var fishPoint = scene.position + ReefPoint(x: 0, y: 21 * (1 - enter) * emerge)
        if !reduceMotion { fishPoint.y += sin(time / 8000 * .pi * 2) * 1.2 * (1 - enter) }
        let fishScale = (1 - enter * 0.78) * (0.22 + 0.78 * emerge)
        let inflation = arrived ? (scene.travel < 1 ? max(0, (scene.travel - 0.65) / 0.35) : max(0, 1 - scene.landing / 0.65)) : 0
        if journey != nil && !reduceMotion && scene.travel < 1 {
            for n in 1...5 {
                let p = fishPoint + ReefPoint(x: -Double(n) * 7, y: sin(Double(n)) * 3)
                world.stroke(circle(p, 0.6 + Double(5 - n) * 0.25), with: .color(ReefTheme.glint.opacity(0.65)), lineWidth: 0.7)
            }
        }
        var fish = world
        fish.translateBy(x: fishPoint.x, y: fishPoint.y)
        fish.rotate(by: .degrees(reduceMotion ? 0 : sin(scene.travel * .pi * 2) * (journey == nil ? 0 : 7)))
        fish.scaleBy(x: fishScale, y: fishScale)
        fish.translateBy(x: -173.0 / 320 * 66, y: -144.0 / 270 * 56)
        PipRenderer.drawPose(in: fish, size: CGSize(width: 66, height: 56), time: time.truncatingRemainder(dividingBy: 8000), inflation: inflation, joy: 1)
        if arrived && enter > 0 { ReefBayArt.doorLip(in: world, at: FirstReef.home) }

        // Soft water at the perimeter gives the area depth and keeps the next cove hidden.
        context.fill(bounds, with: .radialGradient(Gradient(stops: [
            .init(color: .clear, location: 0.45), .init(color: ReefTheme.abyss.opacity(0.35), location: 1)
        ]), center: CGPoint(x: size.width / 2, y: size.height / 2), startRadius: 0, endRadius: max(size.width, size.height) * 0.65))
        for n in 0..<18 {
            let x = WaterDrawing.seed(n, salt: 54) * size.width
            let y = (WaterDrawing.seed(n, salt: 61) * size.height - time / 1400).truncatingRemainder(dividingBy: max(1, size.height))
            context.fill(Path(ellipseIn: CGRect(x: x, y: y < 0 ? y + size.height : y, width: n % 3 == 0 ? 2 : 1, height: n % 3 == 0 ? 2 : 1)), with: .color(ReefTheme.glint.opacity(0.75)))
        }
    }

    private static func circle(_ point: ReefPoint, _ radius: Double) -> Path {
        Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }
    static func coral(_ species: CoralSpecies, in context: GraphicsContext, at point: ReefPoint,
                              size: Double, time: Double, seed: Double, moving: Bool, light: Double) {
        var c = context
        c.translateBy(x: point.x, y: point.y)
        c.rotate(by: .degrees(moving ? sin(time / 8000 * .pi * 2 + seed) * 1.7 * light : 0))
        c.scaleBy(x: size / 100, y: size / 100)
        c.translateBy(x: -50, y: -87)
        let color = CoralArt.blend(0x385B60, species.color, light)
        c.fill(species.left, with: .color(color.opacity(0.85)))
        c.fill(species.right, with: .color(color.opacity(0.85)))
        c.fill(species.body, with: .color(color))
        c.stroke(species.veins, with: .color(CoralArt.blend(0x466970, species.tip, light)), style: .init(lineWidth: 2.5, lineCap: .round))
    }
}
