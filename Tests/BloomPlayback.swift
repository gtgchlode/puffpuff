import Foundation

@main struct CheckBloomPlayback {
    @MainActor static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let defaults = UserDefaults(suiteName: "puffpuff-playback-\(UUID())")!
        func equal<T: Encodable>(_ a: T, _ b: T) -> Bool {
            let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
            return try! encoder.encode(a) == encoder.encode(b)
        }
        // Both historical endpoint timings are exact; interpolation and changes
        // keep the same action/ripple through play, pause, background and finish.
        for count in [0, 2, 8, 30, 100, 4096] {
            let slow=BloomPlaybackTiming(moveCount:count,speed:0),fast=BloomPlaybackTiming(moveCount:count,speed:1)
            precondition(slow.interval==min(380,max(220,6800/Double(max(1,count)))))
            precondition(fast.interval==min(240,max(100,4200/Double(max(1,count)))))
            precondition(slow.lead==650 && slow.tail==1400 && fast.lead==450 && fast.tail==1100)
            for fraction in [0.0,0.25,0.5,0.75,1.0] {
                let t=BloomPlaybackTiming(moveCount:count,speed:fraction)
                for p in [0.0,0.5,1.0,Double(count)+0.4,t.finalPhase] {
                    precondition(abs(t.phase(at:t.time(at:p))-p)<0.000001)
                }
            }
        }
        let epoch=Date(timeIntervalSinceReferenceDate:1000)
        let slow=BloomPlaybackTiming(moveCount:20,speed:0),fast=BloomPlaybackTiming(moveCount:20,speed:1)
        var clock=BloomPlaybackCursor(timing:slow)
        clock.update(timing:slow,running:true,at:epoch)
        let change=epoch.addingTimeInterval(1.325),phaseBefore=clock.phase(at:change)
        clock.update(timing:fast,running:true,at:change)
        precondition(abs(clock.phase(at:change)-phaseBefore)<0.000001)
        let pause=change.addingTimeInterval(0.1),stopped=clock.phase(at:pause)
        clock.update(timing:fast,running:false,at:pause)
        precondition(abs(clock.phase(at:pause.addingTimeInterval(600))-stopped)<0.000001)
        clock.update(timing:slow,running:false,at:pause.addingTimeInterval(600))
        precondition(abs(clock.phase(at:pause.addingTimeInterval(700))-stopped)<0.000001)
        clock.update(timing:slow,running:true,at:pause.addingTimeInterval(700))
        let finish=clock.phase(at:pause.addingTimeInterval(1000))
        precondition(finish==slow.finalPhase)
        clock.update(timing:fast,running:false,at:pause.addingTimeInterval(1000))
        precondition(clock.phase(at:pause.addingTimeInterval(2000))==fast.finalPhase)
        precondition(BloomPlaybackTiming(moveCount:5,speed:Double.nan).speed==0.5)
        print("Playback slider: exact old/new endpoints, in-flight continuity, pause/background, persisted-value bounds and finish verified")

        // Replay all native rules, with mistaken repeated taps included in order.
        for level in 1...ReefStore.levelLimit {
            var p = CoralPuzzle.make(level: level)
            var order: [BloomMove] = []
            if let wrong = p.coralIndices.first(where: { i in var q=p;q.pulse(at:i);return !q.isComplete }) {
                for _ in 0..<2 {
                    let action = BloomMove(kind:.tap,index:wrong)
                    precondition(p.playTap(at:wrong));order.append(action)
                }
            }
            for i in p.solution()! {
                let action = BloomMove(kind:.tap,index:i)
                precondition(p.playTap(at:i));order.append(action)
            }
            precondition(p.isComplete && p.recording!.moves == order)
            let frames = p.recordedFrames!
            precondition(frames.last!.cells == p.cells && frames.last!.taps == p.moves)
            precondition(frames.count == order.count + 1)
            var practice = p.freePractice()
            precondition(practice.cells == frames[0].cells && practice.moves == 0 && practice.recording == nil)
            for i in practice.solution()! {precondition(practice.playTap(at:i))}
            precondition(practice.isComplete && !practice.rewarded && practice.recordedFrames != nil)
        }
        print("Actual action order, mistakes, every special tile, and free practice verified on 100 boards")

        var saved = ReefProgress();saved.puzzle = .make(level:58);saved.puzzle.attemptStarted=true;saved.supplies.lighters=2
        saved.glow=84;saved.shots=11
        let dir=root.appendingPathComponent("resume")
        try ReefSaveFile(defaults:defaults,directory:dir).write(saved)
        let store=ReefStore(defaults:defaults,saveDirectory:dir)
        let index=store.puzzle.coralIndices.first(where:{!store.puzzle.cells[$0]})!
        precondition(store.lightCoral(index))
        precondition(store.puzzle.recording!.moves == [.init(kind:.lighter,index:index)])
        for i in store.puzzle.solution()! { store.tapCoral(i) }
        precondition(store.isComplete && store.puzzle.recordedFrames!.last!.held == [index])
        let reloaded=ReefStore(defaults:defaults,saveDirectory:dir)
        precondition(!reloaded.isSaveBlocked && equal(reloaded.puzzle.recording,store.puzzle.recording))
        let before=try Data(contentsOf:dir.appendingPathComponent("progress.json"))
        let rewards=reloaded.progress
        var practice=reloaded.puzzle.freePractice()
        for _ in 0..<3 {
            for i in practice.solution()! {precondition(practice.playTap(at:i))}
            _ = practice.recordedFrames;practice=practice.freePractice()
        }
        let after = try Data(contentsOf:dir.appendingPathComponent("progress.json"))
        precondition(equal(rewards,reloaded.progress) && before == after)
        print("Lighter playback, relaunch and repeat viewing/practice leave wallet/lives/save unchanged")

        func refundFixture(_ name: String, limit: Int? = nil) throws -> (ReefStore, URL) {
            var p=ReefProgress();p.puzzle = .make(level:8);p.puzzle.attemptStarted=true
            if let limit {p.puzzle.tapLimit=limit}
            p.supplies.lighters=3
            let dir=root.appendingPathComponent(name)
            try ReefSaveFile(defaults:defaults,directory:dir).write(p)
            return (ReefStore(defaults:defaults,saveDirectory:dir),dir)
        }
        let (refunding,refundDir)=try refundFixture("refunds")
        let startCells=refunding.puzzle.cells,startLives=refunding.progress.supplies.lives
        for _ in 0..<20 {refunding.tapCoral(0);refunding.tapCoral(0)}
        precondition(refunding.puzzle.cells==startCells && refunding.puzzle.moves==40 && refunding.puzzle.spentTaps==0)
        precondition(refunding.puzzle.undoTap==nil && refunding.progress.supplies.lives==startLives)
        precondition(refunding.puzzle.recording!.moves.count==40 && refunding.puzzle.recordedFrames!.count==41)
        refunding.tapCoral(0)
        let pending=ReefStore(defaults:defaults,saveDirectory:refundDir)
        precondition(pending.puzzle.canUndoTap(0) && pending.puzzle.spentTaps==1)
        pending.tapCoral(0)
        precondition(pending.puzzle.cells==startCells && pending.puzzle.spentTaps==0 && pending.puzzle.moves==42)
        for i in pending.puzzle.solution()! {pending.tapCoral(i)}
        precondition(pending.isComplete && pending.puzzle.moves>pending.puzzle.allowedTaps)
        precondition(pending.progress.lastBloomTapTotals["8"] == .init(total:45,counted:3))
        pending.nextPuzzle();precondition(pending.puzzle.level==9 && pending.progress.lastBloomTapTotals["8"]?.total==45)
        let again=ReefStore(defaults:defaults,saveDirectory:refundDir)
        precondition(again.progress.lastBloomTapTotals["8"]?.counted==3)

        let (limited,_)=try refundFixture("last-tap",limit:1)
        limited.tapCoral(0);precondition(limited.isOutOfTaps)
        let afterLoss=limited.progress.supplies.lives
        limited.tapCoral(1);precondition(limited.puzzle.moves==1)
        limited.tapCoral(0)
        precondition(!limited.isOutOfTaps && limited.puzzle.tapsRemaining==1 && limited.puzzle.moves==2)
        precondition(limited.progress.supplies.lives==afterLoss,"Refund taps only, never hearts")
        limited.tapCoral(0);precondition(limited.isOutOfTaps)
        limited.claimFreeTapRefill()
        precondition(limited.puzzle.tapsRemaining==5,"Refill must use counted taps, not recorded clicks")

        let (interrupted,_)=try refundFixture("lighter-interruption")
        interrupted.tapCoral(0)
        let sleepy=interrupted.puzzle.coralIndices.first{!interrupted.puzzle.cells[$0]}!
        precondition(interrupted.lightCoral(sleepy) && !interrupted.puzzle.canUndoTap(0))
        interrupted.tapCoral(0)
        precondition(interrupted.puzzle.spentTaps==2 && interrupted.puzzle.moves==2 && interrupted.puzzle.recordedFrames != nil)
        let (rollback,rollbackDir)=try refundFixture("refund-rollback")
        rollback.tapCoral(0)
        let frozenRefund=rollback.progress
        try FileManager.default.moveItem(at:rollbackDir.appendingPathComponent("progress.json"),to:rollbackDir.appendingPathComponent("preserved.json"))
        try FileManager.default.createDirectory(at:rollbackDir.appendingPathComponent("progress.json"),withIntermediateDirectories:true)
        rollback.tapCoral(0)
        precondition(equal(frozenRefund,rollback.progress),"Failed save must roll back refund, cells and recording together")
        print("Tap refunds: consecutive pairs restore allowance; all clicks retained; relaunch, last-tap reversal, lighter boundaries, raw-over-budget wins, saved totals, refills and rollback verified")

        // Genuine old mid-attempt saves never invent missing taps.
        var legacy=ReefProgress();legacy.version=24;legacy.puzzle = .make(level:58)
        legacy.puzzle.attemptStarted=true;legacy.puzzle.pulse(at:2);legacy.puzzle.moves=1
        let legacyDir=root.appendingPathComponent("legacy")
        try ReefSaveFile(defaults:defaults,directory:legacyDir).write(legacy)
        let old=ReefStore(defaults:defaults,saveDirectory:legacyDir)
        old.tapCoral(3);precondition(old.puzzle.recording==nil && old.puzzle.recordedFrames==nil)
        precondition(old.restartPuzzle());old.tapCoral(3);precondition(old.puzzle.recordedFrames != nil)
        var invalid=store.progress
        invalid.puzzle.recording!.moves[0].index=999
        do {try ReefSaveFile(defaults:defaults,directory:root.appendingPathComponent("invalid")).write(invalid);fatalError("Accepted invalid history")}
        catch ReefSaveError.invalidData {}
        // Write failure must roll the newly appended action back with the board.
        let blocked=dir.appendingPathComponent("progress.json")
        let archive=dir.appendingPathComponent("prior-progress.json")
        try FileManager.default.moveItem(at:blocked,to:archive)
        try FileManager.default.createDirectory(at:blocked,withIntermediateDirectories:true)
        let frozen=store.progress
        store.nextPuzzle()
        precondition(equal(frozen,store.progress))
        print("Legacy attempts, new restart recording, invalid history rejection and save rollback verified")
    }
}
