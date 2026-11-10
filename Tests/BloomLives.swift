import Foundation

@main struct CheckBloomLives {
    @MainActor static func main() throws {
        let start=Date(timeIntervalSinceReferenceDate:800_000_000)
        var supplies=BloomSupplies()
        supplies.loseLife(at:start)
        precondition(supplies.lives == 4 && supplies.nextLifeAt == start.addingTimeInterval(300))
        supplies.loseLife(at:start.addingTimeInterval(120))
        precondition(supplies.lives == 3 && supplies.nextLifeAt == start.addingTimeInterval(300))
        precondition(supplies.refreshed(at:start.addingTimeInterval(299)).lives == 3)
        let first=supplies.refreshed(at:start.addingTimeInterval(300))
        precondition(first.lives == 4 && first.nextLifeAt == start.addingTimeInterval(600))
        let full=supplies.refreshed(at:start.addingTimeInterval(600))
        precondition(full.lives == 5 && full.nextLifeAt == nil)
        precondition(full.refreshed(at:start.addingTimeInterval(60*60*24)).lives == 5)

        var empty=BloomSupplies()
        for _ in 0..<5 {empty.loseLife(at:start)}
        for minute in [0,4,5,9,10,14,15,20,25,60] {
            precondition(empty.refreshed(at:start.addingTimeInterval(Double(minute)*60)).lives == min(5,minute/5))
        }
        var gift=first
        gift.addLives(3,at:start.addingTimeInterval(300))
        precondition(gift.lives == 7 && gift.nextLifeAt == nil)
        precondition(gift.refreshed(at:start.addingTimeInterval(86400)).lives == 7)
        gift.loseLife(at:start.addingTimeInterval(400))
        gift.loseLife(at:start.addingTimeInterval(500))
        precondition(gift.lives == 5 && gift.nextLifeAt == nil)
        gift.loseLife(at:start.addingTimeInterval(600))
        precondition(gift.nextLifeAt == start.addingTimeInterval(900))
        print("Five-minute boundaries, multiple losses, offline catch-up, natural cap and gifted overflow passed")

        let root=URL(fileURLWithPath:CommandLine.arguments[1])
        let defaults=UserDefaults(suiteName:"puffpuff-life-tests-\(UUID())")!
        var progress=ReefProgress()
        progress.supplies.lives=0
        progress.supplies.nextLifeAt=Date().addingTimeInterval(-610)
        let file=ReefSaveFile(defaults:defaults,directory:root)
        try file.write(progress)
        let store=ReefStore(defaults:defaults,saveDirectory:root)
        precondition(!store.isSaveBlocked && !store.lastSaveFailed)
        precondition(store.progress.supplies.lives == 3)
        let saved=try JSONDecoder().decode(ReefProgress.self,from:Data(contentsOf:root.appendingPathComponent("progress.json")))
        precondition(saved.supplies == store.progress.supplies)
        precondition(store.startBloomAttempt())
        precondition(store.progress.supplies.lives == 3)
        store.refreshLives()
        let reloaded=ReefStore(defaults:defaults,saveDirectory:root)
        precondition(reloaded.progress.supplies.lives == 3)
        precondition(reloaded.progress.supplies.nextLifeAt == saved.supplies.nextLifeAt)
        precondition(reloaded.progress.glow == progress.glow && reloaded.progress.shots == progress.shots && reloaded.progress.hints == progress.hints)
        print("Relaunch credits elapsed time once, persists the balance, and starting play costs no life")

        func fixture(_ name:String,failed:Bool=false) throws -> (ReefStore,URL) {
            let directory=root.appendingPathComponent(name)
            var p=ReefProgress();p.puzzle=CoralPuzzle.make(level:8)
            p.puzzle.attemptStarted=true;p.puzzle.lifeLossHandled=failed
            p.puzzle.moves=failed ? p.puzzle.allowedTaps:1
            p.supplies.lives=0;p.supplies.nextLifeAt=Date().addingTimeInterval(300)
            try ReefSaveFile(defaults:defaults,directory:directory).write(p)
            return (ReefStore(defaults:defaults,saveDirectory:directory),directory)
        }
        for failed in [false,true] {
            let (ad,directory)=try fixture(failed ? "failed-restart":"midgame-restart",failed:failed)
            precondition(!ad.restartCostsLife)
            precondition(ad.restartPuzzle(usingAdLife:true))
            precondition(ad.progress.supplies.lives==1 && ad.puzzle.moves==0 && ad.puzzle.attemptStarted==true)
            precondition(ad.puzzle.lifeLossHandled != true && ad.restartCostsLife)
            precondition(!ad.restartPuzzle(usingAdLife:true) && ad.progress.supplies.lives==1)
            let reload=ReefStore(defaults:defaults,saveDirectory:directory)
            precondition(reload.progress.supplies.lives==1 && reload.puzzle.attemptStarted==true)
            precondition(ad.restartPuzzle() && ad.progress.supplies.lives==0 && ad.puzzle.attemptStarted==true && ad.canPlayBloom)
            precondition(!ad.restartPuzzle(),"Zero blocks the next restart, not the funded attempt")
        }
        let lastLifeDir=root.appendingPathComponent("last-life")
        var five=ReefProgress();five.puzzle = .make(level:8);five.puzzle.attemptStarted=true
        try ReefSaveFile(defaults:defaults,directory:lastLifeDir).write(five)
        let fiveLives=ReefStore(defaults:defaults,saveDirectory:lastLifeDir)
        for remaining in stride(from:4,through:0,by:-1) {
            precondition(fiveLives.restartPuzzle())
            precondition(fiveLives.progress.supplies.lives==remaining && fiveLives.canPlayBloom && !fiveLives.isComplete)
            let resumed=ReefStore(defaults:defaults,saveDirectory:lastLifeDir)
            precondition(resumed.progress.supplies.lives==remaining && resumed.canPlayBloom)
        }
        precondition(!fiveLives.canStartBloom && !fiveLives.restartPuzzle())
        let moves=fiveLives.puzzle.moves
        fiveLives.tapCoral(0)
        precondition(fiveLives.puzzle.moves==moves+1,"The zero-life final attempt must accept taps")
        var one=five;one.supplies.lives=1;one.supplies.nextLifeAt=Date().addingTimeInterval(300)
        let lastBlockedDir=root.appendingPathComponent("last-life-save-failure")
        try ReefSaveFile(defaults:defaults,directory:lastBlockedDir).write(one)
        let lastBlocked=ReefStore(defaults:defaults,saveDirectory:lastBlockedDir)
        let lastBackup=lastBlockedDir.appendingPathComponent("progress-backup.json")
        if FileManager.default.fileExists(atPath:lastBackup.path) {
            try FileManager.default.moveItem(at:lastBackup,to:lastBlockedDir.appendingPathComponent("retained-backup.json"))
        }
        try FileManager.default.createDirectory(at:lastBackup,withIntermediateDirectories:false)
        precondition(!lastBlocked.restartPuzzle() && lastBlocked.progress.supplies.lives==1)
        precondition(lastBlocked.puzzle.lifeLossHandled==one.puzzle.lifeLossHandled && lastBlocked.puzzle.cells==one.puzzle.cells)
        print("Restart sequence 5→4→3→2→1→0 stays playable, survives reload and accepts taps at zero; next restart is blocked and failed saves roll back")
        let (refill,_)=try fixture("general-refill")
        let originalBoard=refill.puzzle.cells,originalMoves=refill.puzzle.moves
        precondition(refill.claimFreeLifeRefill() && refill.progress.supplies.lives==3)
        precondition(refill.puzzle.cells==originalBoard && refill.puzzle.moves==originalMoves)
        let (blocked,blockedDir)=try fixture("ad-save-failure")
        try FileManager.default.createDirectory(at:blockedDir.appendingPathComponent("progress-backup.json"),withIntermediateDirectories:false)
        let before=blocked.progress
        precondition(!blocked.restartPuzzle(usingAdLife:true))
        precondition(blocked.progress.supplies==before.supplies && blocked.puzzle.cells==before.puzzle.cells && blocked.puzzle.moves==before.puzzle.moves && blocked.puzzle.lifeLossHandled==before.puzzle.lifeLossHandled && blocked.progress.pendingDiscoveries==before.pendingDiscoveries)
        print("Restart ad grants one life atomically; normal refill grants three; replay, relaunch and failed-save checks passed")

        let outcomes=(0..<1000).map {BloomLifeGift.reward(forRoll:$0)}
        precondition(outcomes.filter{$0 == .instant}.count==30)
        precondition(outcomes.filter{$0 == .refill}.count==50)
        precondition(outcomes.filter{$0 == .stored}.count==5)
        precondition(outcomes.filter{$0 == nil}.count==915)
        for (seed,expected):(UInt64,BloomLifeGift?) in [(18,.instant),(50,.refill),(217,.stored),(1,nil)] {
            let directory=root.appendingPathComponent("gift-\(seed)")
            var p=ReefProgress();p.lifeGiftSeed=seed;p.puzzle=CoralPuzzle.make(level:6)
            p.supplies.lives=2;p.supplies.nextLifeAt=Date().addingTimeInterval(300)
            try ReefSaveFile(defaults:defaults,directory:directory).write(p)
            let game=ReefStore(defaults:defaults,saveDirectory:directory)
            precondition(game.startBloomAttempt())
            for tap in game.puzzle.solution()! {game.tapCoral(tap)}
            precondition(game.isComplete && game.puzzle.earnedLifeGift==expected)
            if expected == .instant {precondition(game.progress.supplies.lives==5 && game.progress.supplies.unlimited())}
            else if expected == .refill {precondition(game.progress.supplies.lives==5 && game.progress.supplies.unlimitedUntil==nil && game.progress.supplies.unlimitedBoosts==0)}
            else {precondition(game.progress.supplies.lives==2 && game.progress.supplies.unlimitedUntil==nil)}
            precondition(game.progress.supplies.unlimitedBoosts==(expected == .stored ? 1:0))
            let refreshed=ReefStore(defaults:defaults,saveDirectory:directory)
            precondition(refreshed.progress.supplies==game.progress.supplies && refreshed.puzzle.earnedLifeGift==expected)
        }
        var refillOnly=BloomSupplies();refillOnly.lives=2;refillOnly.nextLifeAt=Date().addingTimeInterval(300)
        let expiry=Date().addingTimeInterval(300)
        refillOnly.unlimitedUntil=expiry;refillOnly.refillLives()
        precondition(refillOnly.lives==5 && refillOnly.unlimitedUntil==expiry)
        refillOnly.lives=12;refillOnly.refillLives()
        precondition(refillOnly.lives==12 && refillOnly.unlimitedUntil==expiry)
        var oldSave=ReefProgress();oldSave.version=17;oldSave.supplies=refillOnly
        let migrateDir=root.appendingPathComponent("gift-migration")
        try ReefSaveFile(defaults:defaults,directory:migrateDir).write(oldSave)
        let migrated=ReefStore(defaults:defaults,saveDirectory:migrateDir)
        precondition(migrated.progress.version==31 && migrated.progress.supplies==oldSave.supplies && migrated.progress.lifeGiftSeed==oldSave.lifeGiftSeed)
        print("Exact 3%/5%/0.5% reward buckets; native win grants; refill adds no unlimited time; overflow and format-17 migration preserved")


    }
}
