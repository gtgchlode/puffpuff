import Foundation
import Observation
import StoreKit

struct ReefObstacle: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let position: Double
    let cost: Int
}

struct ReefStop: Identifiable {
    let id: Int
    let name: String
    let subtitle: String
    let symbol: String
    let obstacles: [ReefObstacle]
    var treasure: String { ["Sunbeam pearl", "Sea-glass ribbon", "Tiny pearl crown", "Rose shell", "Moonstone", "Starfish charm", "Coral compass", "Mermaid's button", "Golden seahorse", "Heart of the reef"][id] }
    var treasureSymbol: String { ["circle.fill", "seal.fill", "crown.fill", "fossil.shell.fill", "moon.fill", "star.fill", "safari.fill", "seal.fill", "fish.fill", "heart.fill"][id] }

    static let all: [ReefStop] = [
        ReefStop(id: 0, name: "Sunbeam Bay", subtitle: "A little light, a little adventure", symbol: "sun.max.fill", obstacles: [
            .init(id: "0-kelp", name: "Tangled kelp", symbol: "leaf.fill", position: 0.29, cost: 2),
            .init(id: "0-shell", name: "Sleepy shell", symbol: "fossil.shell.fill", position: 0.74, cost: 3)
        ]),
        ReefStop(id: 1, name: "Ribbon Reef", subtitle: "Follow the friendly current", symbol: "water.waves", obstacles: [
            .init(id: "1-kelp", name: "Ribbon kelp", symbol: "leaf.fill", position: 0.24, cost: 3),
            .init(id: "1-rock", name: "Pebble pile", symbol: "mountain.2.fill", position: 0.67, cost: 3)
        ]),
        ReefStop(id: 2, name: "Pearl Garden", subtitle: "Something lovely is growing", symbol: "sparkles", obstacles: [
            .init(id: "2-shell", name: "Pearl shell", symbol: "fossil.shell.fill", position: 0.25, cost: 3),
            .init(id: "2-kelp", name: "Curly kelp", symbol: "leaf.fill", position: 0.55, cost: 2),
            .init(id: "2-rock", name: "Pebble arch", symbol: "mountain.2.fill", position: 0.82, cost: 4)
        ]),
        ReefStop(id: 3, name: "Peachy Lagoon", subtitle: "Take the scenic route", symbol: "heart.fill", obstacles: [
            .init(id: "3-kelp", name: "Peachy kelp", symbol: "leaf.fill", position: 0.32, cost: 4),
            .init(id: "3-shell", name: "Giant shell", symbol: "fossil.shell.fill", position: 0.77, cost: 4)
        ]),
        ReefStop(id: 4, name: "Moonpool Cove", subtitle: "A soft glow after sunset", symbol: "moon.stars.fill", obstacles: [
            .init(id: "4-rock", name: "Moon stones", symbol: "mountain.2.fill", position: 0.28, cost: 4),
            .init(id: "4-kelp", name: "Silver kelp", symbol: "leaf.fill", position: 0.71, cost: 5)
        ]),
        ReefStop(id: 5, name: "Starlight Shelf", subtitle: "Look how far you've grown", symbol: "star.fill", obstacles: [
            .init(id: "5-kelp", name: "Starlit kelp", symbol: "leaf.fill", position: 0.22, cost: 4),
            .init(id: "5-shell", name: "Star shell", symbol: "fossil.shell.fill", position: 0.56, cost: 4),
            .init(id: "5-rock", name: "Last little ridge", symbol: "mountain.2.fill", position: 0.84, cost: 5)
        ]),
        ReefStop(id: 6, name: "Coral Castle", subtitle: "A tiny kingdom under the sea", symbol: "crown.fill", obstacles: [
            .init(id: "6-shell", name: "Castle shell", symbol: "fossil.shell.fill", position: 0.25, cost: 4),
            .init(id: "6-rock", name: "Coral arch", symbol: "mountain.2.fill", position: 0.58, cost: 5),
            .init(id: "6-kelp", name: "Royal kelp", symbol: "leaf.fill", position: 0.82, cost: 4)
        ]),
        ReefStop(id: 7, name: "Seaglass Grotto", subtitle: "Little treasures catch the light", symbol: "diamond.fill", obstacles: [
            .init(id: "7-kelp", name: "Glass-green kelp", symbol: "leaf.fill", position: 0.31, cost: 5),
            .init(id: "7-shell", name: "Opal shell", symbol: "fossil.shell.fill", position: 0.69, cost: 5)
        ]),
        ReefStop(id: 8, name: "Golden Wreck", subtitle: "Someone left a lovely surprise", symbol: "sailboat.fill", obstacles: [
            .init(id: "8-rock", name: "Sunken stones", symbol: "mountain.2.fill", position: 0.23, cost: 5),
            .init(id: "8-kelp", name: "Anchor kelp", symbol: "leaf.fill", position: 0.53, cost: 4),
            .init(id: "8-shell", name: "Golden shell", symbol: "fossil.shell.fill", position: 0.81, cost: 5)
        ]),
        ReefStop(id: 9, name: "Heart of the Reef", subtitle: "Every little bloom brought you here", symbol: "heart.circle.fill", obstacles: [
            .init(id: "9-kelp", name: "Heartleaf kelp", symbol: "leaf.fill", position: 0.24, cost: 5),
            .init(id: "9-shell", name: "Rainbow shell", symbol: "fossil.shell.fill", position: 0.55, cost: 5),
            .init(id: "9-rock", name: "Treasure ridge", symbol: "mountain.2.fill", position: 0.83, cost: 6)
        ])
    ]
}

enum ReefScreen: String, Codable { case bloom, trail }

enum ReefDebugSupply: String, CaseIterable, Identifiable {
    case glow, hints, lives, lighters, boosts, futureTellers

    var id: String { rawValue }
    var name: String { self == .futureTellers ? "Future Tellers" : self == .glow ? "Lumes" : self == .boosts ? "saved boost" : rawValue }
    var amount: Int {
        switch self {
        case .glow: 25
        case .hints: 3
        case .lives: 5
        case .lighters: 3
        case .boosts: 1
        case .futureTellers: 3
        }
    }
    var symbol: String {
        switch self {
        case .glow: "sparkles"
        case .hints: "lightbulb.fill"
        case .lives: "heart.fill"
        case .lighters: "flame.fill"
        case .boosts: "infinity"
        case .futureTellers: "sparkles"
        }
    }
    var balance: WritableKeyPath<ReefProgress, Int> {
        switch self {
        case .glow: \.glow
        case .hints: \.hints
        case .lives: \.supplies.lives
        case .lighters: \.supplies.lighters
        case .boosts: \.supplies.unlimitedBoosts
        case .futureTellers: \.futureTellers
        }
    }
}

struct TapRefillRecord: Codable, Identifiable {
    enum Source: String, Codable { case purchasePreview, adPreview }
    var id = UUID()
    let date: Date
    let level: Int
    let taps: Int
    let source: Source
}

struct ReefPurchaseEntitlement: Codable {
    let transactionID: String
    let productID: String
    let purchaseDate: Date
}

struct HintRefillRecord: Codable, Identifiable {
    enum Source: String, Codable { case purchasePreview, adPreview }
    var id = UUID()
    let date: Date
    let hints: Int
    let source: Source
}

enum BloomLifeGift: String, Codable {
    case instant, refill, stored

    static func reward(forRoll roll:Int)->Self? {
        switch roll {
        case 0..<30: .instant       // 3%: refill + immediate 15 minutes.
        case 30..<80: .refill       // 5%: refill only.
        case 100..<105: .stored     // Keep the existing 0.5% rare bucket.
        default: nil
        }
    }
}

/// Real-time supplies are saved with gameplay. Gifts may exceed the natural life cap.
struct BloomSupplies: Codable, Equatable {
    static let lifeCap = 5
    static let refillInterval: TimeInterval = 5 * 60
    static let boostDuration: TimeInterval = 15 * 60
    var lives = lifeCap
    var nextLifeAt: Date?
    var unlimitedUntil: Date?
    var unlimitedBoosts = 0
    var lighters = 0

    func unlimited(at now: Date = Date()) -> Bool { (unlimitedUntil ?? .distantPast) > now }
    func refreshed(at now: Date = Date()) -> Self {
        var next = self
        if lives < Self.lifeCap, let due = nextLifeAt, now >= due {
            let earned = min(Self.lifeCap - lives, Int(min(Double(Self.lifeCap), floor(now.timeIntervalSince(due) / Self.refillInterval) + 1)))
            next.lives += earned
            next.nextLifeAt = next.lives >= Self.lifeCap ? nil : due.addingTimeInterval(Double(earned) * Self.refillInterval)
        }
        if next.lives >= Self.lifeCap { next.nextLifeAt = nil }
        if let until = next.unlimitedUntil, until <= now { next.unlimitedUntil = nil }
        return next
    }
    mutating func loseLife(at now: Date) {
        self = refreshed(at: now)
        guard lives > 0 else { return }
        lives -= 1
        if lives < Self.lifeCap && nextLifeAt == nil { nextLifeAt = now.addingTimeInterval(Self.refillInterval) }
    }
    mutating func refillLives(at now:Date = Date()) {
        self = refreshed(at:now)
        lives = max(lives,Self.lifeCap)
        nextLifeAt = nil
    }
    mutating func activateBoost(at now: Date = Date()) {
        refillLives(at:now)
        unlimitedUntil = max(now, unlimitedUntil ?? now).addingTimeInterval(Self.boostDuration)
    }

    mutating func addLives(_ count: Int, at now: Date = Date()) {
        self = refreshed(at: now)
        lives += count
        if lives >= Self.lifeCap { nextLifeAt = nil }
    }
}

enum ReefDiscovery:String,Codable,CaseIterable,Identifiable {
    case glow,snack,hint,life,lighter,instantBoost,storedBoost,shot,current,currentAdder,bouncyBlock,futureTeller
    var id:String {rawValue}
    var isGolfSupply: Bool { [.shot,.current,.currentAdder,.bouncyBlock].contains(self) }
}

/// A session-only receipt. Saved tutorial records never schedule popups on their own.
struct ReefDiscoveryReceipt: Identifiable {
    enum Source: Equatable { case bloom(Int), trail }
    let id = UUID()
    let source: Source
    let items: [ReefDiscovery]
}

enum ReefIntroKind { case trail }

struct ReefProgress: Codable {
    var version = 32
    var firstReef = FirstReefProgress()
    var glow = 0
    var shots = 0 // Legacy golf inventory: retained for existing saves, never granted or spent here.
    var hints = 3
    var currentChangers = 0
    var currentAdders = 0
    var bouncyBlocks = 0
    var futureTellers = 0
    var futureTellerUnlocked: Bool { completedBloomLevels.contains(where: { $0 >= 50 }) }
    var bloomRewardWins = 0
    var hasSeenTrailIntro = false
    var hasSeenBonusIntro = false
    var supplies = BloomSupplies()
    var learnedDiscoveries:Set<ReefDiscovery> = []
    var pendingDiscoveries:[ReefDiscovery] = []
    var lifeGiftSeed = UInt64.random(in: 1...UInt64.max)
    var puzzle = CoralPuzzle.make(level: 1)
    // Present during replays or debug jumps. Keep the full original board,
    // including its taps, undo history and reward flag, across app launches.
    var bloomResumePuzzle: CoralPuzzle?
    var clearedObjects: Set<String> = []
    var restoredStops: Set<Int> = []
    var distances: [String: Double] = [:]
    var bloomChapterComplete = false
    var savedAt: Date?
    var activeScreen: ReefScreen = .bloom
    var activeStopID: Int?
    var lastTrailStopID: Int?
    var completedBloomLevels: Set<Int> = []
    var bestBloomMoves: [String: Int] = [:]
    var lastBloomTapTotals: [String: BloomTapTotals] = [:]
    var refillHistory: [TapRefillRecord] = []
    var hintRefillHistory: [HintRefillRecord] = []
    // This is a local cache. StoreKit verification remains the authority.
    var purchaseEntitlements: [ReefPurchaseEntitlement] = []

    init() {}

    private enum CodingKeys: String, CodingKey {
        case learnedDiscoveries, pendingDiscoveries, bloomRewardWins, hasSeenTrailIntro, hasSeenBonusIntro
        case version, firstReef, glow, shots, puzzle, clearedObjects, restoredStops, distances, bloomChapterComplete
        case savedAt, activeScreen, activeStopID, lastTrailStopID, completedBloomLevels, bestBloomMoves, lastBloomTapTotals
        case refillHistory, purchaseEntitlements, bloomResumePuzzle, hints, hintRefillHistory, supplies, lifeGiftSeed, currentChangers, currentAdders, bouncyBlocks, futureTellers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let storedVersion = try values.decode(Int.self, forKey: .version)
        guard (1...32).contains(storedVersion) else { throw ReefSaveError.newerVersion }
        version = storedVersion
        hasSeenTrailIntro = try values.decodeIfPresent(Bool.self, forKey: .hasSeenTrailIntro) ?? false
        hasSeenBonusIntro = try values.decodeIfPresent(Bool.self, forKey: .hasSeenBonusIntro) ?? false
        if storedVersion >= 17 {
            learnedDiscoveries = try values.decode(Set<ReefDiscovery>.self,forKey:.learnedDiscoveries)
            pendingDiscoveries = try values.decode([ReefDiscovery].self,forKey:.pendingDiscoveries)
        }
        futureTellers = try values.decodeIfPresent(Int.self,forKey:.futureTellers) ?? 0
        bouncyBlocks = try values.decodeIfPresent(Int.self,forKey:.bouncyBlocks) ?? 0
        currentAdders = try values.decodeIfPresent(Int.self,forKey:.currentAdders) ?? 0
        currentChangers = storedVersion >= 16 ? try values.decode(Int.self, forKey: .currentChangers) : 0
        if storedVersion >= 13 { lifeGiftSeed = try values.decode(UInt64.self, forKey: .lifeGiftSeed) }
        firstReef = storedVersion >= 5 ? try values.decode(FirstReefProgress.self, forKey: .firstReef) : FirstReefProgress()
        glow = try values.decode(Int.self, forKey: .glow)
        shots = try values.decode(Int.self, forKey: .shots)
        puzzle = try values.decode(CoralPuzzle.self, forKey: .puzzle)
        bloomResumePuzzle = try values.decodeIfPresent(CoralPuzzle.self, forKey: .bloomResumePuzzle)
        guard (1...185).contains(puzzle.level) else { throw ReefSaveError.invalidData }
        clearedObjects = try values.decode(Set<String>.self, forKey: .clearedObjects)
        restoredStops = try values.decode(Set<Int>.self, forKey: .restoredStops)
        distances = try values.decode([String: Double].self, forKey: .distances)
        bloomChapterComplete = try values.decodeIfPresent(Bool.self, forKey: .bloomChapterComplete) ?? false
        savedAt = try values.decodeIfPresent(Date.self, forKey: .savedAt)
        activeScreen = try values.decodeIfPresent(ReefScreen.self, forKey: .activeScreen) ?? .bloom
        activeStopID = try values.decodeIfPresent(Int.self, forKey: .activeStopID)
        lastTrailStopID = try values.decodeIfPresent(Int.self, forKey: .lastTrailStopID)
        // The original game advances sequentially, so earlier patches were completed.
        completedBloomLevels = try values.decodeIfPresent(Set<Int>.self, forKey: .completedBloomLevels)
            ?? (bloomChapterComplete ? Set(1...100) : Set(1..<puzzle.level))
        bestBloomMoves = try values.decodeIfPresent([String: Int].self, forKey: .bestBloomMoves) ?? [:]
        lastBloomTapTotals = try values.decodeIfPresent([String: BloomTapTotals].self, forKey: .lastBloomTapTotals) ?? [:]
        refillHistory = try values.decodeIfPresent([TapRefillRecord].self, forKey: .refillHistory) ?? []
        purchaseEntitlements = try values.decodeIfPresent([ReefPurchaseEntitlement].self, forKey: .purchaseEntitlements) ?? []
        if puzzle.isComplete {
            completedBloomLevels.insert(puzzle.level)
            if bestBloomMoves[String(puzzle.level)] == nil { bestBloomMoves[String(puzzle.level)] = puzzle.moves }
        }
        bloomRewardWins = storedVersion >= 20
            ? try values.decode(Int.self,forKey:.bloomRewardWins)
            : completedBloomLevels.count
        // Honor milestones earned before hints became collectible, once on migration.
        // Version 4 requires its balance: a damaged inventory must never silently refill.
        if storedVersion < 4 {
            hints = 3 + completedBloomLevels.filter { $0.isMultiple(of: 5) }.count + restoredStops.count
        } else {
            hints = try values.decode(Int.self, forKey: .hints)
        }
        hintRefillHistory = try values.decodeIfPresent([HintRefillRecord].self, forKey: .hintRefillHistory) ?? []
        if storedVersion >= 11 {
            supplies = try values.decode(BloomSupplies.self, forKey: .supplies)
        } else {
            // The player's pre-update attempt is already in progress; never charge it retroactively.
            puzzle.attemptStarted = true
            bloomResumePuzzle?.attemptStarted = true
            // Credit the new contents of already opened chests exactly once on upgrade.
            if firstReef.treasures.contains("hint-shell") { supplies.addLives(2) }
            if firstReef.treasures.contains("shot-pearl") { supplies.lighters += 1 }
            if firstReef.treasures.contains("coral-cache") { supplies.unlimitedBoosts += 1 }
        }
        if storedVersion < 12 {
            // Old attempts were prepaid (or grandfathered). Preserve balances and
            // never charge them a second time under the new loss-only rules.
            if puzzle.attemptStarted == true { puzzle.lifeLossHandled = true }
            if bloomResumePuzzle?.attemptStarted == true { bloomResumePuzzle?.lifeLossHandled = true }
        }
    }
}

struct PuffResult {
    let from: Double
    let to: Double
    let aim: Double
    let blockedBy: String?
    var reachedPearl: Bool { to >= 1 }
}

@MainActor @Observable
final class ReefStore {
    /// Separate salted streams keep the win and pearl hint chances independent.
    /// The saved win ordinal makes retries/reloads repeat the same outcome.
    static func bonusHints(seed:UInt64,win:Int,pearl:Bool)->Int {
        func roll(_ salt:UInt64)->UInt64 {
            var value=(seed ^ salt) &+ UInt64(win) &* 0x9E3779B97F4A7C15
            value=(value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value=(value ^ (value >> 27)) &* 0x94D049BB133111EB
            value ^= value >> 31
            return value % 1000
        }
        let winHint=roll(0x48494E545F57494E)<80 ? 1:0
        let pearlHints=pearl && roll(0x504541524C48494E)<50 ? 2:0
        return winHint+pearlHints
    }
    static func hasFutureTeller(seed: UInt64, win: Int) -> Bool {
        // Rare, independent 2% stream. The saved ordinal prevents rerolling.
        var value=(seed ^ 0x465554555245544C) &+ UInt64(win) &* 0x9E3779B97F4A7C15
        value=(value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value=(value ^ (value >> 27)) &* 0x94D049BB133111EB
        value ^= value >> 31
        return value % 1000 < 20
    }
    private(set) var discoveryReceipt: ReefDiscoveryReceipt?
    @ObservationIgnored private var stagedDiscoveryReceipt: ReefDiscoveryReceipt?

    func cancelDiscoveryReceipt() { discoveryReceipt = nil }
    func discoveryItems(for receiptID: UUID) -> [ReefDiscovery] {
        guard let receipt=discoveryReceipt,receipt.id==receiptID else{return []}
        return receipt.items.filter{progress.pendingDiscoveries.contains($0) && !progress.learnedDiscoveries.contains($0)}
    }

    // The authored Glow campaign currently runs through level 185.
    static let levelLimit = 185
    static let refillTapCount = 5
    static let hintBundleCount = 3
    private(set) var progress: ReefProgress
    var hint: Int?
    var hintMessage: String?
    var notice: String?
    private(set) var bloomTrailGuidance = false
    private(set) var testingToolsEnabled = ReefTestingEnvironment.isTestingBuild
    @ObservationIgnored private var checkingTestingEnvironment = false
    @ObservationIgnored private let testingEnvironment: () async -> Bool
    private let saveFile: ReefSaveFile
    private(set) var isSaveBlocked = false
    private(set) var lastSaveFailed = false

    init(defaults: UserDefaults = .standard, saveDirectory: URL? = nil,
         testingEnvironment: @escaping () async -> Bool = ReefTestingEnvironment.verifiedSandbox) {
        self.testingEnvironment = testingEnvironment
        saveFile = ReefSaveFile(defaults: defaults, directory: saveDirectory)
        let loaded = saveFile.load()
        progress = loaded.progress ?? ReefProgress()
        progress.version = 32
        isSaveBlocked = loaded.blocked
        notice = loaded.message
        guard !isSaveBlocked else { return }
        let contentChanged = refreshPuzzleContent()
        let trailChanged = refreshFirstReefLayout()
        if loaded.needsSave || contentChanged || trailChanged { save() }
        refreshGuidance()
        refreshLives()
    }

    /// Build access is immediate. Future public builds may verify sandbox access; never save permission.
    func refreshTestingAccess() async {
        guard !ReefTestingEnvironment.isTestingBuild, !checkingTestingEnvironment else { return }
        checkingTestingEnvironment = true
        defer { checkingTestingEnvironment = false }
        testingToolsEnabled = await testingEnvironment()
    }

    @discardableResult
    func startDebugLevel(_ level: Int) -> Bool {
        guard testingToolsEnabled else { return false }
        return startFromLevel(level, replayCompleted: true)
    }

    /// Resume the current board without paying for or uncovering anything.
    @discardableResult
    func playBloomForGlow() -> Bool {
        guard startFromLevel(min(puzzle.level, Self.levelLimit)) else { return false }
        notice = nil
        bloomTrailGuidance = true
        return true
    }

    private func refreshFirstReefLayout() -> Bool {
        var changed = false
        if (progress.firstReef.layoutRevision ?? 1) < 3 {
            progress.firstReef = FirstReef.migrated(progress.firstReef)
            changed = true
        }
        if progress.firstReef.coveSearches == nil {
            progress.firstReef = ReefCove.migrate(progress.firstReef)
            changed = true
        }
        if progress.firstReef.glowPuzzleRevision == nil {
            // Keep already-opened golf caches open without pretending they awarded Bloom items.
            let oldSupplyAreas: Set<String> = ["south","ribbon-cove","shell-shelf","fin-lookout","dead-end"]
            progress.firstReef.legacyGolfFinds = Set(FirstReef.destinations.flatMap { ReefCove.objects(in:$0.id) }.filter {
                (progress.firstReef.coveSearches ?? []).contains($0.id)
                    && ($0.slot == 4 || oldSupplyAreas.contains($0.area) && $0.isGift)
            }.map(\.id))
            progress.firstReef.glowPuzzleRevision = 1
            progress.firstReef.nextWorldUnlocked = progress.firstReef.completed
            changed = true
        }
        if progress.firstReef.rescueRevision == nil {
            // Past visits and paid quest items keep their credit. No balances or boards change.
            let rescued=progress.firstReef.hasFoundHome
            progress.firstReef.rescueRevision=1
            progress.firstReef.bubbaRescued=rescued
            progress.firstReef.homeDecorations=[]
            if rescued { progress.firstReef.coveSearches=(progress.firstReef.coveSearches ?? []).union(["home:2"]) }
            progress.firstReef.completed=rescued && progress.firstReef.food.count == 3
            progress.firstReef.nextWorldUnlocked=progress.firstReef.completed
            changed=true
        }
        return changed
    }

    // Update budgets on both the active board and the exact latest checkpoint.
    // Extra taps, moves, revealed hints and the coral arrangement are retained.
    private func refreshPuzzleContent() -> Bool {
        func update(_ puzzle: inout CoralPuzzle) -> Bool {
            let started = puzzle.attemptStarted, boosted = puzzle.unlimitedLifeAttempt
            let lossHandled = puzzle.lifeLossHandled
            let updated = CoralPuzzle.make(level: puzzle.level)
            guard (puzzle.contentRevision ?? 0) < (updated.contentRevision ?? 0) else { return false }
            // Keep earned currency, trail progress, and completed puzzles. Only
            // unfinished opening boards change to the gentler teaching layouts.
            if (puzzle.contentRevision ?? 0) < 2 && puzzle.level <= 10 && !puzzle.isComplete {
                puzzle = updated
            } else if (puzzle.size != updated.size ||
                       (puzzle.level >= 46 && puzzle.level <= 60 && (puzzle.contentRevision ?? 0) < 9) ||
                       (puzzle.level >= 61 && puzzle.level <= 70 && (puzzle.contentRevision ?? 0) < 10) ||
                       (puzzle.level >= 71 && (puzzle.contentRevision ?? 0) < 11) ||
                       (!(puzzle.cagedCorals ?? []).isEmpty && (puzzle.contentRevision ?? 0) < 14) ||
                       ((161...185).contains(puzzle.level) && (puzzle.contentRevision ?? 0) < 15) ||
                       (puzzle.gaps ?? []) != (updated.gaps ?? []) ||
                       puzzle.stones != updated.stones || puzzle.currents != updated.currents ||
                       puzzle.stars != updated.stars ||
                       (puzzle.verticals ?? []) != (updated.verticals ?? []) ||
                       (puzzle.rowCorals ?? []) != (updated.rowCorals ?? []) ||
                       (puzzle.columnCorals ?? []) != (updated.columnCorals ?? []) ||
                       (puzzle.burstCorals ?? []) != (updated.burstCorals ?? []) ||
                       (puzzle.linkedPairs ?? []) != (updated.linkedPairs ?? []) ||
                       (puzzle.cagedCorals ?? []) != (updated.cagedCorals ?? []) ||
                       puzzle.miniCells != updated.miniCells ||
                       (puzzle.miniColorCorals ?? []) != (updated.miniColorCorals ?? []) ||
                       (puzzle.miniPatterns ?? []) != (updated.miniPatterns ?? []) ||
                       (puzzle.miniOrder ?? []) != (updated.miniOrder ?? []) ||
                       puzzle.specialLevel != updated.specialLevel), puzzle.moves == 0,
                      (puzzle.level < 71 || puzzle.attemptStarted != true),
                      puzzle.history.isEmpty, puzzle.revealedHint == nil, puzzle.futureTellerFinalTap == nil,
                      (puzzle.lighterCorals ?? []).isEmpty,
                      (puzzle.extraTaps ?? 0) == 0, !puzzle.rewarded, !puzzle.isComplete {
                // Only untouched boards adopt a new layout. An attempt or saved
                // checkpoint keeps its cells, hints and footprint until Restart.
                puzzle = updated
            } else {
                puzzle.tapLimit = max(puzzle.baseTapLimit, updated.baseTapLimit)
                puzzle.contentRevision = updated.contentRevision
            }
            puzzle.attemptStarted = started
            puzzle.unlimitedLifeAttempt = boosted
            puzzle.lifeLossHandled = lossHandled
            return true
        }
        var changed = update(&progress.puzzle)
        if progress.bloomChapterComplete && !progress.completedBloomLevels.contains(Self.levelLimit) {
            progress.bloomChapterComplete = false
            changed = true
        }
        if var resume = progress.bloomResumePuzzle {
            if update(&resume) { changed = true }
            progress.bloomResumePuzzle = resume
        }
        return changed
    }

    var puzzle: CoralPuzzle { progress.puzzle }
    var isComplete: Bool { puzzle.isComplete }
    var isOutOfTaps: Bool { puzzle.isOutOfTaps }
    var latestBloomLevel: Int { (progress.bloomResumePuzzle ?? puzzle).level }
    var canPlayBloom: Bool {
        isComplete || puzzle.attemptStarted == true
    }
    var canStartBloom: Bool { progress.supplies.refreshed().lives > 0 || progress.supplies.unlimited() }

    /// Called in the same transaction as selecting/restarting the board.
    private func beginBloomAttempt(allowPaidRestart: Bool = false) -> Bool {
        guard !isComplete, puzzle.attemptStarted != true else { return true }
        let now = Date()
        progress.supplies = progress.supplies.refreshed(at: now)
        if progress.supplies.unlimited(at: now) {
            progress.puzzle.unlimitedLifeAttempt = true
        } else {
            guard progress.supplies.lives > 0 || allowPaidRestart else { return false }
        }
        progress.puzzle.attemptStarted = true
        return true
    }

    var restartCostsLife: Bool {
        puzzle.attemptStarted == true && !isComplete && puzzle.lifeLossHandled != true
            && puzzle.unlimitedLifeAttempt != true && !progress.supplies.unlimited()
            && progress.supplies.refreshed().lives > 0
    }

    /// Failure and abandonment share a persisted, once-per-attempt debit.
    private func resolveBloomLoss() {
        guard puzzle.attemptStarted == true, !isComplete, puzzle.lifeLossHandled != true else { return }
        let now = Date()
        progress.supplies = progress.supplies.refreshed(at: now)
        if puzzle.unlimitedLifeAttempt != true && !progress.supplies.unlimited(at: now) {
            progress.supplies.loseLife(at: now)
        }
        progress.puzzle.lifeLossHandled = true
    }

    @discardableResult
    func startBloomAttempt() -> Bool {
        guard !isSaveBlocked else { return false }
        let previous = progress
        guard beginBloomAttempt() else { progress = previous; return false }
        if save() { refreshGuidance(); return true }
        progress = previous
        return false
    }

    /// Offline reward preview; replace with a verified rewarded-ad grant later.
    @discardableResult
    func claimFreeLifeRefill() -> Bool {
        guard !isSaveBlocked else { return false }
        let previous = progress
        progress.supplies.addLives(3)
        queueDiscoveries(from:previous)
        if save() { return true }
        progress = previous
        return false
    }

    func refreshLives() {
        guard !isSaveBlocked else { return }
        let updated = progress.supplies.refreshed()
        guard updated != progress.supplies else { return }
        let previous = progress
        progress.supplies = updated
        if !save() { progress = previous }
    }

    @discardableResult
    func activateUnlimitedLives() -> Bool {
        guard !isSaveBlocked, progress.supplies.unlimitedBoosts > 0 else { return false }
        let previous = progress, now = Date()
        progress.supplies = progress.supplies.refreshed(at: now)
        progress.supplies.unlimitedBoosts -= 1
        grantLifeGift(.instant, at: now)
        queueDiscoveries(from:previous)
        if save() { return true }
        progress = previous
        return false
    }

    // Stable per-save rolls: replaying, reopening or retrying a failed save cannot
    // reroll a reward. Only first-time wins and one-time Trail finds call this.
    private func lifeGift(for event: String) -> BloomLifeGift? {
        var hash = progress.lifeGiftSeed ^ 14695981039346656037
        for byte in event.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        hash = (hash ^ (hash >> 30)) &* 0xbf58476d1ce4e5b9
        hash = (hash ^ (hash >> 27)) &* 0x94d049bb133111eb
        hash ^= hash >> 31
        return BloomLifeGift.reward(forRoll:Int(hash % 1000))
    }

    private func grantLifeGift(_ gift: BloomLifeGift, at now: Date = Date()) {
        if gift == .stored {
            progress.supplies.unlimitedBoosts += 1
        } else if gift == .refill {
            progress.supplies.refillLives(at:now)
        } else {
            progress.supplies.activateBoost(at: now)
            if puzzle.attemptStarted == true && !isComplete { progress.puzzle.unlimitedLifeAttempt = true }
        }
    }

    // Temporary prototype entry points: beginning is a replay, never a save reset.
    @discardableResult
    func startFromBeginning() -> Bool {
        guard testingToolsEnabled, !isSaveBlocked else { return false }
        let previous = progress
        if progress.bloomResumePuzzle == nil { progress.bloomResumePuzzle = puzzle }
        else { resolveBloomLoss() }
        progress.puzzle = .make(level: 1)
        _ = beginBloomAttempt()
        progress.activeScreen = .bloom
        progress.activeStopID = nil
        refreshGuidance()
        if save() { return true }
        progress = previous
        refreshGuidance()
        return false
    }

    @discardableResult
    func startFromLatest() -> Bool {
        guard !isSaveBlocked else { return false }
        if latestBloomLevel > Self.levelLimit { return startFromLevel(Self.levelLimit) }
        let previous = progress
        if let saved = progress.bloomResumePuzzle { resolveBloomLoss(); progress.puzzle = saved }
        progress.bloomResumePuzzle = nil
        _ = beginBloomAttempt()
        progress.activeScreen = .bloom
        progress.activeStopID = nil
        refreshGuidance()
        if save() { return true }
        progress = previous
        refreshGuidance()
        return false
    }

    // Temporary debugging entry point. A jump in either direction retains the
    // exact original board; entering its level later resumes that checkpoint.
    @discardableResult
    func startFromLevel(_ level: Int, replayCompleted: Bool = false) -> Bool {
        guard !isSaveBlocked, (1...Self.levelLimit).contains(level), !replayCompleted || testingToolsEnabled else { return false }
        let previous = progress
        if level != puzzle.level {
            if let saved = progress.bloomResumePuzzle, saved.level == level {
                resolveBloomLoss()
                progress.puzzle = saved
                progress.bloomResumePuzzle = nil
            } else {
                if progress.bloomResumePuzzle == nil { progress.bloomResumePuzzle = puzzle }
                else { resolveBloomLoss() }
                progress.puzzle = .make(level: level)
            }
        }
        if replayCompleted && puzzle.isComplete {
            if progress.bloomResumePuzzle == nil {progress.bloomResumePuzzle=puzzle}
            progress.puzzle = .make(level:level)
        }
        _ = beginBloomAttempt()
        progress.activeScreen = .bloom
        progress.activeStopID = nil
        refreshGuidance()
        if save() { return true }
        progress = previous
        refreshGuidance()
        return false
    }

    func navigate(to screen: ReefScreen) {
        guard !isSaveBlocked else { return }
        progress.activeScreen = screen
        if screen == .trail { bloomTrailGuidance = false }
        if screen == .bloom { progress.activeStopID = nil }
        save()
    }

    func rememberStop(_ stop: ReefStop?) {
        guard !isSaveBlocked else { return }
        progress.activeStopID = stop?.id
        if let stop {
            progress.activeScreen = .trail
            progress.lastTrailStopID = stop.id
        }
        save()
    }

    func checkpoint() { if !isSaveBlocked { save() } }

    func reloadSavedProgress() {
        let loaded = saveFile.load()
        if let saved = loaded.progress,
           isSaveBlocked || (!lastSaveFailed && (saved.savedAt ?? .distantPast) > (progress.savedAt ?? .distantPast)) {
            progress = saved
            progress.version = 32
            isSaveBlocked = false
            let contentChanged = refreshPuzzleContent()
            let trailChanged = refreshFirstReefLayout()
            if loaded.needsSave || contentChanged || trailChanged { save() }
            refreshGuidance()
            refreshLives()
        }
        if let message = loaded.message { notice = message }
    }

    @discardableResult
    func rememberPurchaseEntitlements(_ entitlements: [ReefPurchaseEntitlement]) -> Bool {
        guard !isSaveBlocked else { return false }
        progress.purchaseEntitlements = entitlements
        return save()
    }

    func tapCoral(_ index: Int) {
        guard !isSaveBlocked, canPlayBloom, puzzle.canTap(index) else { return }
        let previous = progress
        bloomTrailGuidance = false
        hint = nil
        hintMessage = nil
        progress.puzzle.revealedHint = nil
        progress.puzzle.playTap(at: index)
        rewardBloomIfComplete()
        if isOutOfTaps { resolveBloomLoss() }
        if !save() { progress = previous }
        refreshGuidance()
    }

    private func rewardBloomIfComplete() {
        if isComplete && !progress.puzzle.rewarded {
            let before=progress
            progress.glow += puzzle.earnedPearl ? 4 : 3
            progress.puzzle.rewarded = true
            progress.puzzle.futureTellerFinalTap = nil
            let firstBloom = progress.completedBloomLevels.insert(puzzle.level).inserted
            if firstBloom, puzzle.level > 4, let gift = lifeGift(for: "bloom-\(puzzle.level)") {
                grantLifeGift(gift)
                progress.puzzle.earnedLifeGift = gift
            }
            // Renewable supplies: a newly won replay counts, reopening a win does not.
            progress.bloomRewardWins += 1
            let milestoneHint=firstBloom && puzzle.level.isMultiple(of:5) ? 1:0
            let hints=milestoneHint+Self.bonusHints(seed:progress.lifeGiftSeed,win:progress.bloomRewardWins,pearl:puzzle.earnedPearl)
            if hints>0 {
                progress.hints += hints
                progress.puzzle.earnedHint=true
                progress.puzzle.earnedHints=hints
            }
            if progress.futureTellerUnlocked,
               Self.hasFutureTeller(seed: progress.lifeGiftSeed, win: progress.bloomRewardWins) {
                progress.futureTellers += 1
                progress.puzzle.earnedFutureTeller = true
            }
            // First-clear supplies: lighters join the existing Trail pickups.
            if firstBloom && puzzle.level.isMultiple(of: 7) {
                progress.supplies.lighters += 1
                progress.puzzle.earnedLighter = true
            }
            let key = String(puzzle.level)
            progress.bestBloomMoves[key] = min(progress.bestBloomMoves[key] ?? puzzle.moves, puzzle.moves)
            progress.lastBloomTapTotals[key] = .init(total: puzzle.moves, counted: puzzle.spentTaps)
            if puzzle.level == Self.levelLimit { progress.bloomChapterComplete = true }
            queueDiscoveries(from:before,source:.bloom(puzzle.level))
        }
    }

    @discardableResult
    func restartPuzzle(usingAdLife: Bool = false) -> Bool {
        guard !isSaveBlocked, !isComplete, usingAdLife ? !canStartBloom : canStartBloom else { return false }
        let previous = progress
        // Resolve the old attempt before the ad grant, so its loss cannot
        // consume the one life intended for the new attempt.
        resolveBloomLoss()
        if usingAdLife { progress.supplies.addLives(1) }
        progress.puzzle = .make(level: puzzle.level)
        // Eligibility was checked before the loss. Spending the final life funds
        // this new attempt; a zero balance blocks only the following restart.
        _ = beginBloomAttempt(allowPaidRestart: !usingAdLife)
        if usingAdLife { queueDiscoveries(from:previous) }
        let saved = save()
        if !saved { progress = previous }
        refreshGuidance()
        return saved
    }

    @discardableResult
    func lightCoral(_ index: Int) -> Bool {
        guard !isSaveBlocked, canPlayBloom, !isComplete, puzzle.isCoral(index), !puzzle.isCaged(index),
              !puzzle.cells[index], progress.supplies.lighters > 0 else { return false }
        let previous = progress
        progress.puzzle.record(.init(kind: .lighter, index: index))
        progress.puzzle.undoTap = nil
        progress.puzzle.undoTapRefundable = nil
        progress.supplies.lighters -= 1
        progress.puzzle.cells[index] = true
        progress.puzzle.lighterCorals = (puzzle.lighterCorals ?? []) + [index]
        // Keep the purchased glimpse useful if a lighter removes every target
        // of its old final pulse. This adjustment never spends another item.
        if let final = puzzle.futureTellerFinalTap, puzzle.affected(at: final).isEmpty {
            progress.puzzle.futureTellerFinalTap = puzzle.solution()?.last
        }
        progress.puzzle.revealedHint = nil
        rewardBloomIfComplete()
        let saved = save()
        if !saved { progress = previous }
        refreshGuidance()
        return saved
    }

    // Both prototype choices grant immediately for free. A future commerce/ad
    // integration must grant only after its purchase or reward is confirmed.
    func claimFreeTapRefill(source: TapRefillRecord.Source = .purchasePreview) {
        guard !isSaveBlocked, isOutOfTaps else { return }
        let previous = progress
        // Include any over-budget moves from a legacy save so the player
        // receives exactly five usable taps, even on an older attempt.
        progress.puzzle.extraTaps = max(0, puzzle.spentTaps - puzzle.baseTapLimit) + Self.refillTapCount
        progress.refillHistory.append(TapRefillRecord(date: Date(), level: puzzle.level, taps: Self.refillTapCount, source: source))
        if !save() { progress = previous }
        refreshGuidance()
    }

    /// Purchase one stable ending to aim for. Reopening it is free this attempt.
    @discardableResult
    func showFutureTeller() -> Bool {
        guard !isSaveBlocked, canPlayBloom, !isComplete, !puzzle.isTutorial,
              progress.futureTellerUnlocked else { return false }
        if puzzle.futureTellerBoard != nil { return true }
        guard !isOutOfTaps, progress.futureTellers > 0 else { return false }
        guard let solution = puzzle.solution(), solution.count <= puzzle.tapsRemaining,
              let final = solution.last else {
            hintMessage = "More taps needed. Future Teller kept."
            return false
        }
        let previous = progress
        progress.futureTellers -= 1
        progress.puzzle.futureTellerFinalTap = final
        if save() { return true }
        progress = previous
        return false
    }

    /// Returns false only when the player needs more hints. Never spends a tap.
    @discardableResult
    func showHint() -> Bool {
        guard !isSaveBlocked, canPlayBloom, !isComplete, !isOutOfTaps else { return true }
        if puzzle.isTutorial || puzzle.revealedHint != nil {
            refreshGuidance()
            return true
        }
        guard let solution = puzzle.solution(), solution.count <= puzzle.tapsRemaining,
              let next = solution.first else {
            hintMessage = "Restart for fresh taps. No hint used."
            return true
        }
        guard progress.hints > 0 else { return false }
        let previous = progress
        progress.hints -= 1
        progress.puzzle.revealedHint = next
        // Save the debit and reveal together; a failed save spends nothing.
        if !save() { progress = previous }
        refreshGuidance()
        return true
    }

    @discardableResult
    func claimFreeHints(source: HintRefillRecord.Source) -> Bool {
        guard !isSaveBlocked, progress.hints == 0 else { return false }
        let previous = progress
        let count = source == .purchasePreview ? Self.hintBundleCount : 1
        progress.hints += count
        progress.hintRefillHistory.append(.init(date: Date(), hints: count, source: source))
        if source == .purchasePreview,canPlayBloom,!isComplete,!isOutOfTaps,
           !puzzle.isTutorial,puzzle.revealedHint == nil,
           let solution=puzzle.solution(),solution.count<=puzzle.tapsRemaining,let next=solution.first {
            progress.hints -= 1
            progress.puzzle.revealedHint = next
        }
        queueDiscoveries(from:previous)
        if save() { refreshGuidance(); return true }
        progress = previous
        return false
    }

    private func refreshGuidance() {
        hint = nil
        hintMessage = nil
        guard !isComplete, !isOutOfTaps else { return }
        if let revealed = puzzle.revealedHint {
            hint = revealed
            hintMessage = "Tap the gold ring."
            return
        }
        guard puzzle.isTutorial else { return }
        if let solution = puzzle.solution(), solution.count <= puzzle.tapsRemaining {
            hint = solution.first
        } else {
            hintMessage = "Restart for fresh taps, then follow the gold ring."
        }
    }

    func nextPuzzle() {
        guard !isSaveBlocked, isComplete, puzzle.level < Self.levelLimit else { return }
        let previous = progress
        let nextLevel = puzzle.level + 1
        if let saved = progress.bloomResumePuzzle, nextLevel == saved.level {
            // Catching up to the latest patch resumes the original attempt.
            progress.puzzle = saved
            progress.bloomResumePuzzle = nil
        } else {
            progress.puzzle = .make(level: nextLevel)
        }
        _ = beginBloomAttempt()
        if !save() { progress = previous }
        refreshGuidance()
    }

    /// Finish and Skip acknowledge the same introduction. Merely opening it does not.
    @discardableResult
    func finishIntro(_ kind: ReefIntroKind) -> Bool {
        guard !isSaveBlocked else { return false }
        let previous = progress
        switch kind {
        case .trail:
            if progress.hasSeenTrailIntro { return true }
            progress.hasSeenTrailIntro = true
        }
        if save() { return true }
        progress = previous
        return false
    }

    @discardableResult
    func addDebugSupply(_ supply: ReefDebugSupply) -> Bool {
        guard testingToolsEnabled, !isSaveBlocked else { return false }
        let (balance, overflow) = progress[keyPath: supply.balance].addingReportingOverflow(supply.amount)
        guard !overflow else { return false }
        let previous = progress
        progress[keyPath: supply.balance] = balance
        progress.supplies = progress.supplies.refreshed()
        queueDiscoveries(from:previous)
        if save() { return true }
        progress = previous
        return false
    }

    func visitFirstReef(_ id: String) -> ReefJourney? {
        guard !isSaveBlocked,
              let destination = FirstReef.destinations.first(where: { $0.id == id }) else { return nil }
        let cost = FirstReef.cost(to: destination, from: progress.firstReef)
        guard progress.glow >= cost,
              var journey = FirstReef.visit(destination, from: progress.firstReef) else { return nil }
        let previous = progress
        progress.glow -= cost
        progress.firstReef = journey.outcome
        for treasureID in journey.newTreasures {
            let loot=FirstReef.node(treasureID).loot
            progress.hints += loot.hints
            progress.supplies.lighters += loot.lighters
            if loot.lives > 0 { progress.supplies.addLives(loot.lives) }
            if loot.instantBoost {
                grantLifeGift(.instant)
                journey.lifeGift = .instant
            }
        }
        if journey.lifeGift == nil && (!journey.newFood.isEmpty || !journey.newTreasures.isEmpty || journey.clearedObstacle != nil) {
            if let gift = lifeGift(for: "trail-\(id)") {
                grantLifeGift(gift)
                journey.lifeGift = gift
            }
        }
        queueDiscoveries(from:previous,source:.trail)
        if save() { return journey }
        progress = previous
        return nil
    }

    var canVisitHome:Bool { progress.firstReef.hasRestoredHome || !(progress.firstReef.homeDecorations ?? []).isEmpty }
    var isHomeShopUnlocked:Bool { progress.firstReef.completed }

    @discardableResult
    func buyHomeItem(_ item:ReefHomeItem)->Bool {
        guard !isSaveBlocked,isHomeShopUnlocked,progress.glow>=item.cost,
              !(progress.firstReef.homeDecorations ?? []).contains(item.rawValue) else{return false}
        let previous=progress
        var room=progress.firstReef.furnishedRoom
        guard let space=room.firstSpace(for:item) else{return false}
        room.placements[item.id] = .init(position:space)
        progress.glow -= item.cost
        progress.firstReef.homeDecorations=(progress.firstReef.homeDecorations ?? []).union([item.rawValue])
        progress.firstReef.homeRoom=room
        if save() {return true}
        progress=previous;return false
    }

    /// Moving, storing and using owned furnishings never spend or grant resources.
    @discardableResult
    func arrangeHomeItem(_ item:ReefHomeItem,placement:ReefHomePlacement?)->Bool {
        guard !isSaveBlocked,(progress.firstReef.homeDecorations ?? []).contains(item.id) else{return false}
        var room=progress.firstReef.furnishedRoom
        if let placement {
            guard room.canPlace(item,at:placement.position) else{return false}
            room.placements[item.id]=placement
        } else {room.placements.removeValue(forKey:item.id)}
        guard room != progress.firstReef.furnishedRoom else{return true}
        let previous=progress
        progress.firstReef.homeRoom=room
        if save() {return true}
        progress=previous;return false
    }

    @discardableResult
    func setHomeLantern(_ lit:Bool)->Bool {
        guard !isSaveBlocked,progress.firstReef.furnishedRoom.placements[ReefHomeItem.pearlLantern.id] != nil else{return false}
        var room=progress.firstReef.furnishedRoom
        guard room.lanternOn != lit else{return true}
        let previous=progress;room.lanternOn=lit;progress.firstReef.homeRoom=room
        if save() {return true}
        progress=previous;return false
    }

    func uncoverCove(_ id:String)->ReefJourney? {
        guard !isSaveBlocked,
              let object=ReefCove.objects(in:progress.firstReef.location ?? "start").first(where:{$0.id == id}),
              progress.glow>=object.cost,
              var journey=ReefCove.uncover(object,from:progress.firstReef) else{return nil}
        let previous=progress
        progress.glow -= object.cost
        applyCoveReward(object,journey:&journey)
        queueDiscoveries(from:previous,source:.trail)
        if save() {return journey}
        progress=previous;return nil
    }

    private func applyCoveReward(_ object:ReefCove.Object,journey:inout ReefJourney) {
        progress.firstReef=journey.outcome
        if let reward=journey.outcome.clearingRewards?[object.id] {
            switch reward {
            case .hint:progress.hints += 1
            case .life:progress.supplies.addLives(1)
            case .lighter:progress.supplies.lighters += 1
            default:break
            }
        }
        switch object.find {
        case .hint:progress.hints += 1
        case .lives:progress.supplies.addLives(2)
        case .lighter:progress.supplies.lighters += 1
        default:break
        }
        for treasure in journey.newTreasures {
            let loot=FirstReef.node(treasure).loot
            progress.hints += loot.hints
            progress.supplies.lighters += loot.lighters
            if loot.lives>0 {progress.supplies.addLives(loot.lives)}
            if loot.instantBoost {grantLifeGift(.instant);journey.lifeGift = .instant}
        }
        // Retain legacy event keys for original rewards; never reroll them after migration.
        if journey.lifeGift == nil,object.find == .food || object.find == .treasure || journey.clearedObstacle != nil,
           let gift=lifeGift(for:"trail-\(object.area)") {
            grantLifeGift(gift);journey.lifeGift=gift
        }
    }

    private func queueDiscoveries(from old:ReefProgress,source:ReefDiscoveryReceipt.Source? = nil) {
        var gained:[ReefDiscovery]=[]
        if progress.glow>old.glow {gained.append(.glow)}
        if progress.firstReef.food.count>old.firstReef.food.count {gained.append(.snack)}
        if progress.hints>old.hints {gained.append(.hint)}
        if progress.futureTellers>old.futureTellers {gained.append(.futureTeller)}
        if (progress.supplies.unlimitedUntil ?? .distantPast)>(old.supplies.unlimitedUntil ?? .distantPast) {gained.append(.instantBoost)}
        else if progress.supplies.lives>old.supplies.lives {gained.append(.life)}
        if progress.supplies.unlimitedBoosts>old.supplies.unlimitedBoosts {gained.append(.storedBoost)}
        if progress.supplies.lighters>old.supplies.lighters {gained.append(.lighter)}
        let unlearned=gained.filter{!progress.learnedDiscoveries.contains($0)}
        if let source,!unlearned.isEmpty {
            stagedDiscoveryReceipt = .init(source:source,items:unlearned)
        }
        for item in unlearned where !progress.pendingDiscoveries.contains(item) {
            progress.pendingDiscoveries.append(item)
        }
    }

    @discardableResult
    func acknowledgeDiscovery(_ item:ReefDiscovery)->Bool {
        guard !isSaveBlocked,progress.pendingDiscoveries.contains(item) else{return false}
        let previous=progress
        progress.pendingDiscoveries.removeAll{$0==item};progress.learnedDiscoveries.insert(item)
        if save() {return true}
        progress=previous;return false
    }

    @discardableResult
    func restartEverything()->Bool {
        guard testingToolsEnabled, !isSaveBlocked else{return false}
        let previous=progress
        do {try saveFile.archiveBeforeReset()} catch {
            notice="Couldn't back up your reef. Nothing was reset.";return false
        }
        progress=ReefProgress();progress.activeScreen = .trail
        progress.purchaseEntitlements=previous.purchaseEntitlements
        if save() {hint=nil;hintMessage=nil;notice=nil;refreshGuidance();return true}
        progress=previous;return false
    }

    @discardableResult
    private func save() -> Bool {
        defer { stagedDiscoveryReceipt = nil }
        guard !isSaveBlocked else { return false }
        var snapshot = progress
        snapshot.savedAt = Date()
        do {
            try saveFile.write(snapshot)
            progress.savedAt = snapshot.savedAt
            lastSaveFailed = false
            if let receipt=stagedDiscoveryReceipt {discoveryReceipt=receipt}
            return true
        } catch {
            lastSaveFailed = true
            notice = "Your latest changes couldn't be saved. Keep puffpuff open and try Save again in your saved reef."
            return false
        }
    }
}


enum ReefTestingEnvironment {
    /// Current beta archives deliberately expose tools to every tester, even offline.
    /// Remove PUFFPUFF_BETA_TOOLS from Release before a public App Store release.
    static var isTestingBuild: Bool {
        #if DEBUG || PUFFPUFF_BETA_TOOLS || targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    static func verifiedSandbox() async -> Bool {
        do {
            guard case .verified(let app) = try await AppTransaction.shared,
                  app.bundleID == Bundle.main.bundleIdentifier else { return false }
            return app.environment == .sandbox || app.environment == .xcode
        } catch {
            // Retry on foreground/Settings. Never prompt for sign-in or enable
            // tools from a receipt filename, UserDefaults, or a saved game flag.
            return false
        }
    }
}
