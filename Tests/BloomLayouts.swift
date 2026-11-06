import Foundation

@main struct CheckBloomLayouts {
    @MainActor static func main() throws {
        for level in 1...ReefStore.levelLimit {
            var puzzle=CoralPuzzle.make(level:level)
            guard let solution=puzzle.solution() else {fatalError("No solution at \(level)")}
            precondition(!solution.isEmpty && solution.count<=puzzle.allowedTaps)
            if let target=puzzle.pearlTarget {precondition(solution.count<=target)}
            for tap in solution {precondition(puzzle.isCoral(tap));puzzle.pulse(at:tap)}
            precondition(puzzle.isComplete)
            for gap in puzzle.gaps ?? [] {precondition(puzzle.affected(at:gap).isEmpty)}
            for coral in puzzle.coralIndices {precondition(puzzle.affected(at:coral).allSatisfy(puzzle.isCoral))}
        }
        for level in 28...35 {precondition(CoralPuzzle.make(level:level).hasGaps)}
        for level in [28,34,35] {
            let p=CoralPuzzle.make(level:level)
            precondition((p.gaps ?? []).contains {i in i/p.size>0 && i/p.size<p.size-1 && i%p.size>0 && i%p.size<p.size-1})
        }
        precondition(CoralPuzzle.make(level:43).hasGaps)
        precondition(!CoralPuzzle.make(level:37).hasGaps && !CoralPuzzle.make(level:40).hasGaps)
        print("All 60 boards and pearl targets solved using native tap rules; shapes, interior gaps and remaining squares verified")

        for level in [46,47,48,50,51] {
            let p=CoralPuzzle.make(level:level)
            precondition(!(p.verticals ?? []).isEmpty && !p.currents.isEmpty)
        }
        for level in 1..<52 {precondition(CoralPuzzle.make(level:level).stars.isEmpty)}
        for level in 52...54 {
            let p=CoralPuzzle.make(level:level)
            precondition(!p.stars.isEmpty && p.currents.isEmpty && (p.verticals ?? []).isEmpty && !p.hasLineCorals)
            if level>52 {precondition(!p.stones.isEmpty)}
            precondition(!Set(p.solution()!).isDisjoint(with:p.stars))
        }
        for level in [49,57] {
            let p=CoralPuzzle.make(level:level)
            precondition(p.currents.isEmpty && p.stars.isEmpty && (p.verticals ?? []).isEmpty)
        }
        var rules=CoralPuzzle(level:60,size:5,cells:Array(repeating:true,count:25))
        rules.rowCorals=[11]; rules.columnCorals=[8]; rules.stars=[12]
        precondition(Set(rules.affected(at:11))==Set(10...14))
        precondition(Set(rules.affected(at:8))==[3,8,13,18,23])
        precondition(Set(rules.affected(at:12))==[6,8,12,16,18])
        rules.stones=[13];rules.gaps=[10];rules.lighterCorals=[14]
        precondition(Set(rules.affected(at:11))==[11,12])
        precondition(Set(rules.affected(at:8))==[3,8,18,23])
        let cells=rules.cells;rules.pulse(at:8);rules.pulse(at:8)
        precondition(rules.cells==cells)
        print("Mixed axes, diagonal practice, full lines across gaps/pebbles, and lighter protection verified")

        // Every arbitrary legal play state remains solvable without power-ups.
        for level in 46...60 {
            var p=CoralPuzzle.make(level:level)
            for i in 0..<13 {p.pulse(at:p.coralIndices[(i*7+3)%p.coralCount])}
            for tap in p.solution()! {p.pulse(at:tap)}
            precondition(p.isComplete)
        }

        let root=URL(fileURLWithPath:CommandLine.arguments[1])
        let defaults=UserDefaults(suiteName:"puffpuff-layout-tests-\(UUID())")!
        func legacy(_ level:Int,started:Bool)->CoralPuzzle {
            var p=CoralPuzzle.make(level:level)
            p.gaps=[];p.contentRevision=7;p.cells=Array(repeating:true,count:p.size*p.size);p.cells[1]=false
            p.moves=started ? 1:0;p.attemptStarted=started
            return p
        }
        var saved=ReefProgress();saved.puzzle=legacy(28,started:true);saved.bloomResumePuzzle=legacy(31,started:true)
        saved.glow=81;saved.shots=17
        let startedDir=root.appendingPathComponent("started")
        try ReefSaveFile(defaults:defaults,directory:startedDir).write(saved)
        let store=ReefStore(defaults:defaults,saveDirectory:startedDir)
        precondition(!store.isSaveBlocked)
        precondition(store.puzzle.cells==saved.puzzle.cells && store.puzzle.gaps==saved.puzzle.gaps && store.puzzle.moves==1)
        precondition(store.progress.bloomResumePuzzle?.cells==saved.bloomResumePuzzle?.cells && store.progress.bloomResumePuzzle?.gaps==saved.bloomResumePuzzle?.gaps)
        precondition(store.progress.glow==81 && store.progress.shots==17)
        precondition(store.restartPuzzle() && store.puzzle.gaps==CoralPuzzle.make(level:28).gaps)
        precondition(store.progress.bloomResumePuzzle?.gaps==saved.bloomResumePuzzle?.gaps)
        saved.puzzle=legacy(28,started:false);saved.bloomResumePuzzle=nil
        let untouchedDir=root.appendingPathComponent("untouched")
        try ReefSaveFile(defaults:defaults,directory:untouchedDir).write(saved)
        let untouched=ReefStore(defaults:defaults,saveDirectory:untouchedDir)
        precondition(!untouched.isSaveBlocked && untouched.puzzle.cells==CoralPuzzle.make(level:28).cells && untouched.puzzle.gaps==CoralPuzzle.make(level:28).gaps)
        precondition(untouched.progress.glow==81 && untouched.progress.shots==17)
        // Untouched old drafts adopt new size/rules; begun attempts keep exact data.
        for started in [false,true] {
            var p=ReefProgress();p.version=18;p.glow=91;p.shots=21
            p.puzzle=CoralPuzzle(level:52,size:5,cells:Array(repeating:true,count:25))
            p.puzzle.cells[12]=false;p.puzzle.contentRevision=6;p.puzzle.moves=started ? 1:0
            p.puzzle.attemptStarted=started;p.bloomResumePuzzle=p.puzzle
            let dir=root.appendingPathComponent("draft-\(started)")
            try ReefSaveFile(defaults:defaults,directory:dir).write(p)
            let reloaded=ReefStore(defaults:defaults,saveDirectory:dir)
            precondition(!reloaded.isSaveBlocked && reloaded.progress.version==20 && reloaded.progress.glow==91 && reloaded.progress.shots==21)
            precondition(reloaded.puzzle.size==(started ? 5:4))
            precondition(reloaded.progress.bloomResumePuzzle?.size==(started ? 5:4))
            if started {precondition(reloaded.puzzle.cells==p.puzzle.cells)}
        }

        func fixture(_ name:String,level:Int) throws -> (ReefStore,URL) {
            var p=ReefProgress();p.puzzle=CoralPuzzle.make(level:level);p.puzzle.attemptStarted=true
            p.supplies.lighters=2
            let dir=root.appendingPathComponent(name)
            try ReefSaveFile(defaults:defaults,directory:dir).write(p)
            return (ReefStore(defaults:defaults,saveDirectory:dir),dir)
        }
        for level in [7,14,56] {
            let (reward,dir)=try fixture("lighter-\(level)",level:level)
            for tap in reward.puzzle.solution()! {reward.tapCoral(tap)}
            precondition(reward.isComplete && reward.progress.supplies.lighters==3 && reward.puzzle.earnedLighter==true)
            let again=ReefStore(defaults:defaults,saveDirectory:dir)
            precondition(again.progress.supplies.lighters==3)
            precondition(again.startFromBeginning() && again.startFromLevel(level))
            for tap in again.puzzle.solution()! {again.tapCoral(tap)}
            precondition(again.progress.supplies.lighters==3)
        }
        let (end,_)=try fixture("level-cap",level:60)
        for tap in end.puzzle.solution()! {end.tapCoral(tap)}
        end.nextPuzzle();precondition(end.puzzle.level==60 && end.isComplete)
        precondition(!end.startFromLevel(61))
        print("Once-only lighter rewards, relaunch/checkpoints and level-60 cap verified")
        print("Saved attempts/checkpoints retained; untouched boards and Restart adopt new layouts without changing other resources")
    }
}
