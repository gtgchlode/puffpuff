import SwiftUI

struct BloomView: View {
    var onHome: () -> Void
    var onPause: () -> Void
    var onOverlay: (Bool) -> Void = { _ in }
    @Environment(ReefStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRules = false
    @State private var showCoralLesson = false
    @State private var lessonKind: CoralPracticeKind = .vertical
    @State private var showHintSupply = false
    @State private var lighting = false
    @State private var showLives = false
    @State private var showRestart = false
    @State private var celebrationOrigin: Int?
    @State private var celebrationID = 0
    @State private var playFishCelebration = false
    @State private var reinflatingLevel: Int?
    @State private var bubbleBurstID = 0
    @AppStorage("puffpuff.celebrationAnimations") private var celebrationAnimations = true
    @AppStorage("puffpuff.tutorial.verticalCoral") private var learnedVerticalCoral = false
    @AppStorage("puffpuff.tutorial.diagonalCoral") private var learnedDiagonalCoral = false
    @AppStorage("puffpuff.tutorial.lineCoral") private var learnedLineCoral = false

    private var victory: BloomVictoryStyle {
        .choose(level:store.puzzle.level,size:store.puzzle.size,
                feature:store.puzzle.feature,pearlTarget:store.puzzle.pearlTarget)
    }
    private var earnedRewards: [BloomBubbleReward] {
        BloomBubbleReward.earned(pearl: store.puzzle.earnedPearl, hint: store.puzzle.earnedHint == true,
                                 shot: store.puzzle.earnedShot == true, gift: store.puzzle.earnedLifeGift,
                                 lighter: store.puzzle.earnedLighter == true, shots: store.puzzle.earnedShots)
    }
    private var reinflating: Bool {
        reinflatingLevel == store.puzzle.level && !store.isComplete && celebrationAnimations && !reduceMotion
    }

    var body: some View {
        ScrollViewReader { scroll in
        ScrollView {
            ReefClock(duration:reinflating ? BloomVictoryStyle.reinflationDuration : victory.duration,
                      paused:(celebrationOrigin == nil && !reinflating) || showRules || showCoralLesson,frameInterval:1.0/30) { time in
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("\(store.puzzle.level)").reefFont(size: 25, weight: .semibold, display: true).foregroundStyle(ReefTheme.ink)
                            .accessibilityLabel("Level \(store.puzzle.level)")
                        Button { showLives = true } label: { BloomLivesStatus(compact: true) }
                            .buttonStyle(ReefButtonStyle(kind: .quiet))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Group {
                        if store.isComplete {
                            Color.clear
                        } else {
                            Button { bubbleBurstID += 1 } label: {
                                Color.clear.contentShape(Ellipse())
                            }.buttonStyle(.plain)
                        }
                    }.frame(width:104,height:88)
                        .anchorPreference(key:BloomFishAnchors.self,value:.bounds) { ["fish":$0] }
                        .accessibilityElement(children:.ignore)
                        .accessibilityLabel(store.isComplete ? "Puff Puff, relaxed and smiling" : "Puff Puff. Tap for bubbles")
                    ReefChestButton(onPresent:onOverlay)
                    ReefPauseButton(action: onPause)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        if store.isComplete {
                            BloomRewardDock(rewards: earnedRewards)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                        VStack(alignment: .leading, spacing: 3) {
                            if !store.isComplete {
                                Text("\(store.puzzle.awake) of \(store.puzzle.coralCount) glowing")
                                    .reefFont(.caption).foregroundStyle(ReefTheme.muted)
                            }
                        }
                        Spacer()
                        }
                        VStack(spacing: 2) {
                            Text("\(store.puzzle.tapsRemaining)")
                                .reefFont(size: 17, weight: .medium).monospacedDigit()
                            Text(store.puzzle.tapsRemaining == 1 ? "tap left" : "taps left")
                                .reefFont(size: 11)
                        }.foregroundStyle(ReefTheme.ink)
                            .frame(width: 70, height: 64)
                            .background(MembraneSurface(tint: ReefTheme.honey, intensity: 0.85, round: true))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(store.puzzle.tapsRemaining) taps remaining out of \(store.puzzle.allowedTaps)")
                        if !store.isComplete {
                        Button { showRules = true } label: { Image(systemName: "questionmark.circle").font(.title3).frame(width: 44, height: 44) }
                            .buttonStyle(ReefButtonStyle(kind: .quiet)).accessibilityLabel("How to play Coral Bloom")
                        }
                    }
                      if store.puzzle.isTutorial && !store.isComplete && !store.isOutOfTaps {
                        VStack(spacing: 7) {
                            Text(store.puzzle.teachingTitle)
                                .reefFont(size: 20, weight: .medium).foregroundStyle(ReefTheme.gold)
                            Text(store.hintMessage ?? store.puzzle.lesson)
                                .reefFont(size: 13).foregroundStyle(ReefTheme.ink)
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        }.padding(.vertical, 4)
                      }
                      CoralBoard(time:time,celebrationOrigin:celebrationOrigin,lighting:$lighting) { index in
                          var transaction = Transaction(animation:nil)
                          transaction.disablesAnimations = true
                          withTransaction(transaction) {
                              celebrationOrigin = index
                              celebrationID += 1
                              reinflatingLevel = nil
                              playFishCelebration = celebrationAnimations && !reduceMotion
                          }
                      }
                      .anchorPreference(key:BloomFishAnchors.self,value:.bounds) { ["board":$0] }

                    if store.isOutOfTaps {
                        retryView
                    }
                    if !store.canPlayBloom {
                        VStack(spacing: 10) {
                            Text(store.canStartBloom ? "Ready to bloom" : "Lives are refilling").reefFont(size: 18, weight: .semibold)
                            BloomLivesStatus()
                            Button("Play") { store.startBloomAttempt() }
                                .buttonStyle(ReefButtonStyle(filled: true)).disabled(!store.canStartBloom)
                            Button("Lives & boosts") { showLives = true }
                                .buttonStyle(ReefButtonStyle(filled: true))
                        }.padding(.vertical, 12)
                    }
                    if !store.isComplete && store.canPlayBloom {
                        VStack(spacing: 4) {
                            Button { lighting.toggle() } label: {
                                ReefIconLabel(lighting ? "Cancel" : "\(store.progress.supplies.lighters)", .lighter)
                            }.buttonStyle(ReefButtonStyle(kind: .quiet))
                                .disabled(store.progress.supplies.lighters == 0)
                                .accessibilityLabel(lighting ? "Cancel lighter" : "Lighter, \(store.progress.supplies.lighters) available")
                                .accessibilityHint("Choose a sleepy coral to keep it glowing for this attempt. Uses one lighter, no taps.")
                            if lighting {
                                Text("Tap a sleepy coral. It stays glowing this attempt.")
                                    .reefFont(size: 12).multilineTextAlignment(.center).foregroundStyle(ReefTheme.gold)
                            }
                        }
                    }

                    if !store.isComplete && !store.isOutOfTaps {
                        if let message = store.hintMessage, !store.puzzle.isTutorial {
                            Text(message).reefFont(size: 12)
                                .foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if [5, 21, 41, 61, 81].contains(store.puzzle.level) {
                            Text(store.puzzle.lesson).reefFont(size: 12)
                                .foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center)
                        } else if store.puzzle.level == 27 && store.puzzle.hasGaps {
                            Text("Gaps are open water. Tap coral to flip its neighbors.")
                                .reefFont(size: 12).foregroundStyle(ReefTheme.muted)
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        }
                        if store.puzzle.level > 1 {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 9) { hintControls; restartControl }
                                VStack(spacing: 4) { hintControls; restartControl }
                            }.buttonStyle(ReefButtonStyle(kind: .quiet))
                        }
                        if showHintSupply && !store.puzzle.isTutorial && store.progress.hints == 0 {
                            BloomHintSupply { showHintSupply = false }
                        }
                    }
                }.id("bloom-board")

                if store.isComplete {
                    VStack(spacing: 14) {
                        if store.puzzle.level < ReefStore.levelLimit {
                            Button { nextPatch(after: time) } label: {
                                Text(store.puzzle.nextLessonLabel)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }.buttonStyle(ReefButtonStyle(filled: true))
                        } else {
                            Text("More reefs soon").reefFont(size: 14).foregroundStyle(ReefTheme.muted)
                            Button("Play again") { _ = store.startFromBeginning() }
                                .buttonStyle(ReefButtonStyle(filled: true))
                        }
                        Button("Home", action: onHome).buttonStyle(ReefButtonStyle(kind: .quiet))
                    }.accessibilityElement(children: .contain)
                        .padding(.vertical, 8)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
                }
            }.padding(.horizontal, 22).padding(.bottom, 28)
                .overlayPreferenceValue(BloomFishAnchors.self) { anchors in
                    GeometryReader { proxy in
                        if let fish = anchors["fish"], let board = anchors["board"] {
                            BloomFishLayer(board:proxy[board],restingFrame:proxy[fish],style:victory,
                                           time:time,happy:store.isComplete,
                                           celebrating:store.isComplete && celebrationOrigin != nil && playFishCelebration && celebrationAnimations,
                                           reinflating:reinflating)
                            if store.isComplete {
                                BloomRewardFlight(rewards: earnedRewards, board: proxy[board],
                                    docks: anchors.reduce(into: [String: CGRect]()) { result, entry in
                                        result[entry.key] = proxy[entry.value]
                                    }, time: celebrationOrigin == nil || reduceMotion ? victory.duration : time,
                                    duration: victory.duration)
                            }
                            if !store.isComplete && bubbleBurstID > 0 && !reduceMotion {
                                BloomTapBubbles(restingFrame: proxy[fish])
                                    .id("\(store.puzzle.level)-bubbles-\(bubbleBurstID)")
                            }
                        }
                    }.allowsHitTesting(false)
                }
                .background(BloomDiscoveryTrigger(ready:store.isComplete && time>=350))
            }.id("\(store.puzzle.level)-\(celebrationID)")
        }.scrollIndicators(.hidden).clipped()
        .onChange(of: store.isOutOfTaps) { _, _ in
            // Keep the actual puzzle in view both when the refill controls
            // appear and when the player resumes with more taps.
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                scroll.scrollTo("bloom-board", anchor: .top)
            }
        }
        .onAppear {
            if store.isOutOfTaps { scroll.scrollTo("bloom-board", anchor: .top) }
            offerCoralLesson()
        }
        .onChange(of: showHintSupply) { _, visible in
            if visible {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    scroll.scrollTo("bloom-board", anchor: .top)
                }
            }
        }
        .onChange(of: store.progress.hints) { _, count in
            if count > 0 { showHintSupply = false }
        }
        .onChange(of: store.puzzle.level) { _, level in
            lighting = false
            showHintSupply = false
            celebrationOrigin = nil
            playFishCelebration = false
            bubbleBurstID = 0
            if reinflatingLevel != level { reinflatingLevel = nil }
            offerCoralLesson()
        }
        .onChange(of: store.isComplete) { _, complete in
            if complete { showHintSupply = false; lighting = false } else { celebrationOrigin = nil }
        }
        .onChange(of: store.puzzle.verticals ?? []) { _, _ in offerCoralLesson() }
        .onChange(of: store.puzzle.stars) { _, _ in offerCoralLesson() }
        .onChange(of: store.puzzle.rowCorals ?? []) { _, _ in offerCoralLesson() }
        .onChange(of: store.puzzle.columnCorals ?? []) { _, _ in offerCoralLesson() }
        .onChange(of: celebrationAnimations) { _, enabled in
            if !enabled { playFishCelebration = false; reinflatingLevel = nil }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { playFishCelebration = false; reinflatingLevel = nil }
        }
        .onChange(of: showRules) { _, value in onOverlay(value || showCoralLesson || showLives || showRestart) }
        .onChange(of: showCoralLesson) { _, value in onOverlay(value || showRules || showLives || showRestart) }
        .onChange(of: showLives) { _, value in onOverlay(value || showRules || showCoralLesson || showRestart) }
        .onChange(of: showRestart) { _, value in onOverlay(value || showRules || showCoralLesson || showLives) }
        .sheet(isPresented: $showRestart) {
            OceanScene {
                VStack(spacing: 22) {
                    Text("Are you sure?").reefFont(size: 28, weight: .semibold)
                    BloomLivesStatus()
                    if store.restartCostsLife {
                        ReefIconLabel("−1", .life, size: 36)
                            .accessibilityLabel("Restarting uses one life")
                    }
                    if !store.canStartBloom {
                        Button {
                            if store.restartPuzzle(usingAdLife: true) { lighting = false; showRestart = false }
                        } label: {
                            VStack(spacing: 4) { Text("Watch an ad"); ReefIconLabel("+1", .life) }
                        }.buttonStyle(ReefButtonStyle(filled: true))
                        Text("Free preview · no ad").reefFont(size: 11).foregroundStyle(ReefTheme.muted)
                    } else {
                        Button("Restart") { if store.restartPuzzle() { lighting = false; showRestart = false } }
                            .buttonStyle(ReefButtonStyle(filled: true))
                    }
                    Button("Keep playing") { showRestart = false }
                        .buttonStyle(ReefButtonStyle(kind: .quiet))
                }.padding(28).frame(maxWidth: 360)
            }.presentationDetents([.medium]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showLives) {
            BloomLivesSheet().presentationDetents([.large]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showCoralLesson, onDismiss: rememberCoralLesson) {
            CoralPractice(kind: lessonKind) { showCoralLesson = false }.id(lessonKind)
                .presentationDetents([.large]).presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showRules) {
            OceanScene {
              VStack(spacing: 20) {
                Image(systemName: "camera.macro").font(.system(size: 48)).foregroundStyle(ReefTheme.coral)
                Text("How to bloom").reefFont(.title2, weight: .heavy)
                Text("Ordinary coral flips itself and its four side neighbors. Marked coral follows its arrows. Wake them all.").multilineTextAlignment(.center)
                Text("Lose a life when you run out of taps or restart. One refills every 5 minutes.").multilineTextAlignment(.center)
                Text("A lighter keeps one chosen coral glowing for this attempt. It uses no taps.").multilineTextAlignment(.center)
                Text("One hint reveals your next tap. Collect hints at patches 5, 10, 15… and with treasure, or get more with a purchase or ad. Tutorials guide you for free.").multilineTextAlignment(.center)
                Text(store.puzzle.lesson).multilineTextAlignment(.center).foregroundStyle(ReefTheme.muted)
                if store.puzzle.hasGaps {
                    Text("Open water has no tile. Neighbor ripples never skip a gap. Whole-line coral reaches across the row or column.")
                        .multilineTextAlignment(.center).foregroundStyle(ReefTheme.muted)
                }
                Text("A bloom earns 3 Glow. Every five wins earn a shot, and each win has a 10% chance of an extra shot. Replays count too.").multilineTextAlignment(.center)
                Button("Got it") { showRules = false }.buttonStyle(ReefButtonStyle(filled: true))
              }.padding(28).frame(maxWidth: 460).foregroundStyle(ReefTheme.ink)
            }.presentationDetents([.large]).presentationDragIndicator(.visible).presentationBackground(.clear)
        }
        }
    }

    private func offerCoralLesson() {
        guard !showCoralLesson, !store.isComplete else { return }
        if !learnedLineCoral && store.puzzle.hasLineCorals { lessonKind = .lines }
        else if !learnedDiagonalCoral && !store.puzzle.stars.isEmpty { lessonKind = .diagonal }
        else if !learnedVerticalCoral && !(store.puzzle.verticals ?? []).isEmpty { lessonKind = .vertical }
        else { return }
        showCoralLesson = true
    }

    private func rememberCoralLesson() {
        switch lessonKind {
        case .vertical: learnedVerticalCoral = true
        case .diagonal: learnedDiagonalCoral = true
        case .lines: learnedLineCoral = true
        }
    }

    private var hintControls: some View {
        HStack(spacing: 3) {
            Button {
                if !store.showHint() { showHintSupply = true }
            } label: {
                ReefIconLabel(store.puzzle.isTutorial ? "Guide" : "Hint · \(store.progress.hints)", .hint)
                    .lineLimit(1).fixedSize(horizontal: true, vertical: false)
            }
            .disabled(store.puzzle.revealedHint != nil)
            .accessibilityLabel(store.puzzle.isTutorial ? "Free tutorial guide" : "Use one hint. \(store.progress.hints) hints available")
            .help(store.puzzle.isTutorial ? "Tutorial guidance is free." : "Uses one hint to reveal your next tap.")
            if !store.puzzle.isTutorial && store.progress.hints == 0 {
                Button { showHintSupply.toggle() } label: { Image(systemName: "plus.circle") }
                    .accessibilityLabel("Get more hints")
            }
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var restartControl: some View {
        Button { showRestart = true } label: {
            Label(restartLabel, systemImage: "arrow.counterclockwise")
                .lineLimit(1).fixedSize(horizontal: true, vertical: false)
        }.accessibilityLabel(restartLabel)
    }

    private var restartLabel: String {
        "Restart"
    }

    private func nextPatch(after time: Double) {
        let level = store.puzzle.level
        // Use the paused-aware playback time, never elapsed wall time. A skipped
        // swim or a reopened completed patch goes straight to the playing pose.
        let watched = celebrationOrigin != nil && playFishCelebration && celebrationAnimations
            && !reduceMotion && time >= victory.duration
        store.nextPuzzle()
        guard store.puzzle.level != level else { return }
        reinflatingLevel = watched && !store.isComplete ? store.puzzle.level : nil
    }

    private var retryView: some View {
        VStack(spacing: 7) {
            Text("More taps?")
                .reefFont(size: 18, weight: .medium).foregroundStyle(ReefTheme.gold)
            HStack(spacing: 9) {
                Button { store.claimFreeTapRefill(source: .purchasePreview) } label: {
                    VStack(spacing: 3) {
                        ReefIconLabel("+\(ReefStore.refillTapCount)", .taps)
                        Text("Free for now").reefFont(size: 11)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(ReefButtonStyle(filled: true))
                    .accessibilityLabel("Buy \(ReefStore.refillTapCount) more taps, free for now")
                Button { store.claimFreeTapRefill(source: .adPreview) } label: {
                    VStack(spacing: 3) {
                        Text("Watch an ad")
                        ReefIconLabel("+\(ReefStore.refillTapCount)", .taps, size: 24).reefFont(size: 11)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(ReefButtonStyle())
                    .accessibilityLabel("Watch an ad for \(ReefStore.refillTapCount) taps, free preview without an ad")
            }
            Text("Free preview · no payment or ad")
                .reefFont(size: 10).foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center)
            Button { showRestart = true } label: {
                Label(restartLabel, systemImage: "arrow.counterclockwise")
            }.buttonStyle(ReefButtonStyle(kind: .quiet))
        }.padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: 350)
            .background(MembraneSurface(tint: ReefTheme.gold, intensity: 0.65))
    }

}

private struct BloomHintSupply: View {
    var close: () -> Void
    @Environment(ReefStore.self) private var store

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment:.trailing) {
                ReefIcon(.hint,size:48).frame(maxWidth:.infinity)
                Button(action:close) {
                    Image(systemName:"xmark").frame(width:44,height:44).contentShape(Circle())
                }.buttonStyle(.plain).accessibilityLabel("Close hint power-ups")
            }.frame(height:56)
            Text("One hint reveals your next tap.")
                .reefFont(size: 12).foregroundStyle(ReefTheme.muted)
            HStack(spacing: 8) {
                Button { store.claimFreeHints(source: .purchasePreview) } label: {
                    VStack(spacing: 3) {
                        Text("Buy \(ReefStore.hintBundleCount) hints")
                        Text("Free for now").reefFont(size: 11)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(ReefButtonStyle(filled: true))
                    .accessibilityLabel("Buy \(ReefStore.hintBundleCount) hints, free preview")
                Button { store.claimFreeHints(source: .adPreview) } label: {
                    VStack(spacing: 3) {
                        Text("Watch an ad")
                        Text("+1 hint").reefFont(size: 11)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(ReefButtonStyle())
                    .accessibilityLabel("Watch an ad for one hint, free preview without an ad")
            }
            Text("Free preview · no payment or ad")
                .reefFont(size: 10).foregroundStyle(ReefTheme.muted)
        }.multilineTextAlignment(.center)
            .padding(.horizontal, 22).padding(.bottom, 22).padding(.top, 16)
            .frame(maxWidth: 350)
            .background(MembraneSurface(tint: ReefTheme.gold, intensity: 0.65))
    }
}

private struct CoralBoard: View {
    let time: Double
    let celebrationOrigin: Int?
    @Binding var lighting: Bool
    let onWin: (Int) -> Void
    @Environment(ReefStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: store.puzzle.size), spacing: 8) {
                ForEach(store.puzzle.cells.indices, id: \.self) { index in
                  if store.puzzle.isGap(index) {
                    Color.clear.aspectRatio(1, contentMode: .fit)
                        .allowsHitTesting(false).accessibilityHidden(true)
                  } else {
                    let phase = celebration(at: index, time: time)
                    CoralCell(lit: store.puzzle.cells[index], stone: store.puzzle.stones.contains(index),
                              current: store.puzzle.currents.contains(index), vertical: store.puzzle.isVertical(index),
                              star: store.puzzle.stars.contains(index),
                              wholeRow: store.puzzle.isRowCoral(index), wholeColumn: store.puzzle.isColumnCoral(index),
                              hint: store.hint == index,
                              seed: Double(index),
                              species: CoralSpecies(rawValue: (index + index / store.puzzle.size) % 3) ?? .peachSprig,
                              bloom: phase.color, swell: phase.swell) {
                        withAnimation(reduceMotion ? nil : ReefMotion.response) {
                            if lighting {
                                if store.lightCoral(index) { lighting = false }
                            } else { store.tapCoral(index) }
                        }
                        if store.isComplete { onWin(index) }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if (store.puzzle.lighterCorals ?? []).contains(index) {
                            ReefIcon(.lighter, size: 19).font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ReefTheme.hintCore).padding(5)
                                .background(SeaGlassShape().fill(ReefTheme.ink)).padding(4)
                                .allowsHitTesting(false).accessibilityHidden(true)
                        }
                    }
                    .disabled(store.isComplete || !store.canPlayBloom || store.puzzle.stones.contains(index)
                              || (lighting ? store.puzzle.cells[index] : store.isOutOfTaps))
                    .accessibilityLabel("Row \(index / store.puzzle.size + 1), column \(index % store.puzzle.size + 1), \(cellDescription(index))")
                  }
                }
            }.padding(12).frame(maxWidth: store.puzzle.size == 1 ? 126 : store.puzzle.size == 2 ? 228 : 320)
                .background {
                    if store.puzzle.hasGaps {
                        BloomReefBed(size: store.puzzle.size, gaps: store.puzzle.gaps ?? [], complete: store.isComplete)
                    } else {
                        MembraneSurface(tint: store.isComplete ? ReefTheme.bloom : ReefTheme.coral, intensity: store.isComplete ? 0.85 : 0.45)
                            .overlay { if store.isComplete { BloomSuccessBackdrop() } }
                    }
                }
                .overlay {
                    if store.isComplete, let origin = celebrationOrigin, !reduceMotion {
                        BloomRipple(time: time, origin: UnitPoint(
                            x: (Double(origin % store.puzzle.size) + 0.5) / Double(store.puzzle.size),
                            y: (Double(origin / store.puzzle.size) + 0.5) / Double(store.puzzle.size)))
                    }
                }
        .sensoryFeedback(.success, trigger: store.isComplete) { _, complete in complete }
    }

    private func celebration(at index: Int, time: Double) -> (color: Double, swell: Double) {
        guard store.isComplete else { return (0, 0) }
        guard let origin = celebrationOrigin, !reduceMotion else { return (1, 0) }
        let dx = Double(index % store.puzzle.size - origin % store.puzzle.size)
        let dy = Double(index / store.puzzle.size - origin / store.puzzle.size)
        let local = time - hypot(dx, dy) * 100
        let glow = ReefMotion.segment(local, from: 70, to: 550)
        let swell = ReefMotion.track(local, [.init(0, 0), .init(90, 0), .init(270, 1, arriving: true), .init(680, 0, arriving: true)])
        return (glow, swell)
    }

    private func cellDescription(_ index: Int) -> String {
        if store.puzzle.stones.contains(index) { return "resting pebble" }
        let kind = store.puzzle.isRowCoral(index) ? "whole row coral" :
            store.puzzle.isColumnCoral(index) ? "whole column coral" : store.puzzle.isVertical(index) ? "up and down coral" :
            store.puzzle.currents.contains(index) ? "left and right coral" : store.puzzle.stars.contains(index) ? "diagonal coral" : "coral"
        return "\(store.isComplete ? "fully bloomed" : store.puzzle.cells[index] ? "glowing" : "sleepy") \(kind)\(store.hint == index ? ", suggested tap" : "")\((store.puzzle.lighterCorals ?? []).contains(index) ? ", stays lit by a lighter" : "")"
    }
}

/// The water bed follows the planted coral footprint, leaving empty slots clear.
struct BloomReefBed: View {
    let size: Int
    let gaps: [Int]
    var complete = false
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, bounds in
            let side = (bounds.width - 24 - CGFloat(size-1)*8)/CGFloat(size)
            var footprint = Path()
            for index in 0..<(size*size) where !gaps.contains(index) {
                let cell = CGRect(x: 12 + CGFloat(index % size)*(side+8),
                                  y: 12 + CGFloat(index / size)*(side+8), width: side, height: side)
                footprint.addPath(SeaGlassShape(seed: Double(index), amplitude: 0.012)
                    .path(in: cell.insetBy(dx: -12, dy: -12)))
            }
            context.fill(footprint, with: .linearGradient(Gradient(colors: [ReefTheme.glass.opacity(0.5),
                (complete ? ReefTheme.bloom : ReefTheme.coral).opacity(0.12)]),
                startPoint: .zero, endPoint: CGPoint(x: bounds.width, y: bounds.height)))
            var water = context
            water.clip(to: footprint)
            if complete { BloomSuccessWater.draw(in: water, size: bounds, time: reduceMotion ? 0 : time) }
            WaterDrawing.caustics(in: water, size: bounds, time: reduceMotion ? 0 : time, strength: complete ? 0.65 : 0.35)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct CoralCell: View {
    let lit: Bool
    let stone: Bool
    let current: Bool
    var vertical = false
    let star: Bool
    var wholeRow = false
    var wholeColumn = false
    let hint: Bool
    let seed: Double
    let species: CoralSpecies
    let bloom: Double
    let swell: Double
    let action: () -> Void
    @Environment(\.oceanTime) private var time
    @Environment(\.colorScheme) private var colorScheme
    private var isDeepSea: Bool { colorScheme == .dark }
    private var displayedSpecies: CoralSpecies { vertical || wholeColumn ? .tideSpires : current || wholeRow ? .driftShelf : star ? .rosyFan : species }
    private var tint: Color { CoralArt.blend(displayedSpecies.color, 0xFFD6A0, bloom) }
    var body: some View {
        Button(action: action) {
            ZStack {
                if stone {
                    RestingPebbleTile(seed: seed)
                } else {
                    if lit {
                        // Keep the original water, coral texture and glow; omit only the perimeter.
                        MembraneSurface(tint: tint, intensity: 1.1, seed: seed, round: true, showsBorder: false)
                    } else {
                        SeaGlassShape(seed: seed, amplitude: 0)
                            .fill(Color.adaptive(light: 0x345F5D, dark: 0x08252E))
                    }
                    CoralArt(species: displayedSpecies, lit: lit, bloom: bloom, swell: swell, seed: seed).padding(5)
                        .scaleEffect(lit ? 1.04 : 0.87)
                        .shadow(color: lit ? tint.opacity(0.55 + bloom * 0.2) : .clear, radius: 5 + bloom * 3)
                    if lit {
                        Image(systemName: "sparkle").font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: 0xFFF3CE))
                            .padding(8).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .accessibilityHidden(true)
                    }
                }
                if hint && !stone { BloomHintHalo(seed: seed).padding(2) }
                if !stone && (star || wholeRow || wholeColumn) {
                    CoralRuleMark(kind: star ? .diagonal : wholeRow ? .row : .column)
                        .frame(width: 21, height: 21).padding(4)
                        .foregroundStyle(wholeRow || wholeColumn ? Color(hex: 0x244F50) : Color(hex: 0xFFF1C1))
                        .background(SeaGlassShape(seed: seed).fill(wholeRow || wholeColumn ? Color(hex: 0xFFE2A2) : Color(hex: 0x244F50)))
                        .accessibilityHidden(true)
                } else if !stone && (current || vertical) {
                    Image(systemName: vertical ? "arrow.up.arrow.down" : "arrow.left.arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFFF1C1))
                        .frame(width: 29, height: 29)
                        .background(SeaGlassShape(seed: seed).fill(Color(hex: 0x244F50).opacity(0.9)))
                        .accessibilityHidden(true)
                }
            }.aspectRatio(1, contentMode: .fit)
        }.buttonStyle(ReefButtonStyle(kind: .coral))
    }
}

/// Custom direction glyphs: diagonal arrows or an end-to-end line with stops.
struct CoralRuleMark: Shape {
    enum Kind { case diagonal, row, column }
    var kind: Kind
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func line(_ points: [(CGFloat, CGFloat)]) {
            p.move(to: CGPoint(x: points[0].0, y: points[0].1))
            for (x,y) in points.dropFirst() { p.addLine(to: CGPoint(x:x,y:y)) }
        }
        if kind == .diagonal {
            line([(3,3),(17,17)]); line([(3,17),(17,3)])
            for (x,y,sx,sy): (CGFloat,CGFloat,CGFloat,CGFloat) in [(3,3,1,1),(17,3,-1,1),(3,17,1,-1),(17,17,-1,-1)] {
                line([(x,y+4*sy),(x,y),(x+4*sx,y)])
            }
        } else {
            line([(4,10),(16,10)]); line([(7,6),(3,10),(7,14)])
            line([(13,6),(17,10),(13,14)])
            line([(1,5),(1,15)]); line([(19,5),(19,15)])
        }
        if kind == .column {
            p = Path()
            line([(10,4),(10,16)]); line([(6,7),(10,3),(14,7)])
            line([(6,13),(10,17),(14,13)])
            line([(5,1),(15,1)]); line([(5,19),(15,19)])
        }
        return p.strokedPath(StrokeStyle(lineWidth:1.9,lineCap:.round,lineJoin:.round))
            .applying(CGAffineTransform(scaleX:rect.width/20,y:rect.height/20))
            .offsetBy(dx:rect.minX,dy:rect.minY)
    }
}

enum CoralPracticeKind: Hashable {
    case vertical, diagonal, lines
    var title: String { switch self { case .vertical: "Up & down"; case .diagonal: "Diagonals"; case .lines: "Whole lines" } }
    var instruction: String { switch self {
        case .vertical: "It flips itself, above and below."
        case .diagonal: "It flips itself and its diagonal neighbors."
        case .lines: "One flips its whole row. The other flips its whole column."
    } }
    var targets: [Int] { self == .lines ? [11,8] : [4] }
    func puzzle() -> CoralPuzzle {
        let size = self == .lines ? 5 : 3
        var p = CoralPuzzle(level: 1, size: size, cells: Array(repeating:true,count:size*size))
        switch self {
        case .vertical: p.verticals=[4]; p.gaps=[0,2,6,8]
        case .diagonal: p.stars=[4]
        case .lines: p.rowCorals=[11]; p.columnCorals=[8]
        }
        for target in targets { p.pulse(at:target) }
        return p
    }
}

/// A free, unnumbered practice using the actual tap rules; no store or inventory.
struct CoralPractice: View {
    let kind: CoralPracticeKind
    var onClose: () -> Void
    @State private var demo: CoralPuzzle
    @State private var tapped: Set<Int> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    init(kind: CoralPracticeKind, onClose: @escaping () -> Void) {
        self.kind=kind; self.onClose=onClose; _demo=State(initialValue:kind.puzzle())
    }
    var body: some View {
        OceanScene {
            ScrollView {
            VStack(spacing: 20) {
                Text(kind.title).reefFont(size:28,weight:.semibold,display:true)
                Text(kind.instruction).reefFont(size:16).multilineTextAlignment(.center)
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:demo.size),spacing:8) {
                    ForEach(demo.cells.indices,id:\.self) { i in
                        if demo.isGap(i) { Color.clear.aspectRatio(1,contentMode:.fit).accessibilityHidden(true) }
                        else {
                            CoralCell(lit:demo.cells[i],stone:false,current:false,vertical:demo.isVertical(i),
                                      star:demo.stars.contains(i),wholeRow:demo.isRowCoral(i),wholeColumn:demo.isColumnCoral(i),
                                      hint:kind.targets.contains(i) && !tapped.contains(i),seed:Double(i),species:.peachSprig,bloom:0,swell:0) {
                                withAnimation(reduceMotion ? nil : ReefMotion.response) { demo.pulse(at:i); tapped.insert(i) }
                            }.allowsHitTesting(kind.targets.contains(i) && !tapped.contains(i))
                                .accessibilityHidden(!kind.targets.contains(i))
                                .accessibilityLabel(demo.isRowCoral(i) ? "Flip the whole row" : demo.isColumnCoral(i) ? "Flip the whole column" : kind.instruction)
                        }
                    }
                }.padding(12).frame(maxWidth:310)
                    .background(BloomReefBed(size:demo.size,gaps:demo.gaps ?? []))
                if !demo.isComplete { Text("Try the gold ring.").reefFont(size:14) }
                Button(demo.isComplete ? "Play" : "Skip",action:onClose).buttonStyle(ReefButtonStyle(filled:true))
            }.padding(28).frame(maxWidth:390).foregroundStyle(ReefTheme.ink)
            }
        }.frame(minWidth:330,minHeight:560)
    }
}

private struct BloomHintHalo: View {
    let seed: Double
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let breath = reduceMotion ? 1 : 0.88 + 0.12 * sin(time / 4000 * .pi * 2)
        let ring = SeaGlassShape(seed: seed)
        ZStack {
            ring.stroke(ReefTheme.hintGold.opacity(0.65 * breath), lineWidth: 11)
                .blur(radius: 5)
            // A thin amber rim preserves contrast even against sunlit Lagoon water.
            ring.stroke(Color(hex: 0x98601A).opacity(0.85), lineWidth: 6.5)
            ring.stroke(ReefTheme.hintGold, lineWidth: 4.5)
                .shadow(color: ReefTheme.hintGold.opacity(0.9 * breath), radius: 7)
            ring.stroke(ReefTheme.hintCore, lineWidth: 1.5)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct BloomLivesStatus: View {
    var compact = false
    @Environment(ReefStore.self) private var store

    static func countdown(_ until: Date, at now: Date) -> String {
        let seconds = max(0, Int(ceil(until.timeIntervalSince(now))))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { clock in
            let supplies = store.progress.supplies.refreshed(at: clock.date)
            VStack(spacing: 4) {
                ReefIconLabel(supplies.unlimited(at: clock.date) ? "∞" : "\(supplies.lives)", supplies.unlimited(at: clock.date) ? .boostLive : .life, size: compact ? 25 : 38)
                    .reefFont(size: 16, weight: .semibold).foregroundStyle(ReefTheme.coral)
                if let until = supplies.unlimitedUntil, until > clock.date {
                    Text(Self.countdown(until, at: clock.date)).monospacedDigit().reefFont(size: 12)
                } else if let due = supplies.nextLifeAt {
                    Text(Self.countdown(due, at: clock.date)).monospacedDigit().reefFont(size: 12)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(supplies.unlimited(at: clock.date) ? "Unlimited lives" : "\(supplies.lives) lives")
            .onChange(of: supplies.lives) { _, _ in store.refreshLives() }
            .onChange(of: supplies.unlimited(at: clock.date)) { _, _ in store.refreshLives() }
            .onAppear { store.refreshLives() }
        }
    }
}

struct BloomLivesButton: View {
    @State private var showLives = false
    var body: some View {
        Button { showLives = true } label: { BloomLivesStatus() }
            .buttonStyle(ReefButtonStyle(kind: .quiet))
            .accessibilityHint("View lives and activate a collected unlimited-lives boost.")
            .sheet(isPresented: $showLives) {
                BloomLivesSheet().presentationDetents([.large]).presentationBackground(.clear)
            }
    }
}

struct BloomLivesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReefStore.self) private var store
    var body: some View {
        OceanScene {
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Text("Lives & boosts").reefFont(size: 25, weight: .semibold, display: true)
                        Spacer()
                        Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                            .buttonStyle(ReefButtonStyle(kind: .orb)).accessibilityLabel("Close lives and boosts")
                    }
                    BloomLivesStatus()
                    if !store.canStartBloom {
                        Button {
                            if store.claimFreeLifeRefill() { dismiss() }
                        } label: { VStack(spacing: 4) { Text("Watch an ad"); ReefIconLabel("+3", .life) } }
                            .buttonStyle(ReefButtonStyle(filled: true))
                        Text("Free preview · no ad").reefFont(size: 11).foregroundStyle(ReefTheme.muted)
                    }
                    Text("One life every 5 minutes.")
                        .reefFont(size: 14).multilineTextAlignment(.center)
                    Text("Win and keep your lives. Fail or restart to lose one.")
                        .reefFont(size: 13).multilineTextAlignment(.center).foregroundStyle(ReefTheme.muted)
                    if store.progress.supplies.unlimitedBoosts > 0 {
                        TideDivider(tint: ReefTheme.coral)
                        ReefBoostIcon(stored: true, size: 64)
                        Text("\(store.progress.supplies.unlimitedBoosts) saved").reefFont(size: 13)
                        Button {
                            if store.activateUnlimitedLives() { dismiss() }
                        } label: {
                            Text("Use 15 min").frame(maxWidth: .infinity)
                        }.buttonStyle(ReefButtonStyle(filled: true)).disabled(store.isSaveBlocked)
                    }
                    if store.progress.supplies.unlimited() || store.progress.supplies.unlimitedBoosts > 0 {
                        Text("The timer keeps running while you’re away.")
                            .reefFont(size: 13).multilineTextAlignment(.center).foregroundStyle(ReefTheme.muted)
                    }
                }.padding(24).frame(maxWidth: 420)
            }.scrollIndicators(.hidden)
        }.foregroundStyle(ReefTheme.ink)
    }
}

/// The celebration clock is in milliseconds; show when the reward bubble first appears.
private struct BloomDiscoveryTrigger: View {
    let ready: Bool
    @Environment(ReefStore.self) private var store
    @Environment(\.presentReefDiscovery) private var presentDiscovery
    var body: some View {
        Color.clear.frame(width:0,height:0).onChange(of:ready,initial:true) { _,ready in
            if ready,let receipt=store.discoveryReceipt,receipt.source == .bloom(store.puzzle.level) {
                presentDiscovery(receipt.id)
            }
        }.accessibilityHidden(true)
    }
}
