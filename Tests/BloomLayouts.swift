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
        print("All 100 boards and pearl targets solved using native tap rules; shapes, interior gaps and remaining squares verified")

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
        precondition((60...70).filter { !CoralPuzzle.make(level:$0).hasLineCorals } == [63,67])
        let mixes: [Int:[Int]] = [
            60:[1,1,0,0,0,0],61:[1,0,1,0,0,2],62:[0,1,0,1,1,0],
            63:[0,0,0,0,2,2],64:[1,1,1,0,0,0],65:[1,0,0,1,1,2],
            66:[0,1,1,0,1,0],67:[0,0,0,0,2,0],68:[1,1,0,0,1,2],
            69:[1,0,1,1,0,0],70:[1,1,1,1,1,0]]
        for (level, expected) in mixes {
            let p=CoralPuzzle.make(level:level)
            precondition([(p.rowCorals ?? []).count,(p.columnCorals ?? []).count,(p.verticals ?? []).count,p.currents.count,p.stars.count,p.stones.count] == expected)
            if level>60 { precondition(p.tapLimit==38) }
        }
        precondition(CoralPuzzle.make(level:64).isGap(12))
        print("Approved 60–70 counts, two no-line boards and 38-tap budgets verified")
        print("Mixed axes, diagonal practice, full lines across gaps/pebbles, and lighter protection verified")

        // Every arbitrary legal play state remains solvable without power-ups.
        for level in 46...100 {
            var p=CoralPuzzle.make(level:level)
            for i in 0..<13 {p.pulse(at:p.coralIndices[(i*7+3)%p.coralCount])}
            for tap in p.solution()! {p.pulse(at:tap)}
            precondition(p.isComplete)
        }

        let finalMixes:[Int:[Int]] = [71:[0, 0, 0, 0, 0, 0, 0],72:[1, 0, 0, 0, 1, 0, 2],73:[0, 1, 0, 2, 0, 0, 0],74:[0, 0, 1, 0, 2, 0, 0],75:[2, 0, 0, 0, 0, 0, 0],76:[0, 0, 0, 0, 0, 0, 2],77:[0, 2, 0, 1, 0, 0, 0],78:[1, 0, 0, 0, 1, 0, 0],79:[0, 0, 2, 2, 0, 0, 2],80:[1, 1, 0, 0, 2, 0, 0],81:[0, 0, 0, 0, 1, 0, 0],82:[1, 1, 0, 0, 0, 0, 2],83:[2, 0, 1, 0, 0, 0, 0],84:[0, 0, 0, 1, 2, 0, 2],85:[0, 0, 0, 0, 0, 1, 0],86:[0, 0, 0, 0, 0, 1, 0],87:[0, 0, 0, 0, 0, 2, 0],88:[0, 0, 0, 0, 0, 1, 2],89:[0, 0, 0, 0, 0, 0, 0],90:[1, 0, 0, 0, 0, 1, 0],91:[0, 0, 0, 0, 0, 0, 2],92:[1, 0, 1, 1, 0, 1, 0],93:[0, 2, 0, 0, 2, 0, 0],94:[0, 0, 2, 2, 1, 0, 2],95:[2, 1, 0, 0, 0, 1, 0],96:[0, 0, 0, 1, 1, 0, 0],97:[1, 1, 0, 0, 2, 0, 2],98:[2, 0, 1, 1, 0, 1, 0],99:[0, 0, 0, 0, 0, 0, 0],100:[1, 1, 1, 1, 1, 1, 2]]
        for (level,expected) in finalMixes {
            let p=CoralPuzzle.make(level:level)
            precondition([(p.rowCorals ?? []).count,(p.columnCorals ?? []).count,(p.verticals ?? []).count,p.currents.count,p.stars.count,(p.burstCorals ?? []).count,p.stones.count]==expected)
        }
        // Burst uses all eight adjacent coral, clips at edges, and never flips
        // pebbles, open water or lighter-held coral.
        var burst=CoralPuzzle(level:85,size:3,cells:Array(repeating:true,count:9))
        burst.burstCorals=[4]
        precondition(Set(burst.affected(at:4))==Set(0..<9))
        burst.burstCorals=[0]
        precondition(Set(burst.affected(at:0))==[0,1,3,4])
        burst.burstCorals=[4];burst.stones=[0];burst.gaps=[8];burst.lighterCorals=[2]
        precondition(Set(burst.affected(at:4))==[1,3,4,5,6,7])
        burst.lighterCorals=[]
        burst.cells[3]=false
        let beforeBurst=burst.cells
        precondition(burst.playTap(at:4) && burst.playTap(at:4))
        precondition(burst.cells==beforeBurst && burst.moves==2 && burst.spentTaps==0)
        precondition(burst.recordedFrames?.last?.cells==burst.cells)
        for level in 1..<85 {precondition((CoralPuzzle.make(level:level).burstCorals ?? []).isEmpty)}
        for level in 85...88 {
            let p=CoralPuzzle.make(level:level)
            precondition(!p.burstCorals!.isEmpty && !p.hasLineCorals && p.currents.isEmpty && p.stars.isEmpty && (p.verticals ?? []).isEmpty)
            precondition(p.stones.isEmpty == (level != 88))
            precondition(Set(p.burstCorals!).isSubset(of:Set(p.solution()!)))
            if level<88 {for i in p.burstCorals! {precondition(p.affected(at:i).count==9)}}
        }
        precondition(CoralPuzzle.make(level:87).burstCorals!.count==2)
        precondition(CoralPuzzle.make(level:89).feature=="classic")
        precondition(CoralPuzzle.make(level:90).rowCorals!.count==1 && CoralPuzzle.make(level:90).burstCorals!.count==1)
        for level in 71...100 {
            let p=CoralPuzzle.make(level:level)
            precondition(p.tapLimit==(level<=80 ? 38:42))
            precondition((p.rowCorals ?? []).map{$0/p.size}.count==Set((p.rowCorals ?? []).map{$0/p.size}).count)
            precondition((p.columnCorals ?? []).map{$0%p.size}.count==Set((p.columnCorals ?? []).map{$0%p.size}).count)
        }
        print("Burst introduction, 3x3/edge effects, obstacles, lighters, tap refunds and later mixes verified")

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
            precondition(!reloaded.isSaveBlocked && reloaded.progress.version==28 && reloaded.progress.glow==91 && reloaded.progress.shots==21)
            precondition(reloaded.puzzle.size==(started ? 5:4))
            precondition(reloaded.progress.bloomResumePuzzle?.size==(started ? 5:4))
            if started {precondition(reloaded.puzzle.cells==p.puzzle.cells)}
        }

        for level in 61...100 {
            for started in [false,true] {
                var p=ReefProgress();p.puzzle=CoralPuzzle.make(level:level)
                p.puzzle.contentRevision=6;p.puzzle.rowCorals=nil;p.puzzle.columnCorals=nil
                p.puzzle.verticals=nil;p.puzzle.currents=[];p.puzzle.stars=[];p.puzzle.burstCorals=nil
                p.puzzle.cells=Array(repeating:true,count:p.puzzle.size*p.puzzle.size)
                p.puzzle.cells[p.puzzle.coralIndices[0]]=false
                p.puzzle.moves=started ? 1:0;p.puzzle.attemptStarted=started
                p.bloomResumePuzzle=p.puzzle;p.glow=90;p.shots=17
                let dir=root.appendingPathComponent("new-mix-\(level)-\(started)")
                try ReefSaveFile(defaults:defaults,directory:dir).write(p)
                let reloaded=ReefStore(defaults:defaults,saveDirectory:dir)
                precondition(!reloaded.isSaveBlocked && reloaded.progress.glow==90 && reloaded.progress.shots==17)
                let expected=started ? p.puzzle:CoralPuzzle.make(level:level)
                precondition(reloaded.puzzle.cells==expected.cells && reloaded.puzzle.rowCorals==expected.rowCorals)
                precondition(reloaded.progress.bloomResumePuzzle?.cells==expected.cells)
            }
        }
        // Resume a prior cap without resetting the won board or granting again.
        var capped=ReefProgress();capped.version=26;capped.puzzle = .make(level:70)
        for tap in capped.puzzle.solution()! {capped.puzzle.pulse(at:tap);capped.puzzle.moves+=1}
        capped.puzzle.attemptStarted=true;capped.puzzle.rewarded=true;capped.completedBloomLevels=Set(1...70)
        capped.bloomChapterComplete=true;capped.glow=82;capped.shots=19
        let capDir=root.appendingPathComponent("old-cap")
        try ReefSaveFile(defaults:defaults,directory:capDir).write(capped)
        let capStore=ReefStore(defaults:defaults,saveDirectory:capDir)
        precondition(!capStore.isSaveBlocked && capStore.isComplete && capStore.puzzle.cells==capped.puzzle.cells)
        precondition(!capStore.progress.bloomChapterComplete && capStore.progress.glow==82 && capStore.progress.shots==19)
        capStore.nextPuzzle();precondition(capStore.puzzle.level==71 && !capStore.isComplete)

        // Real new boards save, hint, record, reopen, finish and advance atomically.
        for level in [85,87,90,95,100] {
            var p=ReefProgress();p.puzzle = .make(level:level);p.puzzle.attemptStarted=true;p.hints=3;p.supplies.lighters=1
            let dir=root.appendingPathComponent("burst-real-\(level)")
            try ReefSaveFile(defaults:defaults,directory:dir).write(p)
            let game=ReefStore(defaults:defaults,saveDirectory:dir)
            precondition(game.showHint() && game.puzzle.revealedHint != nil)
            let hint=game.puzzle.revealedHint!
            game.tapCoral(hint)
            if level==87, let sleepy=game.puzzle.coralIndices.first(where:{!game.puzzle.cells[$0]}) {
                precondition(game.lightCoral(sleepy))
            }
            let resumed=ReefStore(defaults:defaults,saveDirectory:dir)
            precondition(!resumed.isSaveBlocked && resumed.puzzle.cells==game.puzzle.cells && resumed.puzzle.burstCorals==p.puzzle.burstCorals)
            for i in resumed.puzzle.solution()! {resumed.tapCoral(i)}
            precondition(resumed.isComplete && resumed.puzzle.rewarded && resumed.progress.completedBloomLevels.contains(level))
            precondition(resumed.puzzle.recordedFrames?.last?.cells==resumed.puzzle.cells)
            resumed.nextPuzzle();precondition(resumed.puzzle.level==min(100,level+1))
            if level==100 {precondition(resumed.isComplete && resumed.progress.bloomChapterComplete)}
        }
        // Invalid burst positions must never be silently accepted by a save.
        for bad in [[-1],[25],[12,12],[0]] {
            var invalid=ReefProgress();invalid.puzzle = .make(level:100);invalid.puzzle.burstCorals=bad
            do {try ReefSaveFile(defaults:defaults,directory:root.appendingPathComponent("invalid-burst")).write(invalid);fatalError("Accepted invalid burst")}
            catch ReefSaveError.invalidData {}
        }
        print("Old level-70 cap, new burst hints/playback/relaunch, final cap and invalid-save protection verified")
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
        let (end,_)=try fixture("level-cap",level:100)
        for tap in end.puzzle.solution()! {end.tapCoral(tap)}
        end.nextPuzzle();precondition(end.puzzle.level==100 && end.isComplete)
        precondition(!end.startFromLevel(101))
        print("Once-only lighter rewards, relaunch/checkpoints and level-100 cap verified")
        print("Saved attempts/checkpoints retained; untouched boards and Restart adopt new layouts without changing other resources")
    }
}
