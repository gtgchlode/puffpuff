import Foundation

struct CoralPuzzle: Codable {
    let level: Int
    let size: Int
    var cells: [Bool]
    var moves = 0 // Every physical tap, including reversals; used by playback/pearl scores.
    var countedMoves: Int? = nil // Optional for legacy saves; the tap allowance uses this.
    var undoTap: Int? = nil // Only the immediately preceding un-reversed tap can refund.
    var history: [[Bool]] = [] // Retain legacy save data; Restart replaced Undo.
    var recording: BloomRecording? = nil // Actual actions; absent on older attempts.
    var rewarded = false
    var stones: [Int] = []
    var currents: [Int] = []
    var stars: [Int] = []
    // Optional so older saved attempts keep their original tap rules.
    var verticals: [Int]? = nil
    // Repeatable line corals. The entire line reaches across gaps/pebbles,
    // changing only coral; lighter-protected targets remain on.
    var rowCorals: [Int]? = nil
    var columnCorals: [Int]? = nil
    var burstCorals: [Int]? = nil // Self plus all eight adjacent coral; introduced at 85.
    var pearlTarget: Int? = nil
    var feature = "classic"
    // Optional for decoding saves made before the tap-budget content update.
    var tapLimit: Int? = nil
    var contentRevision: Int? = nil
    var extraTaps: Int? = nil
    // A purchased reveal belongs to this exact board, including in a replay checkpoint.
    var revealedHint: Int? = nil
    // A glimpse reveals only a possible final arrangement, never the route to it.
    var futureTellerFinalTap: Int? = nil
    var earnedFutureTeller: Bool? = nil
    var earnedHint: Bool? = nil
    var earnedHints: Int? = nil
    var earnedShot: Bool? = nil
    var earnedShots: Int? = nil
    var earnedLighter: Bool? = nil
    var earnedBouncyBlock: Bool? = nil
    var earnedCurrentAdder:Bool? = nil
    var earnedLifeGift: BloomLifeGift? = nil
    // Keep square coordinates for adjacency, but these slots are open water.
    // Optional so existing boards retain their exact original footprint.
    var gaps: [Int]? = nil
    // A lighter holds one coral on for this attempt. Projecting out that target
    // preserves solvability; its own tap can still affect neighboring coral.
    var lighterCorals: [Int]? = nil
    var unlimitedLifeAttempt: Bool? = nil
    var attemptStarted: Bool? = nil
    // One failed/abandoned attempt can never debit twice, even after more moves.
    var lifeLossHandled: Bool? = nil

    func isGap(_ index: Int) -> Bool { gaps?.contains(index) == true }
    func isVertical(_ index: Int) -> Bool { verticals?.contains(index) == true }
    func isRowCoral(_ index: Int) -> Bool { rowCorals?.contains(index) == true }
    func isColumnCoral(_ index: Int) -> Bool { columnCorals?.contains(index) == true }
    func isBurst(_ index: Int) -> Bool { burstCorals?.contains(index) == true }
    var hasLineCorals: Bool { !(rowCorals ?? []).isEmpty || !(columnCorals ?? []).isEmpty }
    func isCoral(_ index: Int) -> Bool { cells.indices.contains(index) && !isGap(index) && !stones.contains(index) }
    var hasGaps: Bool { !(gaps ?? []).isEmpty }
    var coralIndices: [Int] { cells.indices.filter(isCoral) }
    var isComplete: Bool { coralIndices.allSatisfy { cells[$0] } }
    var baseTapLimit: Int { max(1, tapLimit ?? size * size + 18) }
    var allowedTaps: Int { baseTapLimit + max(0, extraTaps ?? 0) }
    var spentTaps: Int { countedMoves ?? moves }
    var tapsRemaining: Int { max(0, allowedTaps - spentTaps) }
    func canUndoTap(_ index: Int) -> Bool { !isComplete && isCoral(index) && undoTap == index && spentTaps > 0 }
    func canTap(_ index: Int) -> Bool { !isComplete && isCoral(index) && (!isOutOfTaps || canUndoTap(index)) }

    @discardableResult
    mutating func playTap(at index: Int) -> Bool {
        guard canTap(index) else { return false }
        let reversing = canUndoTap(index), spent = spentTaps
        record(.init(kind: .tap, index: index))
        pulse(at: index)
        moves += 1
        countedMoves = spent + (reversing ? -1 : 1)
        undoTap = reversing ? nil : index
        return true
    }
    var isOutOfTaps: Bool { !isComplete && tapsRemaining == 0 }
    var isTutorial: Bool { level <= 4 }
    var awake: Int { coralIndices.filter { cells[$0] }.count }
    var coralCount: Int { coralIndices.count }
    var earnedPearl: Bool { isComplete && pearlTarget.map { moves <= $0 } == true }

    var lesson: String {
        if level <= 10 {
            return switch level {
            case 1: "Tap the sleepy coral inside the gold ring to make it glow."
            case 2: "Tap the gold-ring coral. It flips itself and its side neighbors. Diagonal coral stays as it is."
            case 3: moves == 0 ? "Tap the gold ring. Two glowing neighbors will go sleepy. That's okay — the next tap will wake them." : "Every tap flips both ways: sleepy becomes glowing, and glowing becomes sleepy. Follow the next gold ring."
            case 4: "On a bigger reef, a tap reaches up, down, left, and right. Follow the gold ring to wake all five."
            case 5: "Your turn! One corner tap can wake this whole patch. Hint can show you where."
            case 6: "Two ripples will do it. Look for sleepy coral in opposite corners."
            case 7: "Plan two taps. A glowing coral can be the right place to tap, too."
            case 8, 9: "Take your time. Wake every coral before your taps run out."
            default: "A little more room to bloom. The same neighbor rule works on this bigger reef."
            }
        }
        return switch feature {
        case "pearl": "A pearl bonus! Bloom within \(pearlTarget ?? 0) taps for 1 extra Glow."
        case "stone": "Pebbles rest here. They don't change and can't be tapped."
        case "current": "↔ coral flips itself and its left and right neighbors."
        case "vertical": "↕ coral flips itself and the coral just above and below."
        case "star": "Diagonal coral flips itself and its four diagonal neighbors."
        case "burst": "Burst coral flips itself and every coral around it."
        case "line": "Line coral flips its whole row or column, including itself. Pebbles and water stay as they are."
        case "mixed": [
            stones.isEmpty ? nil : "Pebbles stay still.",
            currents.isEmpty ? nil : "Arrow coral flips itself and its left/right neighbors.",
            (verticals ?? []).isEmpty ? nil : "↕ coral flips itself and the coral just above and below.",
            stars.isEmpty ? nil : "Diagonal coral flips itself and its diagonal neighbors.",
            (burstCorals ?? []).isEmpty ? nil : "Burst coral flips itself and every coral around it.",
            hasLineCorals ? "Line coral flips its whole row or column, including itself." : nil
        ].compactMap { $0 }.joined(separator: " ")
        default: "Tap a coral to flip it and its up, down, left, and right neighbors."
        }
    }

    var teachingTitle: String {
        switch level {
        case 1: "One little light"
        case 2: "Meet the neighbors"
        case 3: "Light flips both ways"
        case 4: "One tap, five corals"
        case 5: "Your first solo bloom"
        default: "Wake the whole reef"
        }
    }

    var completionMessage: String {
        switch level {
        case 1: "You made your first light!"
        case 2: "One tap reached its neighbors."
        case 3: "Sleepy can become glowing again."
        case 4: "You've learned the ripple!"
        case 100: "100 patches of lovely."
        default: "A little bloom. A big smile."
        }
    }

    var nextLessonLabel: String {
        switch level {
        case 1: "Meet the neighbors"
        case 2: "Try two ripples"
        case 3: "Try a bigger reef"
        case 4: "Try it on your own"
        case 100: "Bloom again"
        default: "Next patch"
        }
    }

    static func make(level: Int) -> CoralPuzzle {
        if let packed = BloomPack.levels.first(where: { $0.level == level }) { return packed }
        let size = level <= 6 ? 3 : (level <= 20 ? 4 : 5)
        var random = ReefRandom(seed: UInt64(level) &* 7919 &+ 42)
        let count = size * size
        // Start solved, then apply legal pulses. Every generated board is reachable.
        for _ in 0..<40 {
            var board = Array(repeating: true, count: count)
            let taps = level == 1 ? [4] : Array((0..<count).shuffled(using: &random).prefix(min(count - 2, 2 + level / 3)))
            for tap in taps { pulse(&board, size: size, at: tap) }
            if !board.allSatisfy({ $0 }), let solution = solve(board, size: size), solution.count >= (level == 1 ? 1 : 2) {
                return CoralPuzzle(level: level, size: size, cells: board)
            }
        }
        var board = Array(repeating: true, count: count)
        pulse(&board, size: size, at: count / 2)
        return CoralPuzzle(level: level, size: size, cells: board)
    }

    func affected(at index: Int) -> [Int] {
        guard isCoral(index) else { return [] }
        let row = index / size, column = index % size
        if isRowCoral(index) || isColumnCoral(index) {
            return coralIndices.filter {
                (isRowCoral(index) ? $0 / size == row : $0 % size == column)
                    && !(lighterCorals ?? []).contains($0)
            }
        }
        let offsets: [(Int, Int)] = isBurst(index) ? [(0, 0), (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)] :
            isVertical(index) ? [(0, 0), (-1, 0), (1, 0)] :
            currents.contains(index) ? [(0, 0), (0, -1), (0, 1)] :
            stars.contains(index) ? [(0, 0), (-1, -1), (-1, 1), (1, -1), (1, 1)] :
            [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]
        return offsets.compactMap { dr, dc in
            let r = row + dr, c = column + dc, cell = r * size + c
            return (0..<size).contains(r) && (0..<size).contains(c) && isCoral(cell)
                && !(lighterCorals ?? []).contains(cell) ? cell : nil
        }
    }

    mutating func pulse(at index: Int) { for cell in affected(at: index) { cells[cell].toggle() } }

    func solution() -> [Int]? {
        let targets = cells.indices.map { isCoral($0) ? cells[$0] : true }
        return Self.solve(targets, size: size, affected: { affected(at: $0) })
    }

    /// Build the one-tap-from-winning target independently of the live cells.
    /// With reversible pulses, any legal final pulse is reachable from a solvable board.
    var futureTellerBoard: CoralPuzzle? {
        guard let final = futureTellerFinalTap, isCoral(final), !affected(at: final).isEmpty else { return nil }
        var target = self
        target.cells = Array(repeating: true, count: cells.count)
        target.pulse(at: final)
        target.moves = 0; target.countedMoves = nil; target.undoTap = nil
        target.recording = nil; target.history = []; target.rewarded = false
        return target
    }

    static func neighbors(size: Int, at index: Int) -> [Int] {
        let row = index / size, column = index % size
        return [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)].compactMap { dr, dc in
            let r = row + dr, c = column + dc
            return (0..<size).contains(r) && (0..<size).contains(c) ? r * size + c : nil
        }
    }

    static func pulse(_ board: inout [Bool], size: Int, at index: Int) {
        for cell in neighbors(size: size, at: index) { board[cell].toggle() }
    }

    // Gaussian elimination over GF(2), then minimize over the null space so a
    // hint follows the shortest remaining solution and respects the tap budget.
    static func solve(_ cells: [Bool], size: Int, affected: ((Int) -> [Int])? = nil) -> [Int]? {
        let count = size * size
        guard count < 63, cells.count == count else { return nil }
        let rhs = UInt64(1) << count
        var rows = (0..<count).map { cells[$0] ? UInt64(0) : rhs }
        for move in 0..<count {
            for cell in affected?(move) ?? neighbors(size: size, at: move) { rows[cell] |= UInt64(1) << move }
        }
        var rank = 0
        var pivots: [Int] = []
        for column in 0..<count {
            guard let pivot = (rank..<count).first(where: { rows[$0] & (UInt64(1) << column) != 0 }) else { continue }
            rows.swapAt(rank, pivot)
            for row in 0..<count where row != rank && rows[row] & (UInt64(1) << column) != 0 {
                rows[row] ^= rows[rank]
            }
            pivots.append(column)
            rank += 1
        }
        if rows.contains(where: { $0 & (rhs - 1) == 0 && $0 & rhs != 0 }) { return nil }
        var best = pivots.enumerated().reduce(UInt64(0)) { mask, pair in
            mask | (rows[pair.offset] & rhs != 0 ? UInt64(1) << pair.element : 0)
        }
        let freeColumns = (0..<count).filter { column in
            !pivots.contains(column) && !(affected?(column) ?? neighbors(size: size, at: column)).isEmpty
        }
        let basis = freeColumns.map { column in
            pivots.enumerated().reduce(UInt64(1) << column) { mask, pair in
                mask | (rows[pair.offset] & (UInt64(1) << column) != 0 ? UInt64(1) << pair.element : 0)
            }
        }
        func search(_ position: Int, _ candidate: UInt64) {
            if position == basis.count {
                if candidate.nonzeroBitCount < best.nonzeroBitCount { best = candidate }
                return
            }
            search(position + 1, candidate)
            search(position + 1, candidate ^ basis[position])
        }
        search(0, best)
        return (0..<count).filter { best & (UInt64(1) << $0) != 0 }
    }
}

private enum BloomPack {
    static let levels: [CoralPuzzle] = {
        guard let url = Bundle.main.url(forResource: "BloomLevels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let levels = try? JSONDecoder().decode([CoralPuzzle].self, from: data) else { return [] }
        return levels
    }()
}

private struct ReefRandom: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 {
        seed &+= 0x9E3779B97F4A7C15
        var value = seed
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

struct BloomMove: Codable, Equatable {
    enum Kind: String, Codable { case tap, lighter }
    var kind: Kind
    var index: Int
}

struct BloomRecording: Codable {
    var initialCells: [Bool]
    var moves: [BloomMove] = []
}

struct BloomMoveFrame {
    var cells: [Bool]
    var held: [Int]
    var move: BloomMove?
    var affected: [Int]
    var taps: Int
}

extension CoralPuzzle {
    /// Called before a successful action; the recording shares its save transaction.
    /// An older in-progress attempt cannot have its missing actions reconstructed.
    mutating func record(_ move: BloomMove) {
        if recording == nil {
            guard moves == 0, (lighterCorals ?? []).isEmpty else { return }
            recording = BloomRecording(initialCells: cells)
        }
        guard (recording?.moves.count ?? 0) < 4096 else { recording = nil; return }
        recording?.moves.append(move)
    }

    /// Pure playback, with the same rules as real play, including held-on lighters.
    var recordedFrames: [BloomMoveFrame]? {
        guard let recording, recording.initialCells.count == cells.count,
              !recording.moves.isEmpty, recording.moves.count <= 4096,
              (stones + (gaps ?? [])).allSatisfy({ recording.initialCells[$0] }) else { return nil }
        var board = self
        board.cells = recording.initialCells
        board.moves = 0
        board.lighterCorals = []
        board.recording = nil
        var result = [BloomMoveFrame(cells: board.cells, held: [], move: nil, affected: [], taps: 0)]
        for move in recording.moves {
            guard board.isCoral(move.index), !board.isComplete else { return nil }
            let affected: [Int]
            switch move.kind {
            case .tap:
                affected = board.affected(at: move.index)
                board.pulse(at: move.index)
                board.moves += 1
            case .lighter:
                guard !board.cells[move.index] else { return nil }
                affected = [move.index]
                board.cells[move.index] = true
                board.lighterCorals = (board.lighterCorals ?? []) + [move.index]
            }
            result.append(.init(cells: board.cells, held: board.lighterCorals ?? [],
                                move: move, affected: affected, taps: board.moves))
        }
        guard board.cells == cells, board.moves == moves,
              Set(board.lighterCorals ?? []) == Set(lighterCorals ?? []) else { return nil }
        return result
    }

    /// No shared store, rewards or life state: a disposable attempt at this board.
    func freePractice() -> CoralPuzzle {
        var board = CoralPuzzle.make(level: level)
        if let recording, recordedFrames != nil {
            board = self
            board.cells = recording.initialCells
        }
        board.moves = 0; board.countedMoves = nil; board.undoTap = nil
        board.history = []; board.recording = nil
        board.rewarded = false; board.pearlTarget = nil; board.extraTaps = nil
        board.lighterCorals = nil; board.revealedHint = nil
        board.futureTellerFinalTap = nil; board.earnedFutureTeller = nil
        board.earnedHint = nil; board.earnedHints = nil; board.earnedShot = nil; board.earnedShots = nil
        board.earnedLighter = nil; board.earnedLifeGift = nil; board.earnedCurrentAdder = nil; board.earnedBouncyBlock = nil
        board.attemptStarted = nil; board.unlimitedLifeAttempt = nil; board.lifeLossHandled = nil
        return board
    }
}


/// Retained after advancing for future Pro statistics; not a second reward score.
struct BloomTapTotals: Codable, Equatable {
    let total: Int
    let counted: Int
    var valid: Bool { total >= 0 && counted >= 0 && counted <= total && (total - counted).isMultiple(of: 2) }
}


/// Playback preference: 0 is the relaxed pace, 1 is the earlier quick pace.
/// Phase measures initial hold, actual move intervals, then the final hold.
struct BloomPlaybackTiming: Equatable {
    let moveCount: Int
    let speed: Double
    init(moveCount: Int, speed: Double) {
        self.moveCount = max(0, moveCount)
        self.speed = speed.isFinite ? min(1, max(0, speed)) : 0.5
    }
    private func blend(_ slow: Double, _ fast: Double) -> Double { slow + (fast - slow) * speed }
    var interval: Double {
        let count = Double(max(1, moveCount))
        return blend(min(380, max(220, 6800 / count)), min(240, max(100, 4200 / count)))
    }
    var lead: Double { blend(650, 450) }
    var tail: Double { blend(1400, 1100) }
    var finalPhase: Double { Double(moveCount) + 2 }
    var duration: Double { lead + Double(moveCount) * interval + tail }
    func phase(at milliseconds: Double) -> Double {
        let t = max(0, milliseconds)
        if t < lead { return t / lead }
        let end = lead + Double(moveCount) * interval
        if t < end { return 1 + (t - lead) / interval }
        return min(finalPhase, Double(moveCount) + 1 + (t - end) / tail)
    }
    func time(at phase: Double) -> Double {
        let p = min(finalPhase, max(0, phase))
        if p < 1 { return p * lead }
        if p < Double(moveCount) + 1 { return lead + (p - 1) * interval }
        return lead + Double(moveCount) * interval + (p - Double(moveCount) - 1) * tail
    }
}

/// Anchors the current action and its in-flight ripple when speed or pause changes.
struct BloomPlaybackCursor {
    private(set) var timing: BloomPlaybackTiming
    private(set) var settledPhase = 0.0
    private var began: Date?
    init(timing: BloomPlaybackTiming) { self.timing = timing }
    func phase(at now: Date) -> Double {
        let elapsed = began.map { max(0, now.timeIntervalSince($0) * 1000) } ?? 0
        return timing.phase(at: timing.time(at: settledPhase) + elapsed)
    }
    mutating func update(timing: BloomPlaybackTiming, running: Bool, at now: Date) {
        settledPhase = phase(at: now)
        self.timing = timing
        began = running ? now : nil
    }
    func remaining(at now: Date) -> Double { max(0, timing.duration - timing.time(at: phase(at: now))) }
}
