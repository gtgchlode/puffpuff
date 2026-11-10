import Foundation

@main struct CheckTestingAccess {
    @MainActor static func main() async throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let defaults = UserDefaults(suiteName: "puffpuff-testing-access-\(UUID())")!
        func equal<T: Encodable>(_ a: T, _ b: T) -> Bool {
            let e = JSONEncoder(); e.outputFormatting = .sortedKeys
            return try! e.encode(a) == e.encode(b)
        }
        func fixture(_ name: String, check: @escaping () async -> Bool) throws -> (ReefStore, URL) {
            var p = ReefProgress(); p.hasSeenTrailIntro = true; p.activeScreen = .trail
            p.puzzle = .make(level: 12); p.puzzle.attemptStarted = true
            p.puzzle.playTap(at: p.puzzle.coralIndices[0])
            p.glow = 0; p.shots = 7; p.hints = 4
            let dir = root.appendingPathComponent(name)
            try ReefSaveFile(defaults: defaults, directory: dir).write(p)
            return (ReefStore(defaults: defaults, saveDirectory: dir, testingEnvironment: check), dir)
        }
        #if PUFFPUFF_BETA_TOOLS
        #if DEBUG
        preconditionFailure("Test beta archives without DEBUG, using optimized Release code")
        #endif
        precondition(ReefTestingEnvironment.isTestingBuild)
        var verificationCalls = 0
        let (beta, betaDir) = try fixture("beta") { verificationCalls += 1; return false }
        let betaBefore = beta.progress
        precondition(beta.testingToolsEnabled, "Every tester has tools immediately, before an environment check")
        await beta.refreshTestingAccess()
        precondition(verificationCalls == 0 && beta.testingToolsEnabled)
        precondition(equal(beta.progress, betaBefore), "Enabling tools does not edit player data")
        precondition(beta.addDebugSupply(.glow) && beta.progress.glow == 25)
        precondition(beta.addDebugSupply(.hints) && beta.progress.hints == 7)
        precondition(equal(beta.puzzle, betaBefore.puzzle))
        precondition(beta.startDebugLevel(58) && beta.puzzle.level == 58)
        precondition(equal(beta.progress.bloomResumePuzzle, betaBefore.puzzle))
        await beta.refreshTestingAccess()
        precondition(verificationCalls == 0 && beta.testingToolsEnabled)
        let reloadedBeta = ReefStore(defaults: defaults, saveDirectory: betaDir, testingEnvironment: { false })
        precondition(reloadedBeta.testingToolsEnabled && reloadedBeta.puzzle.level == 58)
        precondition(reloadedBeta.startFromBeginning() && reloadedBeta.puzzle.level == 1)
        precondition(reloadedBeta.restartEverything())
        precondition(FileManager.default.fileExists(atPath: betaDir.appendingPathComponent("reset-backups").path))
        print("Optimized beta archive: tools on immediately; failed/offline StoreKit never called; refills, replay, relaunch and backed-up reset work.")
        #else
        precondition(!ReefTestingEnvironment.isTestingBuild, "Run this test without DEBUG on macOS")
        var sandbox = false
        let (app, dir) = try fixture("access") { sandbox }
        let before = app.progress
        await app.refreshTestingAccess()
        precondition(!app.testingToolsEnabled)
        precondition(!app.addDebugSupply(.glow) && !app.startDebugLevel(58))
        precondition(!app.startFromBeginning() && !app.startFromLevel(58, replayCompleted: true))
        precondition(!app.restartEverything() && equal(app.progress, before))
        precondition(!FileManager.default.fileExists(atPath: dir.appendingPathComponent("reset-backups").path))
        sandbox = true; await app.refreshTestingAccess()
        precondition(app.testingToolsEnabled && app.addDebugSupply(.glow))
        precondition(app.progress.glow == 25 && equal(app.puzzle, before.puzzle))
        precondition(app.startDebugLevel(58) && app.puzzle.level == 58)
        precondition(equal(app.progress.bloomResumePuzzle, before.puzzle))
        // An App Store installation loading a beta save must not inherit access.
        let production = ReefStore(defaults: defaults, saveDirectory: dir, testingEnvironment: { false })
        await production.refreshTestingAccess()
        precondition(!production.testingToolsEnabled && !production.addDebugSupply(.hints))
        sandbox = false; await app.refreshTestingAccess()
        precondition(!app.testingToolsEnabled && !app.restartEverything())
        print("Release tools default off; sandbox enables refills/level picker; production/recheck revokes access; saves cannot transfer permission.")
        #endif

        let (referral, referralDir) = try fixture("referral") { false }
        let trail = referral.progress.firstReef, board = referral.puzzle, balances = referral.progress.supplies
        precondition(referral.playBloomForGlow())
        precondition(referral.progress.activeScreen == .bloom && referral.bloomTrailGuidance)
        precondition(equal(referral.puzzle, board) && equal(referral.progress.firstReef, trail))
        precondition(equal(referral.progress.supplies, balances) && referral.progress.glow == 0 && referral.progress.shots == 7 && referral.progress.hints == 4)
        let loaded = ReefStore(defaults: defaults, saveDirectory: referralDir, testingEnvironment: { false })
        precondition(loaded.progress.activeScreen == .bloom && equal(loaded.puzzle, board))
        referral.navigate(to: .trail)
        precondition(!referral.bloomTrailGuidance && equal(referral.puzzle, board) && equal(referral.progress.firstReef, trail))
        precondition(referral.playBloomForGlow()); referral.tapCoral(referral.puzzle.coralIndices[1])
        precondition(!referral.bloomTrailGuidance)
        // Force a write failure with a directory at the atomic backup destination.
        let (failure, failureDir) = try fixture("save-failure") { false }
        try FileManager.default.createDirectory(at: failureDir.appendingPathComponent("progress-backup.json"), withIntermediateDirectories: true)
        let failedBefore = failure.progress
        precondition(!failure.playBloomForGlow() && !failure.bloomTrailGuidance)
        precondition(equal(failure.progress, failedBefore))
        print("Glow referral resumes and persists the exact board without spending, returns safely to Trail, clears its guidance, and rolls back on save failure.")
    }
}
