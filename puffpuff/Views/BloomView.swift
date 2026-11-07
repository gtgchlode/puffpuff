import SwiftUI

struct BloomView: View {
    var onHome: () -> Void
    var onPause: () -> Void
    var onOverlay: (Bool) -> Void = { _ in }
    @Environment(ReefStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var tapSupplyHeight = 220.0
    @ScaledMetric(relativeTo: .body) private var hintSupplyHeight = 255.0
    @State private var showTapSummary = false
    @State private var inspectedReward: BloomBubbleReward?
    @State private var showRules = false
    @State private var showCoralLesson = false
    @State private var lessonKind: CoralPracticeKind = .vertical
    @State private var showHintSupply = false
    @State private var lighting = false
    @State private var showLifePeek = false
    @State private var showReplay = false
    @State private var showMoves = false
    @State private var showFuture = false
    @State private var pendingHintUse: BloomHintUse?
    @State private var showLives = false
    @State private var showRestart = false
    @State private var celebrationOrigin: Int?
    @State private var celebrationID = 0
    @State private var playFishCelebration = false
    @State private var reinflatingLevel: Int?
    @State private var bubbleBurstID = 0
    @AppStorage("puffpuff.confirmHintUse") private var confirmHintUse = true
    @AppStorage("puffpuff.celebrationAnimations") private var celebrationAnimations = true
    @AppStorage("puffpuff.tutorial.verticalCoral") private var learnedVerticalCoral = false
    @AppStorage("puffpuff.tutorial.diagonalCoral") private var learnedDiagonalCoral = false
    @AppStorage("puffpuff.tutorial.lineCoral") private var learnedLineCoral = false
    @AppStorage("puffpuff.tutorial.burstCoral") private var learnedBurstCoral = false

    private var victory: BloomVictoryStyle {
        .choose(level:store.puzzle.level,size:store.puzzle.size,
                feature:store.puzzle.feature,pearlTarget:store.puzzle.pearlTarget)
    }
    private var earnedRewards: [BloomBubbleReward] {
        BloomBubbleReward.earned(pearl: store.puzzle.earnedPearl, hint: store.puzzle.earnedHint == true,
                                 shot: store.puzzle.earnedShot == true, gift: store.puzzle.earnedLifeGift,
                                 lighter: store.puzzle.earnedLighter == true, shots: store.puzzle.earnedShots, hints: store.puzzle.earnedHints, currentAdder:store.puzzle.earnedCurrentAdder == true, bouncyBlock:store.puzzle.earnedBouncyBlock == true, futureTeller:store.puzzle.earnedFutureTeller == true)
    }
    private var reinflating: Bool {
        reinflatingLevel == store.puzzle.level && !store.isComplete && celebrationAnimations && !reduceMotion
    }

    private var showingOverlay: Bool {
        showRules || showCoralLesson || showLives || showRestart || inspectingCompletion || showLifePeek || showReplay || showMoves || showFuture || pendingHintUse != nil
    }

    private var inspectingCompletion: Bool { inspectedReward != nil || showTapSummary }

    private var showingSupplies: Bool {
        store.isOutOfTaps || (showHintSupply && !store.isComplete && !store.puzzle.isTutorial && store.progress.hints == 0)
    }
    @ViewBuilder private var supplyControls: some View {
        if store.isOutOfTaps { retryView }
        else { BloomHintSupply { showHintSupply = false } }
    }

    var body: some View {
        GeometryReader { available in
        ReefClock(duration:reinflating ? BloomVictoryStyle.reinflationDuration : victory.duration,
                  paused:(celebrationOrigin == nil && !reinflating) || showingOverlay,frameInterval:1.0/30) { time in
        ScrollViewReader { scrollProxy in
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("\(store.puzzle.level)").reefFont(size: 25, weight: .semibold, display: true).foregroundStyle(ReefTheme.ink)
                            .accessibilityLabel("Level \(store.puzzle.level)")
                        Button { showLifePeek = true } label: {
                            BloomLivesStatus(compact: true, iconOnly: true).frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Show lives")
                        .anchorPreference(key: BloomFishAnchors.self, value: .bounds) { ["lives": $0] }
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
                    VStack(spacing: 0) {
                        ReefTrailReturnButton(progress: store.progress.firstReef, action: onHome)
                        ReefPauseButton(action: onPause)
                    }
                }
                if store.bloomTrailGuidance {
                    Text("Win Bloom to earn Glow and light your way through the trail.")
                        .reefFont(size: 15, weight: .semibold).foregroundStyle(ReefTheme.ink)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
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
                        tapsCounter
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
                      .id("future-board")
                      .anchorPreference(key:BloomFishAnchors.self,value:.bounds) { ["board":$0] }

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
                        } else if [5, 21, 41, 81].contains(store.puzzle.level) {
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
                        if store.progress.futureTellerUnlocked,
                           store.progress.futureTellers > 0 || store.puzzle.futureTellerFinalTap != nil {
                            Button { requestHintUse(.futureTeller) } label: {
                                BloomGlimpseLabel(count: store.progress.futureTellers,
                                    available: store.puzzle.futureTellerFinalTap != nil)
                            }.buttonStyle(ReefButtonStyle(kind: .quiet))
                                .accessibilityLabel(store.puzzle.futureTellerFinalTap == nil ? "Future Teller" : "Your glimpse")
                                .accessibilityValue("\(store.progress.futureTellers) available")
                                .accessibilityHint(store.puzzle.futureTellerFinalTap == nil ? "Uses one Future Teller to preview a possible final arrangement and winning tap." : "Reopen the glimpse for this attempt. No item used.")
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

                        }
                        VStack(spacing: 6) { reviewControls }
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
                                    duration: victory.duration, onInspect: { inspectedReward = $0 })
                            }
                            if !store.isComplete && bubbleBurstID > 0 && !reduceMotion {
                                BloomTapBubbles(restingFrame: proxy[fish])
                                    .id("\(store.puzzle.level)-bubbles-\(bubbleBurstID)")
                            }
                        }
                    }
                }
                .background(BloomDiscoveryTrigger(ready:store.isComplete && time>=350))
        }.scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showingSupplies {
                ViewThatFits(in: .vertical) {
                    supplyControls.fixedSize(horizontal: false, vertical: true)
                    ScrollView { supplyControls }.scrollBounceBehavior(.basedOnSize)
                }
                .frame(height: min(max(180, available.size.height * 0.5),
                                   store.isOutOfTaps ? tapSupplyHeight : hintSupplyHeight))
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background {
                    LinearGradient(colors: [ReefTheme.glass.opacity(0.92), ReefTheme.glass],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .blur(radius: showFuture ? 6 : 0)
        .allowsHitTesting(!inspectingCompletion && !showLifePeek && !showFuture && pendingHintUse == nil)
        .accessibilityHidden(inspectingCompletion || showLifePeek || showFuture || pendingHintUse != nil)
        .overlayPreferenceValue(BloomFishAnchors.self) { anchors in
            GeometryReader { proxy in
                if showFuture, let board = anchors["board"],
                   let target = store.puzzle.futureTellerBoard, let final = store.puzzle.futureTellerFinalTap {
                    BloomFutureTellerOverlay(target: target, finalTap: final,
                        boardFrame: proxy[board], viewport: proxy.size) {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { showFuture = false }
                        }
                        .transition(.opacity)
                }
            }
        }
        .overlayPreferenceValue(BloomFishAnchors.self) { anchors in
            GeometryReader { proxy in
                if showLifePeek, let heart = anchors["lives"] {
                    BloomLivesPeek(anchor: proxy[heart], viewport: proxy.size) { showLifePeek = false }
                }
            }
        }
        .overlay {
            if let pendingHintUse {
                BloomInfoPanel(closeLabel: "Cancel use", onDismiss: { self.pendingHintUse = nil }) {
                    VStack(spacing: 18) {
                        ReefIcon(pendingHintUse.icon, size: 66)
                        Text(pendingHintUse.question).reefFont(size: 24, weight: .semibold)
                        Button("Use") {
                            self.pendingHintUse = nil
                            useHint(pendingHintUse)
                        }.buttonStyle(ReefButtonStyle(filled: true))
                        Button("Keep playing") { self.pendingHintUse = nil }
                            .buttonStyle(ReefButtonStyle(kind: .quiet))
                    }
                }
            } else if let reward = inspectedReward {
                BloomRewardInfo(reward: reward) { inspectedReward = nil }
            } else if showTapSummary {
                BloomTapInfo(moves: store.puzzle.moves, bonus: store.puzzle.earnedPearl) { showTapSummary = false }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { inspectedReward = nil; showTapSummary = false; showLifePeek = false; showFuture = false; pendingHintUse = nil }
        }
        .onDisappear {
            if inspectingCompletion || showLifePeek || showFuture || pendingHintUse != nil { inspectedReward = nil; showTapSummary = false; showLifePeek = false; showFuture = false; pendingHintUse = nil; onOverlay(false) }
        }
        .onChange(of: showFuture) { _, shown in
            if shown {
                // The control is below Hint; bring the actual board into view
                // before showing its glimpse, including on short screens.
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    scrollProxy.scrollTo("future-board", anchor: .center)
                }
            }
        }
        }
        }.id("\(store.puzzle.level)-\(celebrationID)")
        }
        .task(id: showLifePeek) {
            guard showLifePeek else { return }
            do {
                try await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                showLifePeek = false
            } catch { /* Dismissal or leaving Bloom cancels this peek. */ }
        }
        .onAppear { offerCoralLesson() }
        .onChange(of: store.progress.hints) { _, count in
            if count > 0 { showHintSupply = false }
        }
        .onChange(of: store.puzzle.level) { _, level in
            inspectedReward = nil
            showTapSummary = false
            showLifePeek = false
            lighting = false
            showFuture = false
            pendingHintUse = nil
            showHintSupply = false
            celebrationOrigin = nil
            playFishCelebration = false
            bubbleBurstID = 0
            if reinflatingLevel != level { reinflatingLevel = nil }
            offerCoralLesson()
        }
        .onChange(of: store.isComplete) { _, complete in
            if complete { showHintSupply = false; lighting = false; showFuture = false; pendingHintUse = nil } else { celebrationOrigin = nil; inspectedReward = nil; showTapSummary = false }
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
        .onChange(of: showingOverlay) { _, value in onOverlay(value) }
        .sheet(isPresented: $showReplay) {
            BloomFreeReplay(puzzle: store.puzzle, canAdvance: store.puzzle.level < ReefStore.levelLimit,
                onClose: { showReplay = false }, onNext: {
                    store.nextPuzzle()
                    showReplay = false
                })
                .environment(\.reefPaused, false)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .sheet(isPresented: $showMoves) {
            BloomMoveShow(puzzle: store.puzzle) { showMoves = false }
                .environment(\.reefPaused, false)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
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
                Text("One hint reveals a useful coral to tap. Collect hints as you play, or get more when you run out.").multilineTextAlignment(.center)
                Text(store.puzzle.lesson).multilineTextAlignment(.center).foregroundStyle(ReefTheme.muted)
                if store.puzzle.hasGaps {
                    Text("Open water has no tile. Neighbor ripples never skip a gap. Whole-line coral reaches across the row or column.")
                        .multilineTextAlignment(.center).foregroundStyle(ReefTheme.muted)
                }
                Text("Win Bloom to earn Glow for the Trail. You may find extra supplies too.").multilineTextAlignment(.center)
                Button("Got it") { showRules = false }.buttonStyle(ReefButtonStyle(filled: true))
              }.padding(28).frame(maxWidth: 460).foregroundStyle(ReefTheme.ink)
            }.presentationDetents([.large]).presentationDragIndicator(.visible).presentationBackground(.clear)
        }
    }

    @ViewBuilder private var reviewControls: some View {
        Button { showReplay = true } label: {
            Text("Replay").multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
        }.buttonStyle(ReefButtonStyle(kind: .quiet))
            .accessibilityHint("Try this level again for free, without rewards or losing lives.")
        if store.puzzle.recording != nil {
            Button { showMoves = true } label: {
                Text("Watch your moves").multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
            }.buttonStyle(ReefButtonStyle(kind: .quiet))
        }
    }

    @ViewBuilder private var tapsCounter: some View {
        if store.isComplete {
            Button { showTapSummary = true } label: {
                BloomTapsBadge(remaining: store.puzzle.tapsRemaining, complete: true, bonus: store.puzzle.earnedPearl)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Finished in \(store.puzzle.moves) taps" + (store.puzzle.earnedPearl ? ", tap bonus earned" : ""))
            .accessibilityHint("Show tap summary")
        } else {
            BloomTapsBadge(remaining: store.puzzle.tapsRemaining, complete: false, bonus: false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(store.puzzle.tapsRemaining) taps remaining out of \(store.puzzle.allowedTaps)")
        }
    }

    private func offerCoralLesson() {
        guard !showCoralLesson, !store.isComplete else { return }
        if !learnedBurstCoral && !(store.puzzle.burstCorals ?? []).isEmpty { lessonKind = .burst }
        else if !learnedLineCoral && store.puzzle.hasLineCorals { lessonKind = .lines }
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
        case .burst: learnedBurstCoral = true
        }
    }

    private var hintControls: some View {
        HStack(spacing: 3) {
            Button { requestHintUse(.hint) } label: {
                ReefIconLabel(store.puzzle.isTutorial ? "Guide" : "\(store.progress.hints)", .hint)
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

    private func requestHintUse(_ kind: BloomHintUse) {
        guard store.canPlayBloom, !store.isSaveBlocked, !store.isComplete, !store.isOutOfTaps else { return }
        let spendsItem = kind == .hint
            ? !store.puzzle.isTutorial && store.puzzle.revealedHint == nil && store.progress.hints > 0
            : store.puzzle.futureTellerFinalTap == nil && store.progress.futureTellers > 0
        if confirmHintUse && spendsItem { pendingHintUse = kind }
        else { useHint(kind) }
    }

    private func useHint(_ kind: BloomHintUse) {
        switch kind {
        case .hint:
            if !store.showHint() { showHintSupply = true }
        case .futureTeller:
            if store.showFutureTeller() {
                lighting = false; showHintSupply = false
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { showFuture = true }
            }
        }
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
                              wholeRow: store.puzzle.isRowCoral(index), wholeColumn: store.puzzle.isColumnCoral(index), burst: store.puzzle.isBurst(index),
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
                              || (lighting ? store.puzzle.cells[index] : !store.puzzle.canTap(index)))
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
        let kind = store.puzzle.isBurst(index) ? "burst coral" : store.puzzle.isRowCoral(index) ? "whole row coral" :
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
    var burst = false
    let hint: Bool
    let seed: Double
    let species: CoralSpecies
    let bloom: Double
    let swell: Double
    let action: () -> Void
    @Environment(\.oceanTime) private var time
    @Environment(\.colorScheme) private var colorScheme
    private var isDeepSea: Bool { colorScheme == .dark }
    private var displayedSpecies: CoralSpecies { burst ? .burstAnemone : vertical || wholeColumn ? .tideSpires : current || wholeRow ? .driftShelf : star ? .rosyFan : species }
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
                if !stone && (burst || star || wholeRow || wholeColumn) {
                    CoralRuleMark(kind: burst ? .burst : star ? .diagonal : wholeRow ? .row : .column)
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
    enum Kind { case diagonal, row, column, burst }
    var kind: Kind
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func line(_ points: [(CGFloat, CGFloat)]) {
            p.move(to: CGPoint(x: points[0].0, y: points[0].1))
            for (x,y) in points.dropFirst() { p.addLine(to: CGPoint(x:x,y:y)) }
        }
        if kind == .burst {
            p.addEllipse(in: CGRect(x: 7, y: 7, width: 6, height: 6))
            for i in 0..<8 {
                let a = Double(i) * .pi / 4
                line([(10 + CGFloat(cos(a)) * 6, 10 + CGFloat(sin(a)) * 6),
                      (10 + CGFloat(cos(a)) * 9, 10 + CGFloat(sin(a)) * 9)])
            }
        } else if kind == .diagonal {
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
    case vertical, diagonal, lines, burst
    var title: String { switch self { case .vertical: "Up & down"; case .diagonal: "Diagonals"; case .lines: "Whole lines"; case .burst: "Burst coral" } }
    var instruction: String { switch self {
        case .vertical: "It flips itself, above and below."
        case .diagonal: "It flips itself and its diagonal neighbors."
        case .lines: "One flips its whole row. The other flips its whole column."
        case .burst: "Tap to flip this coral and all eight around it."
    } }
    var targets: [Int] { self == .lines ? [11,8] : [4] }
    func puzzle() -> CoralPuzzle {
        let size = self == .lines ? 5 : 3
        var p = CoralPuzzle(level: 1, size: size, cells: Array(repeating:true,count:size*size))
        switch self {
        case .vertical: p.verticals=[4]; p.gaps=[0,2,6,8]
        case .diagonal: p.stars=[4]
        case .lines: p.rowCorals=[11]; p.columnCorals=[8]
        case .burst: p.burstCorals=[4]
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
                                      star:demo.stars.contains(i),wholeRow:demo.isRowCoral(i),wholeColumn:demo.isColumnCoral(i),burst:demo.isBurst(i),
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
    var iconOnly = false
    @Environment(ReefStore.self) private var store

    static func countdown(_ until: Date, at now: Date) -> String {
        let seconds = max(0, Int(ceil(until.timeIntervalSince(now))))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { clock in
            let supplies = store.progress.supplies.refreshed(at: clock.date)
            VStack(spacing: 4) {
                Group {
                    if iconOnly { ReefIcon(supplies.unlimited(at:clock.date) ? .boostLive : .life, size: compact ? 25:38) }
                    else if supplies.unlimited(at:clock.date) {ReefIcon(.boostLive,size:compact ? 25:38)}
                    else {ReefIconLabel("\(supplies.lives)",.life,size:compact ? 25:38)}
                }
                    .reefFont(size: 16, weight: .semibold).foregroundStyle(ReefTheme.coral)
                if !iconOnly, let until = supplies.unlimitedUntil, until > clock.date {
                    Text(Self.countdown(until, at: clock.date)).monospacedDigit().reefFont(size: 12)
                } else if !iconOnly, let due = supplies.nextLifeAt {
                    Text(Self.countdown(due, at: clock.date)).monospacedDigit().reefFont(size: 12)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(iconOnly ? "Lives" : supplies.unlimited(at: clock.date) ? "Unlimited lives" : "\(supplies.lives) lives")
            .onChange(of: supplies.lives) { _, _ in store.refreshLives() }
            .onChange(of: supplies.unlimited(at: clock.date)) { _, _ in store.refreshLives() }
            .onAppear { store.refreshLives() }
        }
    }
}

/// A brief anchored balance peek, separate from the full lives/refill sheet.
private struct BloomLivesPeek: View {
    let anchor: CGRect
    let viewport: CGSize
    let onDismiss: () -> Void
    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: onDismiss) {
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
            }.buttonStyle(.plain).accessibilityLabel("Hide lives")
            BloomLivesStatus()
                .padding(16).frame(width: 140, height: 108)
                .background {
                    MembraneShape().fill(ReefTheme.glass.opacity(0.97))
                    MembraneSurface(tint: ReefTheme.coral, intensity: 0.75)
                }
                .contentShape(Rectangle()).onTapGesture { }
                .position(x: min(max(78, anchor.minX + 70), viewport.width - 78),
                          y: min(max(62, anchor.maxY + 60), viewport.height - 62))
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
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


private enum BloomHintUse {
    case hint, futureTeller
    var icon: ReefIconKind { self == .hint ? .hint : .futureTeller }
    var question: String { self == .hint ? "Use a hint?" : "Use a Future Teller?" }
}

/// A saved glimpse remains available without using another item.
private struct BloomGlimpseLabel: View {
    let count: Int
    let available: Bool
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        let breath = reduceMotion ? 1 : 0.86 + 0.14 * sin(time / 4000 * .pi * 2)
        ReefIconLabel("\(count)", .futureTeller)
            .background {
                if available {
                    SeaGlassShape().fill(ReefTheme.hintGold.opacity(0.3 * breath))
                        .blur(radius: 7).padding(-7)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .shadow(color: ReefTheme.hintGold.opacity(available ? 0.65 * breath : 0), radius: 6)
    }
}
