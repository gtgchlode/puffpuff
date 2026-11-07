import SwiftUI

/// A disposable replay of the just-completed level. This view never owns a store.
struct BloomFreeReplay: View {
    let original: CoralPuzzle
    let canAdvance: Bool
    var onClose: () -> Void
    var onNext: () -> Void
    @State private var puzzle: CoralPuzzle
    @State private var hint: Int?
    @State private var showMoves = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(puzzle: CoralPuzzle, canAdvance: Bool, onClose: @escaping () -> Void, onNext: @escaping () -> Void) {
        original = puzzle; self.canAdvance = canAdvance; self.onClose = onClose; self.onNext = onNext
        _puzzle = State(initialValue: puzzle.freePractice())
    }

    var body: some View {
        OceanScene(paused: showMoves) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Replay · \(puzzle.level)").reefFont(size: 24, weight: .semibold)
                        Text("Just for fun").reefFont(size: 14)
                    }
                    Spacer()
                    PipView(happy: puzzle.isComplete).frame(width: 60, height: 50)
                    Button("Done", action: onClose).buttonStyle(ReefButtonStyle(kind: .quiet))
                }.padding(.horizontal, 22)
                ScrollView {
                    VStack(spacing: 14) {
                        BloomTapsBadge(remaining: puzzle.tapsRemaining, complete: puzzle.isComplete, bonus: false)
                        BloomReviewBoard(puzzle: puzzle, focus: hint) { index in
                            guard puzzle.canTap(index) else { return }
                            withAnimation(reduceMotion ? nil : ReefMotion.response) {
                                puzzle.playTap(at: index); hint = nil
                            }
                        }
                        if puzzle.isComplete {
                            Text("\(puzzle.moves) taps").reefFont(size: 16)
                            Button("Watch your moves") { showMoves = true }
                                .buttonStyle(ReefButtonStyle(kind: .quiet))
                        } else if puzzle.isOutOfTaps {
                            Text("Try again").reefFont(size: 20, weight: .semibold)
                        } else {
                            Button("Hint") { hint = puzzle.solution()?.first }
                                .buttonStyle(ReefButtonStyle(kind: .quiet))
                        }
                    }.padding(.horizontal, 22).padding(.bottom, 14).frame(maxWidth: .infinity)
                }.scrollIndicators(.visible)
                VStack(spacing: 6) {
                    Button(puzzle.isComplete ? "Replay again" : "Restart") {
                        puzzle = original.freePractice(); hint = nil
                    }.buttonStyle(ReefButtonStyle(kind: .quiet))
                    if canAdvance {
                        Button("Next patch", action: onNext).buttonStyle(ReefButtonStyle(filled: true))
                    }
                }.padding(.horizontal, 22).padding(.bottom, 14)
            }.padding(.top, 16).foregroundStyle(ReefTheme.ink)
        }
        .sheet(isPresented: $showMoves) {
            BloomMoveShow(puzzle: puzzle) { showMoves = false }
                .environment(\.reefPaused, false)
                .presentationDetents([.large]).presentationBackground(.clear)
        }
        .frame(minWidth: 320, idealHeight: 650)
    }
}

/// Read-only viewing of recorded actions, never a solution generated after the fact.
struct BloomMoveShow: View {
    let original: CoralPuzzle
    let frames: [BloomMoveFrame]
    var onClose: () -> Void
    @AppStorage("puffpuff.bloomPlaybackSpeed") private var playbackSpeed = 0.5
    @State private var playbackID = 0
    @State private var paused = false
    @State private var manualStep = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(puzzle: CoralPuzzle, onClose: @escaping () -> Void) {
        original = puzzle; frames = puzzle.recordedFrames ?? []; self.onClose = onClose
    }
    private var timing: BloomPlaybackTiming { .init(moveCount: frames.count - 1, speed: playbackSpeed) }

    var body: some View {
        OceanScene(paused: paused) {
            BloomMoveClock(timing: timing, paused: paused) { phase in
                let step = reduceMotion ? manualStep : min(max(0, frames.count - 1), max(0, Int(phase)))
                VStack(spacing: 14) {
                    Text("Watch your moves").reefFont(size: 25, weight: .semibold)
                        .multilineTextAlignment(.center).padding(.horizontal, 22)
                    ScrollView {
                        if frames.indices.contains(step) {
                            let frame = frames[step]
                            let board = board(at: frame)
                            VStack(spacing: 16) {
                                PipView(happy: board.isComplete).frame(width: 104, height: 88)
                                Text("\(frame.taps) / \(original.moves)").monospacedDigit().reefFont(size: 18)
                                    .accessibilityLabel("\(frame.taps) of \(original.moves) taps")
                                BloomReviewBoard(puzzle: board, focus: frame.move?.index,
                                    frame: frame, pulse: reduceMotion ? 1 : min(1, max(0, phase - Double(step))))
                            }.padding(.horizontal, 22).padding(.bottom, 20).frame(maxWidth: .infinity)
                        }
                    }.scrollIndicators(.visible)
                    if !reduceMotion {
                        HStack(spacing: 12) {
                            Text("Slow").reefFont(size: 14)
                            Slider(value: Binding(get: { timing.speed }, set: { playbackSpeed = $0 }), in: 0...1)
                                .tint(ReefTheme.ink)
                                .accessibilityLabel("Playback speed")
                                .accessibilityValue(timing.speed < 0.05 ? "Slowest" : timing.speed > 0.95 ? "Fastest" : "\(Int(timing.speed * 100)) percent")
                                .accessibilityHint("Adjusts speed without restarting the move show.")
                            Text("Fast").reefFont(size: 14)
                        }.padding(.horizontal, 26)
                    }
                    HStack(spacing: 8) {
                        if reduceMotion && manualStep < frames.count - 1 {
                            Button("Next tap") { manualStep += 1 }.buttonStyle(ReefButtonStyle(kind: .quiet))
                        } else if phase < timing.finalPhase && !reduceMotion {
                            Button(paused ? "Play" : "Pause") { paused.toggle() }.buttonStyle(ReefButtonStyle(kind: .quiet))
                        } else {
                            Button("Again") { manualStep = 0; paused = false; playbackID += 1 }
                                .buttonStyle(ReefButtonStyle(kind: .quiet))
                        }
                        Button("Done", action: onClose).buttonStyle(ReefButtonStyle(filled: true))
                    }.padding(.horizontal, 22).padding(.bottom, 16)
                }.padding(.top, 22).foregroundStyle(ReefTheme.ink)
            }.id(playbackID)
        }.frame(minWidth: 320, idealHeight: 650)
    }

    private func board(at frame: BloomMoveFrame) -> CoralPuzzle {
        var board = original
        board.cells = frame.cells; board.lighterCorals = frame.held; board.moves = frame.taps
        return board
    }
}

/// The move show's variable clock follows the existing pause/visibility rules.
/// Rate edits retain the exact phase; only Again starts a new clock identity.
private struct BloomMoveClock<Content: View>: View {
    let timing: BloomPlaybackTiming
    var paused: Bool
    @ViewBuilder var content: (Double) -> Content
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.reefPaused) private var reefPaused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var finished = false
    @State private var cursor: BloomPlaybackCursor

    init(timing: BloomPlaybackTiming, paused: Bool, @ViewBuilder content: @escaping (Double) -> Content) {
        self.timing = timing; self.paused = paused; self.content = content
        _cursor = State(initialValue: .init(timing: timing))
    }
    private struct Request: Equatable { let timing: BloomPlaybackTiming; let running: Bool }
    private var running: Bool { appeared && !paused && !reefPaused && !reduceMotion && scenePhase == .active && !finished }
    private var request: Request { .init(timing: timing, running: running) }
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !running)) { context in
            content(cursor.phase(at: context.date))
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
        .task(id: request) {
            cursor.update(timing: timing, running: running, at: Date())
            guard running else { return }
            do {
                try await Task.sleep(for: .milliseconds(cursor.remaining(at: Date())))
                guard !Task.isCancelled else { return }
                finished = true
            } catch { /* A speed, scene or pause change replaces this completion task. */ }
        }
    }
}

/// A read-only glimpse aligned with the live board, over a haze of the game.
struct BloomFutureTellerOverlay: View {
    let target: CoralPuzzle
    let finalTap: Int
    let boardFrame: CGRect
    let viewport: CGSize
    var onClose: () -> Void
    @ScaledMetric(relativeTo: .body) private var captionRoom = 48.0

    private var previewFrame: CGRect {
        let availableHeight = max(100, viewport.height - captionRoom * 2 - 90)
        let side = min(boardFrame.width, viewport.width - 44, availableHeight)
        let minY = captionRoom + 14
        let maxY = max(minY, viewport.height - side - captionRoom - 76)
        return CGRect(x: (viewport.width - side) / 2,
                      y: min(maxY, max(minY, boardFrame.minY)), width: side, height: side)
    }

    var body: some View {
        let frame = previewFrame
        ZStack {
            Rectangle().fill(ReefTheme.glass.opacity(0.48))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            ReefIconLabel("Aim for this", .futureTeller, size: 30)
                .reefFont(size: 19, weight: .semibold)
                .multilineTextAlignment(.center)
                .frame(width: viewport.width - 44, height: captionRoom)
                .position(x: viewport.width / 2, y: frame.minY - captionRoom / 2 - 4)
            BloomReviewBoard(puzzle: target, focus: finalTap)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityLabel("Future Teller. Possible final board. Winning tap: row \(finalTap / target.size + 1), column \(finalTap % target.size + 1).")
            Text("Then tap the gold ring.").reefFont(size: 16)
                .multilineTextAlignment(.center)
                .frame(width: viewport.width - 44, height: captionRoom)
                .position(x: viewport.width / 2, y: frame.maxY + captionRoom / 2 + 4)
        }
        .overlay(alignment: .bottom) {
            Button("Keep playing", action: onClose)
                .buttonStyle(ReefButtonStyle(filled: true))
                .padding(.horizontal, 22).padding(.bottom, 16)
        }
        .foregroundStyle(ReefTheme.ink)
    }
}

private struct BloomReviewBoard: View {
    let puzzle: CoralPuzzle
    var focus: Int?
    var frame: BloomMoveFrame?
    var pulse = 0.0
    var onTap: ((Int) -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: puzzle.size), spacing: 8) {
            ForEach(puzzle.cells.indices, id: \.self) { i in
                if puzzle.isGap(i) {
                    Color.clear.aspectRatio(1, contentMode: .fit).accessibilityHidden(true)
                } else {
                    CoralCell(lit: puzzle.cells[i], stone: puzzle.stones.contains(i),
                        current: puzzle.currents.contains(i), vertical: puzzle.isVertical(i), star: puzzle.stars.contains(i),
                        wholeRow: puzzle.isRowCoral(i), wholeColumn: puzzle.isColumnCoral(i), burst: puzzle.isBurst(i), hint: focus == i,
                        seed: Double(i), species: CoralSpecies(rawValue: (i + i / puzzle.size) % 3) ?? .peachSprig,
                        bloom: puzzle.isComplete ? 1 : 0,
                        swell: reduceMotion ? 0 : (frame?.affected.contains(i) == true ? sin(.pi * pulse) * 0.6 : 0)) { onTap?(i) }
                        .allowsHitTesting(onTap != nil && puzzle.canTap(i))
                        .accessibilityLabel("Row \(i / puzzle.size + 1), column \(i % puzzle.size + 1), \(puzzle.stones.contains(i) ? "pebble" : puzzle.cells[i] ? "glowing coral" : "sleepy coral")")
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: puzzle.cells[i])
                }
            }
        }.padding(12).frame(maxWidth: puzzle.size == 1 ? 126 : puzzle.size == 2 ? 228 : 320)
            .background(BloomReefBed(size: puzzle.size, gaps: puzzle.gaps ?? [], complete: puzzle.isComplete))
            .overlay {
                if let frame, let move = frame.move, !reduceMotion, pulse < 1 {
                    BloomMoveGleam(size: puzzle.size, origin: move.index, targets: frame.affected, phase: pulse)
                }
            }
    }
}

/// Little pearls of light trace the real ripple from the tapped coral to its targets.
private struct BloomMoveGleam: View {
    let size: Int
    let origin: Int
    let targets: [Int]
    let phase: Double
    var body: some View {
        Canvas { context, bounds in
            let side = (bounds.width - 24 - CGFloat(size - 1) * 8) / CGFloat(size)
            func center(_ i: Int) -> CGPoint {
                CGPoint(x: 12 + CGFloat(i % size) * (side + 8) + side / 2,
                        y: 12 + CGFloat(i / size) * (side + 8) + side / 2)
            }
            let start = center(origin)
            let travel = ReefMotion.segment(phase, from: 0, to: 1)
            for target in targets {
                let end = center(target)
                let point = CGPoint(x: start.x + (end.x - start.x) * travel, y: start.y + (end.y - start.y) * travel)
                let radius = 2 + 3 * sin(.pi * phase)
                var glow = context
                glow.addFilter(.shadow(color: ReefTheme.gold.opacity(0.8), radius: 7))
                glow.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                          with: .color(ReefTheme.hintCore.opacity(1 - phase * 0.5)))
            }
            let r = side * (0.15 + phase * 0.48)
            context.stroke(Path(ellipseIn: CGRect(x: start.x - r, y: start.y - r, width: r * 2, height: r * 2)),
                           with: .color(ReefTheme.gold.opacity(1 - phase)), lineWidth: 2)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
