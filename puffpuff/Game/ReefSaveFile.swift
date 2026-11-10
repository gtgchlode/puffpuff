import Foundation

enum ReefSaveError: Error { case invalidData, newerVersion }

struct ReefLoadedSave {
    var progress: ReefProgress?
    var message: String?
    var blocked = false
    var needsSave = false
}

/// Small, versioned local snapshots. Atomic replacement protects interrupted
/// writes; the preceding valid snapshot is retained as a separate backup.
struct ReefSaveFile {
    private let defaults: UserDefaults
    private let directory: URL
    private var primary: URL { directory.appendingPathComponent("progress.json") }
    private var backup: URL { directory.appendingPathComponent("progress-backup.json") }

    init(defaults: UserDefaults, directory: URL? = nil) {
        self.defaults = defaults
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("puffpuff", isDirectory: true)
    }

    func load() -> ReefLoadedSave {
        var foundUnreadableSave = false
        for (index, url) in [primary, backup].enumerated() {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                let saved = try decode(Data(contentsOf: url))
                return ReefLoadedSave(progress: saved,
                    message: index == 1 ? "Your last save couldn't be opened, so puffpuff recovered the previous backup. The original file is kept for recovery." : nil,
                    needsSave: index == 1 || saved.version < 32)
            } catch ReefSaveError.newerVersion {
                return ReefLoadedSave(message: "This reef was saved by a newer version of puffpuff. Update the app to continue. Your save has been kept.", blocked: true)
            } catch { foundUnreadableSave = true }
        }
        // Import the existing prototype save once; leave the original untouched.
        if let data = defaults.data(forKey: "PuffPuffReef.native.v1") {
            do {
                return ReefLoadedSave(progress: try decode(data),
                    message: foundUnreadableSave ? "puffpuff recovered your earlier local save. The unreadable files are kept for recovery." : nil,
                    needsSave: true)
            } catch ReefSaveError.newerVersion {
                return ReefLoadedSave(message: "This reef needs a newer version of puffpuff. Your save has been kept.", blocked: true)
            } catch { foundUnreadableSave = true }
        }
        if foundUnreadableSave {
            return ReefLoadedSave(message: "Your saved reef couldn't be opened. It has been kept safely; puffpuff won't replace it with a new game.", blocked: true)
        }
        return ReefLoadedSave(progress: ReefProgress(), needsSave: true)
    }

    func write(_ progress: ReefProgress) throws {
        try validate(progress)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(progress)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: primary.path) {
            let previous = try Data(contentsOf: primary)
            var validPrevious = false
            do {
                _ = try decode(previous)
                validPrevious = true
            } catch ReefSaveError.newerVersion {
                throw ReefSaveError.newerVersion
            } catch {
                // Preserve unreadable data before replacing it with a recovered save.
                let recovery = directory.appendingPathComponent("recovery-\(UUID().uuidString).json")
                try previous.write(to: recovery, options: .atomic)
            }
            if validPrevious { try previous.write(to: backup, options: .atomic) }
        }
        try data.write(to: primary, options: .atomic)
    }

    func archiveBeforeReset() throws {
        let folder=directory.appendingPathComponent("reset-backups/\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        for source in [primary,backup] where FileManager.default.fileExists(atPath:source.path) {
            try FileManager.default.copyItem(at:source,to:folder.appendingPathComponent(source.lastPathComponent))
        }
    }

    private func decode(_ data: Data) throws -> ReefProgress {
        let progress = try JSONDecoder().decode(ReefProgress.self, from: data)
        try validate(progress)
        return progress
    }

    private func validate(_ progress: ReefProgress) throws {
        guard Set(progress.pendingDiscoveries).count == progress.pendingDiscoveries.count,
              progress.learnedDiscoveries.isDisjoint(with:progress.pendingDiscoveries) else {throw ReefSaveError.invalidData}
        guard progress.lastBloomTapTotals.allSatisfy({ key, value in
            Int(key).map { (1...185).contains($0) } == true && value.valid
        }) else { throw ReefSaveError.invalidData }
        try validatePuzzle(progress.puzzle)
        if progress.version >= 11 {
            for puzzle in [progress.puzzle, progress.bloomResumePuzzle].compactMap({ $0 }) {
                guard (puzzle.moves == 0 && (puzzle.lighterCorals ?? []).isEmpty && !puzzle.isComplete)
                        || puzzle.attemptStarted == true,
                      puzzle.unlimitedLifeAttempt != true || puzzle.attemptStarted == true
                else { throw ReefSaveError.invalidData }
            }
        }
        if let resume = progress.bloomResumePuzzle {
            try validatePuzzle(resume)
            // Format 7 permits debug jumps above the preserved original board.
            if progress.version < 7 {
                guard resume.level >= progress.puzzle.level else { throw ReefSaveError.invalidData }
            }
        }
        let obstacleIDs = Set(ReefStop.all.flatMap { $0.obstacles.map(\.id) })
        guard progress.lifeGiftSeed != 0 else { throw ReefSaveError.invalidData }
        let supplies = progress.supplies
        guard supplies.lives >= 0, supplies.lighters >= 0, supplies.unlimitedBoosts >= 0,
              supplies.lives >= BloomSupplies.lifeCap || supplies.nextLifeAt != nil,
              supplies.nextLifeAt.map({ $0.timeIntervalSinceReferenceDate.isFinite }) ?? true,
              supplies.unlimitedUntil.map({ $0.timeIntervalSinceReferenceDate.isFinite }) ?? true
        else { throw ReefSaveError.invalidData }
        guard (0..<Int.max).contains(progress.bloomRewardWins),
              (progress.version < 29 || progress.firstReef.glowPuzzleRevision == 1),
              (progress.version < 30 || progress.firstReef.rescueRevision == 1),
              (progress.version < 8 || progress.firstReef.layoutRevision == 3), FirstReef.valid(progress.firstReef), progress.glow >= 0, progress.shots >= 0, progress.hints >= 0, progress.futureTellers >= 0, progress.currentChangers >= 0, progress.currentAdders >= 0, progress.bouncyBlocks >= 0,
              progress.version < 16 || progress.firstReef.coveSearches != nil,
              progress.version < 16 || progress.firstReef.bonus == nil ||
                (progress.firstReef.bonus?.currents != nil &&
                 (progress.firstReef.bonus?.courseRevision == BonusCourse.revision ||
                  progress.firstReef.bonus?.courseRevision == 2 || progress.firstReef.bonus?.courseRevision == 3)),
              progress.hintRefillHistory.allSatisfy({ $0.hints > 0 }),
              progress.clearedObjects.isSubset(of: obstacleIDs),
              progress.restoredStops.allSatisfy({ (0..<10).contains($0) }),
              progress.completedBloomLevels.allSatisfy({ (1...185).contains($0) }),
              progress.bestBloomMoves.allSatisfy({ key, moves in Int(key).map { (1...185).contains($0) } == true && moves >= 0 }),
              progress.distances.allSatisfy({ key, distance in Int(key).map { (0..<10).contains($0) } == true && distance.isFinite && (0...1).contains(distance) }),
              progress.activeStopID.map({ (0..<10).contains($0) }) ?? true,
              progress.lastTrailStopID.map({ (0..<10).contains($0) }) ?? true
        else { throw ReefSaveError.invalidData }
    }

    private func validatePuzzle(_ puzzle: CoralPuzzle) throws {
        guard puzzle.earnedLifeGift == nil || (puzzle.isComplete && puzzle.rewarded) else { throw ReefSaveError.invalidData }
        if let hints=puzzle.earnedHints {
            guard (1...4).contains(hints),puzzle.earnedHint == true,puzzle.isComplete,puzzle.rewarded else {throw ReefSaveError.invalidData}
        }
        guard puzzle.earnedShot != true || (puzzle.isComplete && puzzle.rewarded) else { throw ReefSaveError.invalidData }
        if let shots=puzzle.earnedShots {
            guard (1...2).contains(shots),puzzle.earnedShot == true,puzzle.isComplete,puzzle.rewarded else {throw ReefSaveError.invalidData}
        }
        guard puzzle.earnedFutureTeller != true || (puzzle.isComplete && puzzle.rewarded) else {throw ReefSaveError.invalidData}
        guard puzzle.earnedBouncyBlock != true || (puzzle.isComplete && puzzle.rewarded) else {throw ReefSaveError.invalidData}
        guard puzzle.earnedCurrentAdder != true || (puzzle.isComplete && puzzle.rewarded) else {throw ReefSaveError.invalidData}
        guard puzzle.earnedLighter != true || (puzzle.isComplete && puzzle.rewarded) else { throw ReefSaveError.invalidData }
        guard BloomTapTotals(total: puzzle.moves, counted: puzzle.spentTaps).valid,
              puzzle.undoTap == nil || (puzzle.isCoral(puzzle.undoTap!) && puzzle.spentTaps > 0),
              puzzle.undoTapRefundable != true || puzzle.undoTap != nil
        else { throw ReefSaveError.invalidData }
        let indices = Set(puzzle.cells.indices)
        let gaps = Set(puzzle.gaps ?? [])
        let verticals = Set(puzzle.verticals ?? [])
        let rows = Set(puzzle.rowCorals ?? []), columns = Set(puzzle.columnCorals ?? [])
        let bursts = Set(puzzle.burstCorals ?? [])
        let linkedPairs = puzzle.linkedPairs ?? []
        let linkedTiles = linkedPairs.flatMap { $0 }
        let cages = Set(puzzle.cagedCorals ?? [])
        let miniColors = puzzle.miniColorCorals ?? []
        let miniPatterns = puzzle.miniPatterns ?? []
        let miniOrder = puzzle.miniOrder ?? []
        let ruleTiles = [puzzle.stones, puzzle.currents, puzzle.stars, puzzle.verticals ?? [],
                         puzzle.rowCorals ?? [], puzzle.columnCorals ?? [], puzzle.burstCorals ?? [], puzzle.gaps ?? [],
                         linkedTiles, Array(cages), miniColors].flatMap { $0 }
        let lighterCorals = Set(puzzle.lighterCorals ?? [])
        guard (1...185).contains(puzzle.level), (1...6).contains(puzzle.size),
              puzzle.cells.count == puzzle.size * puzzle.size, puzzle.moves >= 0,
              puzzle.history.count <= 100, puzzle.history.allSatisfy({ $0.count == puzzle.cells.count }),
              Set(puzzle.stones + puzzle.currents + puzzle.stars).isSubset(of: indices),
              gaps.isSubset(of: indices), gaps.count == (puzzle.gaps ?? []).count,
              gaps.isDisjoint(with: puzzle.stones + puzzle.currents + puzzle.stars),
              verticals.isSubset(of: indices), verticals.count == (puzzle.verticals ?? []).count,
              verticals.isDisjoint(with: puzzle.stones + puzzle.currents + puzzle.stars + Array(gaps)),
              rows.isSubset(of: indices), columns.isSubset(of: indices), bursts.isSubset(of: indices),
              linkedPairs.allSatisfy({ $0.count >= 2 && $0.count <= puzzle.cells.count && Set($0).count == $0.count }),
              linkedTiles.count == Set(linkedTiles).count, Set(linkedTiles).isSubset(of: indices),
              cages.count == (puzzle.cagedCorals ?? []).count, cages.isSubset(of: indices),
              Set(ruleTiles).count == ruleTiles.count,
              lighterCorals.count == (puzzle.lighterCorals ?? []).count,
              lighterCorals.allSatisfy({ puzzle.isCoral($0) && puzzle.cells[$0] }),
              gaps.allSatisfy({ puzzle.cells[$0] }), puzzle.coralCount > 0,
              puzzle.stones.allSatisfy({ puzzle.cells[$0] }),
              cages.allSatisfy({ puzzle.isCoral($0) }),
              (puzzle.tapLimit ?? 1) > 0, (puzzle.extraTaps ?? 0) >= 0
        else { throw ReefSaveError.invalidData }
        if let mini = puzzle.miniCells {
            guard mini.count == 4, miniColors.count == 4, Set(miniColors).count == 4,
                  miniColors.allSatisfy({ puzzle.isCoral($0) }),
                  miniPatterns.count == 4,
                  miniPatterns.allSatisfy({ !$0.isEmpty && Set($0).count == $0.count && $0.allSatisfy { (0..<mini.count).contains($0) } }),
                  miniOrder.count == 4, Set(miniOrder) == Set(0..<4),
                  (0...miniOrder.count).contains(puzzle.miniStep ?? 0)
            else { throw ReefSaveError.invalidData }
        } else if puzzle.miniColorCorals != nil || puzzle.miniPatterns != nil || puzzle.miniOrder != nil || puzzle.miniStep != nil {
            throw ReefSaveError.invalidData
        }
        if let final = puzzle.futureTellerFinalTap {
            guard puzzle.isCoral(final), !puzzle.isTutorial, !puzzle.isComplete,
                  !puzzle.affected(at: final).isEmpty else { throw ReefSaveError.invalidData }
        }
        if puzzle.recording != nil, puzzle.recordedFrames == nil { throw ReefSaveError.invalidData }
        if let hint = puzzle.revealedHint {
            guard puzzle.isCoral(hint),
                  !puzzle.isTutorial, !puzzle.isComplete, !puzzle.isOutOfTaps
            else { throw ReefSaveError.invalidData }
        }
    }

}
