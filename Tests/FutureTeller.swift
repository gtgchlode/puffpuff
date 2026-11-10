import Foundation

@main struct CheckFutureTeller {
    @MainActor static func main() throws {
        let root=URL(fileURLWithPath:CommandLine.arguments[1])
        let defaults=UserDefaults(suiteName:"future-teller-\(UUID())")!
        func equal<T:Encodable>(_ a:T,_ b:T)->Bool {
            let e=JSONEncoder();e.outputFormatting = .sortedKeys
            return try! e.encode(a)==e.encode(b)
        }
        func fixture(_ name:String,level:Int=58,unlocked:Bool=true,items:Int=3) throws -> (ReefStore,URL) {
            var p=ReefProgress();p.puzzle = .make(level:level);p.puzzle.attemptStarted=true
            p.futureTellers=items;p.supplies.lighters=30;p.glow=81;p.shots=9
            p.completedBloomLevels=unlocked ? [50]:[]
            let dir=root.appendingPathComponent(name)
            try ReefSaveFile(defaults:defaults,directory:dir).write(p)
            return (ReefStore(defaults:defaults,saveDirectory:dir),dir)
        }
        // All current rule families, holes and pebbles: the glimpse is a target
        // state reachable from the actual board, and one exact tap finishes it.
        for level in 5...100 {
            for light in [false,true] {
                var p=CoralPuzzle.make(level:level)
                if let wrong=p.coralIndices.first(where:{i in var q=p;q.pulse(at:i);return !q.isComplete}) {p.pulse(at:wrong)}
                if light,let i=p.coralIndices.first(where:{!p.cells[$0]}) {
                    p.cells[i]=true;p.lighterCorals=[i]
                }
                guard let solution=p.solution(),let final=solution.last else {continue}
                let live=p.cells;p.futureTellerFinalTap=final
                var target=p.futureTellerBoard!
                precondition(p.cells==live && !target.isComplete)
                precondition(target.cells.indices.filter{!target.cells[$0]}==p.affected(at:final).sorted())
                for i in solution.dropLast() {p.pulse(at:i)}
                precondition(p.cells==target.cells)
                target.pulse(at:final);precondition(target.isComplete)
            }
        }
        print("Final-state previews are reachable and solve in one tap across all 100 levels, including lighter/special/gap/pebble rules.")

        let (locked,_)=try fixture("locked",level:49,unlocked:false)
        let lockedBefore=locked.progress
        precondition(!locked.showFutureTeller() && equal(locked.progress,lockedBefore))
        let (empty,_)=try fixture("empty",items:0)
        precondition(!empty.showFutureTeller())
        let (s,dir)=try fixture("active")
        let before=s.progress
        precondition(s.showFutureTeller())
        precondition(s.progress.futureTellers==before.futureTellers-1)
        var expected=before;expected.futureTellers-=1;expected.puzzle.futureTellerFinalTap=s.puzzle.futureTellerFinalTap;expected.savedAt=s.progress.savedAt
        precondition(equal(s.progress,expected))
        let saved=try Data(contentsOf:dir.appendingPathComponent("progress.json"))
        precondition(s.showFutureTeller())
        let reopened=try Data(contentsOf:dir.appendingPathComponent("progress.json"))
        precondition(reopened==saved)
        let reload=ReefStore(defaults:defaults,saveDirectory:dir)
        let final=reload.puzzle.futureTellerFinalTap!
        precondition(!reload.isSaveBlocked && reload.showFutureTeller() && reload.progress.futureTellers==2)
        let target=reload.puzzle.futureTellerBoard!.cells
        let wrong=reload.puzzle.coralIndices.first(where:{$0 != final})!
        reload.tapCoral(wrong)
        precondition(reload.puzzle.futureTellerFinalTap==final && reload.puzzle.futureTellerBoard!.cells==target)
        precondition(reload.progress.futureTellers==2)
        if let i=reload.puzzle.coralIndices.first(where:{!reload.puzzle.cells[$0]}) {
            precondition(reload.lightCoral(i))
            if !reload.isComplete {
                var target=reload.puzzle.futureTellerBoard!
                target.pulse(at:reload.puzzle.futureTellerFinalTap!);precondition(target.isComplete)
            }
        }
        for i in reload.puzzle.solution()! {reload.tapCoral(i)}
        precondition(reload.isComplete && reload.puzzle.futureTellerFinalTap==nil)
        let rewards=reload.progress.futureTellers
        let again=ReefStore(defaults:defaults,saveDirectory:dir)
        precondition(again.progress.futureTellers==rewards && !again.showFutureTeller())
        let practice=again.puzzle.freePractice()
        precondition(practice.futureTellerFinalTap==nil && practice.earnedFutureTeller==nil)
        print("Unlock, atomic single-item use, unchanged board/resources, reopen/relaunch, mistakes, lighters and win cleanup verified.")

        let (restart,_)=try fixture("restart")
        precondition(restart.showFutureTeller() && restart.restartPuzzle())
        precondition(restart.puzzle.futureTellerFinalTap==nil && restart.progress.futureTellers==2)
        let (failure,failDir)=try fixture("failure")
        let failBefore=failure.progress
        let kept=failDir.appendingPathExtension("retained")
        try FileManager.default.moveItem(at:failDir,to:kept)
        try Data("blocked save fixture".utf8).write(to:failDir)
        precondition(!failure.showFutureTeller() && equal(failure.progress,failBefore))
        print("Restart clears the glimpse; failed writes restore the item and exact original puzzle.")

        let winSeed=(UInt64(1)...10000).first{ReefStore.hasFutureTeller(seed:$0,win:1)}!
        for level in [49,50,51] {
            var p=ReefProgress();p.puzzle = .make(level:level);p.puzzle.attemptStarted=true
            p.lifeGiftSeed=winSeed
            let d=root.appendingPathComponent("drop-\(level)")
            try ReefSaveFile(defaults:defaults,directory:d).write(p)
            let g=ReefStore(defaults:defaults,saveDirectory:d)
            for i in g.puzzle.solution()! {g.tapCoral(i)}
            precondition(g.isComplete && !g.lastSaveFailed)
            precondition(g.progress.futureTellers==(level>=50 ? 1:0))
            precondition((g.puzzle.earnedFutureTeller==true)==(level>=50))
            precondition(ReefStore(defaults:defaults,saveDirectory:d).progress.futureTellers==g.progress.futureTellers)
        }
        let count=(1...100000).filter{ReefStore.hasFutureTeller(seed:8675309,win:$0)}.count
        precondition((1800...2200).contains(count))
        print("Rare drop gate and repeat-safe reward persistence verified; sampled rate \(count)/100000.")

        var legacy=ReefProgress();legacy.version=27;legacy.puzzle = .make(level:55);legacy.glow=123;legacy.completedBloomLevels=[50]
        var object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(legacy)) as! [String:Any]
        object.removeValue(forKey:"futureTellers")
        let legacyDir=root.appendingPathComponent("legacy")
        try FileManager.default.createDirectory(at:legacyDir,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:object).write(to:legacyDir.appendingPathComponent("progress.json"))
        let migrated=ReefStore(defaults:defaults,saveDirectory:legacyDir)
        precondition(!migrated.isSaveBlocked && migrated.progress.version==31 && migrated.progress.futureTellers==0 && migrated.progress.glow==123 && equal(migrated.puzzle,legacy.puzzle))
        var invalid=migrated.progress;invalid.futureTellers = -1
        do {try ReefSaveFile(defaults:defaults,directory:root.appendingPathComponent("invalid")).write(invalid);preconditionFailure()} catch ReefSaveError.invalidData {}
        invalid=migrated.progress;invalid.puzzle.futureTellerFinalTap=99
        do {try ReefSaveFile(defaults:defaults,directory:root.appendingPathComponent("invalid-final")).write(invalid);preconditionFailure()} catch ReefSaveError.invalidData {}
        print("Format-27 migration preserves all prior state; invalid inventory and final targets rejected.")
    }
}
