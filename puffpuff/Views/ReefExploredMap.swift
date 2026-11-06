import SwiftUI

/// This chart contains reached places only. It never uses visibleIDs, which
/// also includes the next unexplored choices, or the golf renderer's full course.
struct ReefExploredChart {
    let nodes: [FirstReef.Destination]
    let lanes: [FirstReef.Lane]
    let bounds: CGRect

    init(progress: FirstReefProgress, position: ReefPoint) {
        let visited = progress.visited ?? ["start"]
        nodes = FirstReef.destinations.filter { visited.contains($0.id) }
        lanes = FirstReef.activeLanes(progress).filter { visited.contains($0.a) && visited.contains($0.b) }
        let points = nodes.map(\.point) + lanes.flatMap(\.points) + [position]
        let minX = points.map(\.x).min() ?? position.x
        let maxX = points.map(\.x).max() ?? position.x
        let minY = points.map(\.y).min() ?? position.y
        let maxY = points.map(\.y).max() ?? position.y
        let width = max(140, maxX - minX + 70)
        let height = max(160, maxY - minY + 80)
        bounds = CGRect(x: (minX + maxX - width) / 2, y: (minY + maxY - height) / 2,
                        width: width, height: height)
    }

    func point(_ point: ReefPoint, in size: CGSize) -> CGPoint {
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        return CGPoint(x: size.width / 2 + (point.x - bounds.midX) * scale,
                       y: size.height / 2 + (point.y - bounds.midY) * scale)
    }
}

struct ReefExploredMap: View {
    let progress: FirstReefProgress
    var position: ReefPoint? = nil
    var compact = false
    var selectedID: String? = nil

    var body: some View {
        Canvas { context, size in
            let position = position ?? progress.position
            let chart = ReefExploredChart(progress: progress, position: position)
            for lane in chart.lanes {
                let lit = ReefLight.isLit(lane.a, in: progress) && ReefLight.isLit(lane.b, in: progress)
                var path = Path()
                path.move(to: chart.point(lane.points[0], in: size))
                for point in lane.points.dropFirst() { path.addLine(to: chart.point(point, in: size)) }
                context.stroke(path, with: .color(ReefTheme.bone.opacity(0.3)), style: .init(lineWidth: compact ? 10 : 30, lineCap: .round, lineJoin: .round))
                context.stroke(path, with: .color(lit ? ReefTheme.sand : Color(hex: 0x143139)), style: .init(lineWidth: compact ? 7 : 24, lineCap: .round, lineJoin: .round))
                context.stroke(path, with: .color(lit ? ReefTheme.cyan.opacity(0.48) : Color(hex: 0x09232C)), style: .init(lineWidth: compact ? 3 : 13, lineCap: .round, lineJoin: .round))
                if !compact && lit {
                    context.stroke(path, with: .color(ReefTheme.glint.opacity(0.85)), style: .init(lineWidth: 1.2, lineCap: .round, dash: [1, 7]))
                }
            }
            for node in chart.nodes {
                let lit = ReefLight.isLit(node.id, in: progress)
                let point = chart.point(node.point, in: size)
                let radius = compact ? 3.5 : 14.0
                let island = SeaGlassShape(seed: Double(node.id.count)).path(in: CGRect(x: point.x - radius * 1.6, y: point.y - radius * 1.6, width: radius * 3.2, height: radius * 3.2))
                if lit && !compact {
                    context.fill(circle(point, 28), with: .radialGradient(Gradient(colors: [ReefTheme.honey.opacity(0.4), .clear]), center: point, startRadius: 6, endRadius: 28))
                }
                context.fill(island, with: .color(lit ? ReefTheme.glass : Color(hex: 0x102F38)))
                if compact {
                    let color = node.kind == .treasure ? ReefTheme.gold : node.kind == .food ? ReefTheme.coral : ReefTheme.cyan
                    context.fill(circle(point, radius), with: .color(lit ? color : Color(hex: 0x4B6C73)))
                } else {
                    var symbol = context; symbol.opacity = lit ? 1 : 0.38
                    landmark(node, at: point, in: symbol)
                    if selectedID == node.id {
                        context.stroke(circle(point, 23), with: .color(ReefTheme.gold), style: .init(lineWidth: 1.5, dash: [2, 4]))
                    }
                }
            }
            let here = chart.point(position, in: size)
            let fishSize=compact ? 26.0:58.0
            context.fill(circle(here,compact ? 12:27),with:.radialGradient(Gradient(colors:[ReefTheme.honey.opacity(0.7),.clear]),center:here,startRadius:0,endRadius:compact ? 14:30))
            var fish=context;fish.translateBy(x:here.x-fishSize*173/320,y:here.y-fishSize*144/320)
            PipRenderer.drawPose(in:fish,size:.init(width:fishSize,height:fishSize*270/320),time:0,inflation:0,joy:1)
            for node in chart.nodes where ReefCove.isComplete(node.id,in:progress) {
                let p=chart.point(node.point,in:size)
                let here=node.id == progress.location
                ReefClearArt.checkbox(in:context,at:.init(x:p.x+(compact ? (here ? 12:5):20),
                                                         y:p.y-(compact ? (here ? 10:5):19)),
                                      size:compact ? 10:20)
            }
        }.accessibilityHidden(true)
    }

    private func circle(_ point: CGPoint, _ radius: Double) -> Path {
        Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }

    private func landmark(_ node: FirstReef.Destination, at point: CGPoint, in c: GraphicsContext) {
        switch node.kind {
        case .treasure:
            let found = progress.treasures.contains(node.id)
            let asset = node.chestArt(open: found)
            TrailArt.draw(asset, in: c, at: point, size: 42)
            if found { ReefTreasureArt.draw(ReefTreasureArt.rewards(for:node),in:c,at:point,chestSize:42) }
        case .food:
            TrailArt.draw(.food, in: c, at: point, size: 32)
        case .clearance:
            if progress.cleared.contains(node.id) {
                c.fill(circle(point,5),with:.color(ReefTheme.cyan))
                c.stroke(Path(ellipseIn:CGRect(x:point.x-10,y:point.y-5,width:20,height:10)),
                         with:.color(ReefTheme.glint),lineWidth:1.5)
            } else {
                let asset: TrailArt.Asset = node.barrierKind == .kelp ? .kelpForest : node.barrierKind == .sand ? .sandpit : .enemySchool
                TrailArt.draw(asset, in: c, at: point, size: 44)
            }
        case .home:
            CoralHomeArt.draw(in: c, at: CGPoint(x: point.x, y: point.y + 10), scale: 0.19, open: progress.completed)
        case .path:
            c.fill(circle(point, 4), with: .color(ReefTheme.cyan))
        }
    }
}

struct ReefMiniMap: View {
    let progress: FirstReefProgress
    let position: ReefPoint
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            ReefExploredMap(progress: progress, position: position, compact: true)
                .padding(.horizontal, 14).padding(.vertical, 21)
                .frame(width: 96, height: 120)
                .background(FoldedReefMapPaper())
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ReefTheme.ink)
                        .padding(5).background(Circle().fill(ReefTheme.sand))
                        .padding(6)
                }
        }
        .buttonStyle(ReefButtonStyle(kind: .navigation))
        .accessibilityLabel("Expand explored reef map")
        .accessibilityValue("\(ReefQuestView.areaName(progress.location ?? "start")), \(progress.visited?.count ?? 1) explored areas")
    }
}

/// A small nautical chart: the zigzag silhouette and creases read as paper.
private struct FoldedReefMapPaper: View {
    var body: some View {
        Canvas { c, size in
            func point(_ x: Double, _ y: Double) -> CGPoint { .init(x: x * size.width, y: y * size.height) }
            var outline = Path()
            outline.move(to: point(0.05, 0.14))
            outline.addLine(to: point(0.34, 0.06))
            outline.addLine(to: point(0.65, 0.14))
            outline.addLine(to: point(0.95, 0.06))
            outline.addQuadCurve(to: point(0.94, 0.87), control: point(0.92, 0.47))
            outline.addLine(to: point(0.65, 0.95))
            outline.addLine(to: point(0.34, 0.87))
            outline.addLine(to: point(0.05, 0.95))
            outline.addQuadCurve(to: point(0.05, 0.14), control: point(0.08, 0.53))
            outline.closeSubpath()
            c.addFilter(.shadow(color: ReefTheme.abyss.opacity(0.35), radius: 2, y: 3))
            c.fill(outline, with: .color(Color.adaptive(light: 0xF7E8C5, dark: 0x244953)))
            c.stroke(outline, with: .color(ReefTheme.ink.opacity(0.85)), style: .init(lineWidth: 2, lineJoin: .round))
            var middle = Path()
            middle.move(to: point(0.34, 0.06)); middle.addLine(to: point(0.65, 0.14))
            middle.addLine(to: point(0.65, 0.95)); middle.addLine(to: point(0.34, 0.87)); middle.closeSubpath()
            c.fill(middle, with: .color(ReefTheme.bone.opacity(0.16)))
            for (x, top, bottom) in [(0.34, 0.07, 0.87), (0.65, 0.14, 0.94)] {
                var fold = Path(); fold.move(to: point(x, top)); fold.addLine(to: point(x, bottom))
                c.stroke(fold, with: .color(ReefTheme.gold.opacity(0.32)), style: .init(lineWidth: 1, lineCap: .round))
            }
        }.accessibilityHidden(true)
    }
}

struct ReefExploredMapSheet: View {
    let progress: FirstReefProgress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.oceanTime) private var time
    @State private var selection: String?

    private var selected: String { selection ?? progress.location ?? "start" }
    private var detail: String {
        let node = FirstReef.node(selected)
        if ReefCove.isComplete(selected,in:progress) {
            return selected == progress.location ? "You are here · All clear":"All clear"
        }
        if selected == progress.location { return "You are here" }
        if node.kind == .clearance {
            return progress.cleared.contains(selected) ? node.clearanceResult : "\(node.label) · \(node.glowCost) Glow"
        }
        switch node.kind {
        case .food: return progress.food.contains(selected) ? "Snack collected" : "Snack"
        case .treasure: return progress.treasures.contains(selected) ? "Collected · \(node.treasureReward)" : "\(node.actionLabel) · \(node.glowCost) Glow"
        case .clearance: return node.clearanceResult
        case .home: return progress.completed ? "Home found" : "Home"
        case .path: return ReefLight.isLit(selected, in: progress) ? "Corals glowing" : "Still in shadow"
        }
    }

    var body: some View {
        ZStack {
            OceanBackdrop(time: time).ignoresSafeArea().accessibilityHidden(true)
            VStack(spacing: 8) {
                HStack {
                    Text("Sunbeam Bay").reefFont(size: 24, weight: .semibold, display: true)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .buttonStyle(ReefButtonStyle(kind: .orb)).accessibilityLabel("Close reef map")
                }.padding(.horizontal, 22).padding(.top, 14)
                GeometryReader { geometry in
                    let size = geometry.size
                    let chart = ReefExploredChart(progress: progress, position: progress.position)
                    ZStack {
                        ReefExploredMap(progress: progress, selectedID: selected)
                        ForEach(chart.nodes) { node in
                            Button { selection = node.id } label: { Color.clear.frame(width: 44, height: 44).contentShape(Circle()) }
                                .buttonStyle(ReefButtonStyle(kind: .navigation))
                                .position(chart.point(node.point, in: size))
                                .accessibilityLabel(ReefQuestView.areaName(node.id))
                                .accessibilityValue([node.id == progress.location ? "You are here":"Explored",
                                                     ReefCove.isComplete(node.id,in:progress) ? "All clear":nil].compactMap{$0}.joined(separator:", "))
                                .accessibilityAddTraits(node.id == selected ? [.isSelected] : [])
                        }
                    }
                }.padding(.horizontal, 24)
                VStack(spacing: 3) {
                    Text(ReefQuestView.areaName(selected)).reefFont(size: 19, weight: .semibold)
                    Text(detail).reefFont(size: 12).foregroundStyle(ReefTheme.muted)
                }.frame(minHeight: 52).padding(.bottom, 12)
            }.frame(maxWidth: 480)
        }.foregroundStyle(ReefTheme.ink)
        #if os(macOS)
        .frame(minWidth: 380, idealWidth: 440, minHeight: 620, idealHeight: 720)
        #endif
    }
}
