import SwiftUI

/// A short, illustrated introduction. It never spends resources or starts a putt.
struct ReefIntroView: View {
    let kind: ReefIntroKind
    let onFinish: () -> Bool
    @State private var page = 0
    @State private var saveFailed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var count: Int { kind == .trail ? 3 : 2 }
    private var scene: Int { kind == .trail ? page : page + 3 }
    private var title: String {
        ["Find home", "Play Bloom for Glow", "Win bonuses", "Putt Puff Puff home", "Explore for an easier putt"][scene]
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button("Skip", action: finish).buttonStyle(ReefButtonStyle(kind: .quiet))
                }
                ScrollView {
                    VStack(spacing: 20) {
                        ReefIntroArt(scene: scene)
                            .frame(height: min(280, max(170, geometry.size.height * 0.38)))
                            .accessibilityHidden(true)
                        Text(title).reefFont(.title2, weight: .semibold)
                            .accessibilityAddTraits(.isHeader)
                        explanation
                    }
                    .frame(maxWidth: .infinity).padding(.horizontal, 8).padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                .id(page)
                .simultaneousGesture(DragGesture(minimumDistance: 35).onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                    changePage(value.translation.width < 0 ? 1 : -1)
                })
                HStack(spacing: 10) {
                    ForEach(0..<count, id: \.self) { index in
                        Circle().fill(index == page ? ReefTheme.cyan : ReefTheme.bone.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Slide \(page + 1) of \(count)")
                if saveFailed {
                    Text("Couldn't save. Please try again.").reefFont(size: 13)
                }
                HStack(spacing: 12) {
                    if page > 0 {
                        Button { changePage(-1) } label: {
                            Image(systemName: "chevron.left").frame(width: 44, height: 44)
                        }.buttonStyle(ReefButtonStyle(kind: .quiet)).accessibilityLabel("Previous slide")
                    }
                    Button {
                        if page == count - 1 { finish() } else { changePage(1) }
                    } label: {
                        Text(page < count - 1 ? "Next" : kind == .trail ? "Let's explore" : "Let's putt")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(ReefButtonStyle(filled: true))
                }.padding(.top, 8)
            }
            .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 24)
            .frame(maxWidth: 460).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(ReefTheme.ink)
        .reefFont(.body)
        .multilineTextAlignment(.center)
    }

    @ViewBuilder private var explanation: some View {
        switch scene {
        case 0:
            Text("Explore the path. Complete your tasks.")
            HStack(spacing: 26) {
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        ForEach(0..<3) { _ in IntroTrailAsset(asset: .food).frame(width: 38, height: 48) }
                    }
                    Text("3 snacks").reefFont(.subheadline, weight: .semibold)
                }
                VStack(spacing: 4) {
                    IntroHome().frame(width: 60, height: 48)
                    Text("Find home").reefFont(.subheadline, weight: .semibold)
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel("Tasks: find three snacks and find home")
        case 1:
            Text("Win Bloom to earn Glow.")
            Text("Light the path. Open chests.").foregroundStyle(ReefTheme.muted)
        case 2:
            Text("Finish your tasks, then play Bonus putt.")
            Text("Fewer putts, more treasure.").foregroundStyle(ReefTheme.muted)
        case 3:
            Text("Pull back to aim. Release to putt.")
            ReefIconLabel("Each putt uses 1 shot", .shot, size: 32).reefFont(.subheadline)
            Text("6 putts per round. Home in 4 or fewer wins bonuses. A hole in one wins them all.")
                .reefFont(.subheadline).foregroundStyle(ReefTheme.muted)
        default:
            Text("Cleared obstacles stay gone.")
            ReefIconLabel("Spend 1 changer to steer a current.", .current, size: 38)
                .reefFont(.subheadline)
            Text("Retry or explore more. Collect your best bonuses once to unlock the next reef.")
                .reefFont(.subheadline).foregroundStyle(ReefTheme.muted)
        }
    }
    private func changePage(_ step: Int) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            page = min(count - 1, max(0, page + step))
        }
    }
    private func finish() { saveFailed = !onFinish() }
}

private struct IntroTrailAsset: View {
    let asset: TrailArt.Asset
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Canvas { context, size in
            TrailArt.draw(asset, in: context, at: .init(x: size.width / 2, y: size.height / 2),
                          size: min(size.width, size.height), time: reduceMotion ? 0 : time)
        }
    }
}

private struct IntroHome: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 280
            CoralHomeArt.draw(in: context, at: .init(x: size.width / 2, y: size.height / 2 + 77 * scale),
                              scale: scale, open: true)
        }
    }
}

private struct ReefIntroArt: View {
    let scene: Int
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 320, geometry.size.height / 260)
            ZStack {
                Circle().fill(ReefTheme.glint.opacity(0.13)).blur(radius: 18)
                    .frame(width: 245, height: 245)
                if scene == 1 { bloomArt } else { pathArt }
            }
            .frame(width: 320, height: 260)
            .scaleEffect(scale)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }.allowsHitTesting(false)
    }

    private var bloomArt: some View {
        ZStack {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(43), spacing: 4), count: 3), spacing: 5) {
                ForEach(0..<9) { index in
                    CoralArt(species: CoralSpecies(rawValue: index % 3)!, lit: index != 0, seed: Double(index))
                        .frame(width: 43, height: 43)
                }
            }.frame(width: 145).position(x: 88, y: 87)
            Image(systemName: "arrow.down.right").font(.system(size: 30, weight: .light))
                .foregroundStyle(ReefTheme.cyan).position(x: 167, y: 157)
            ReefIcon(.glow, size: 76).position(x: 248, y: 62)
            CoralArt(species: .rosyFan).frame(width: 80, height: 80).position(x: 77, y: 221)
            IntroTrailAsset(asset: .chestMint).frame(width: 130, height: 130).position(x: 241, y: 204)
            ReefIcon(.glowKey, size: 65).rotationEffect(.degrees(18)).position(x: 235, y: 142)
        }
    }

    private var pathArt: some View {
        ZStack {
            Canvas { context, _ in
                var path = Path()
                path.move(to: .init(x: 60, y: 220))
                path.addCurve(to: .init(x: 243, y: 85), control1: .init(x: 300, y: 223), control2: .init(x: 85, y: 65))
                context.stroke(path, with: .color(ReefTheme.cyan.opacity(0.15)),
                               style: StrokeStyle(lineWidth: 52, lineCap: .round))
                context.stroke(path, with: .color(ReefTheme.glint.opacity(0.7)),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 10]))
            }
            CoralArt(species: .rosyFan).frame(width: 69, height: 69).position(x: 47, y: 129)
            CoralArt(species: .honeyCups).frame(width: 85, height: 85).position(x: 281, y: 215)
            IntroHome().frame(width: 130, height: 130).position(x: 247, y: 61)
            if scene == 0 {
                ForEach(0..<3) { index in
                    IntroTrailAsset(asset: .food).frame(width: 51, height: 51)
                        .position(x: [159.0, 180.0, 159.0][index], y: [199.0, 142.0, 89.0][index])
                }
            } else if scene == 4 {
                IntroTrailAsset(asset: .kelpForest).frame(width: 83, height: 83)
                    .opacity(0.3).position(x: 176, y: 163)
                Image(systemName: "checkmark").font(.system(size: 25, weight: .bold))
                    .foregroundStyle(ReefTheme.cyan).position(x: 176, y: 152)
                ReefIcon(.current, size: 65).position(x: 116, y: 61)
                Image(systemName: "arrow.up.right").font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(ReefTheme.cyan).position(x: 204, y: 112)
            } else if scene == 3 {
                Image(systemName: "arrow.down.left").font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ReefTheme.gold).position(x: 32, y: 242)
                ReefIcon(.shot, size: 55).position(x: 178, y: 157)
            } else {
                ReefIcon(.hint, size: 55).position(x: 135, y: 78)
                ReefIcon(.glow, size: 50).position(x: 175, y: 144)
                ReefIcon(.shot, size: 48).position(x: 233, y: 160)
            }
            PipPoseArtwork(inflation: scene == 3 ? 0.65 : 0, joy: scene == 3 ? 0 : 1,
                           time: reduceMotion ? 0 : time)
                .frame(width: 115, height: 95).position(x: 66, y: 204)
        }
    }
}
