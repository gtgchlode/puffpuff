import Foundation

@main struct PathGoalsCheck {
    @MainActor static func main() throws {
        setbuf(stdout,nil)
        let root=URL(fileURLWithPath:CommandLine.arguments[1])
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let defaults=UserDefaults(suiteName:"puffpuff-path-goals-\(UUID())")!
        func fixture(_ value:ReefProgress,_ name:String)throws->ReefStore {
            let directory=root.appendingPathComponent(name)
            try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
            try JSONEncoder().encode(value).write(to:directory.appendingPathComponent("progress.json"))
            return ReefStore(defaults:defaults,saveDirectory:directory)
        }
        var fresh=ReefProgress();fresh.glow=1000
        let store=try fixture(fresh,"required-route")
        func open(_ find:ReefCove.Find) {
            let object=ReefCove.objects(in:store.progress.firstReef.location!).first{$0.find == find}!
            let balance=store.progress.glow
            precondition(store.uncoverCove(object.id) != nil)
            precondition(store.progress.glow == balance-object.cost)
        }
        func visit(_ id:String) { precondition(store.visitFirstReef(id) != nil,"Cannot visit \(id)") }
        precondition(!store.startReefBonus())
        open(.passage);visit("south");open(.passage)
        visit("food-sand");open(.food);visit("south")
        visit("hint-shell");open(.passage);visit("lower");open(.passage)
        visit("kelp");open(.passage);visit("food-garden");open(.food);open(.passage)
        visit("north");open(.passage);visit("food-middle");open(.food);open(.passage)
        precondition(!store.progress.firstReef.completed && !store.startReefBonus())
        visit("home")
        precondition(store.progress.firstReef.completed && store.progress.firstReef.hasFoundHome)
        precondition(store.progress.firstReef.treasures.isEmpty)
        precondition(!ReefCove.isComplete("home",in:store.progress.firstReef))
        precondition(store.startReefBonus(),"Optional chests must not gate Bonus putt")
        print("Required route example: \(1000-store.progress.glow) Glow; Bonus putt available with all six optional treasure finds unopened")
        let all=FirstReef.destinations.flatMap{ReefCove.objects(in:$0.id)}
        let full=all.reduce(0){$0+$1.cost}
        print("Full clear: \(full) Glow = \(Int(ceil(Double(full)/4)))–\(Int(ceil(Double(full)/3))) Bloom wins")
        precondition(all.allSatisfy{(8...24).contains($0.baseCost) && $0.cost==$0.baseCost*($0.challengeKind == nil ? 1:4)})
        for node in FirstReef.destinations {
            let prices=ReefCove.objects(in:node.id).map(\.baseCost)
            precondition(prices.max()! <= prices.min()!*3,"Local price gap is too wide")
            var fullyOpen=FirstReefProgress();fullyOpen.cleared=Set(FirstReef.clearances.map(\.id))
            let exits=FirstReef.neighbors(node.id,state:fullyOpen).map(FirstReef.node)
            for (w,h) in [(340.0,420.0),(393.0,620.0),(480.0,740.0)] {
                for exit in exits {
                    let delta=exit.point-node.point,angle=ReefCove.exitBearing(to:exit,from:node.id)
                    precondition(abs(sin(angle)-delta.x/delta.length)<0.0001 && abs(-cos(angle)-delta.y/delta.length)<0.0001)
                    let p=ReefCove.exitPoint(to:exit,from:node.id,exits:exits,width:w,height:h)
                    precondition(p.x>=46 && p.x<=w-46 && p.y>=39 && p.y<=h-39)
                    precondition(p.x-46>=104 || p.y-39>=132,"Exit overlaps folded map")
                    for other in exits where other.id != exit.id {
                        let q=ReefCove.exitPoint(to:other,from:node.id,exits:exits,width:w,height:h)
                        if abs(p.x-q.x)<92 && abs(p.y-q.y)<78 {print("Overlap: \(node.id), \(exit.id) at \(p), \(other.id) at \(q), size \(w)×\(h)")}
                        precondition(abs(p.x-q.x)>=92 || abs(p.y-q.y)>=78,"Overlapping exits at \(node.id): \(exit.id), \(other.id)")
                    }
                    let start=ReefPoint(x:0.24,y:0.69),size=ReefPoint(x:w,y:h)
                    let first=ReefCove.travelFrame(from:node.point,to:exit.point,start:start,size:size,fraction:0)
                    let last=ReefCove.travelFrame(from:node.point,to:exit.point,start:start,size:size,fraction:1)
                    precondition(first.fish == ReefPoint(x:start.x*w,y:start.y*h) && first.oldOffset == ReefPoint(x:0,y:0))
                    precondition((last.fish-ReefPoint(x:w*0.5,y:h*0.51)).length<0.0001 && last.newOffset == ReefPoint(x:0,y:0))
                    var prior=first
                    for step in 1...120 {
                        let frame=ReefCove.travelFrame(from:node.point,to:exit.point,start:start,size:size,fraction:Double(step)/120)
                        precondition((frame.fish-prior.fish).length<20,"Fish jumps between scrolling frames")
                        precondition((frame.oldOffset-prior.oldOffset).length<40,"Camera jumps")
                        prior=frame
                    }
                }
            }
        }
        print("Base prices 8–24 Glow; challenge bypasses cost 4×; map bearings, separated exit targets and continuous camera/fish motion checked at three phone/Mac sizes")
        // Enumerate every useful set of paid passages, including both gated shortcuts.
        // Free arrival/retreat means paying a passage exposes all of its neighbors.
        // Leaf excursions with no goal or quest gate cannot lower a required-route cost.
        let goals=Set(FirstReef.food.map(\.id)+["home"])
        let protected=goals.union(["start"]).union(FirstReef.lanes.compactMap(\.gate))
        var relevant=Set(FirstReef.destinations.map(\.id))
        while true {
            let leaves=relevant.filter { id in
                !protected.contains(id) && FirstReef.lanes.filter {
                    relevant.contains($0.a) && relevant.contains($0.b) && ($0.a == id || $0.b == id)
                }.count <= 1
            }
            if leaves.isEmpty {break};relevant.subtract(leaves)
        }
        let areas=relevant.sorted(),combinations=1<<areas.count
        var valid=Array(repeating:false,count:combinations),costs=Array(repeating:0,count:combinations)
        valid[0]=true
        let snacks=FirstReef.food.reduce(0){$0+ReefCove.objects(in:$1.id).first{$0.find == .food}!.cost}
        var cheapest=Int.max,checked=0
        for mask in 0..<combinations where valid[mask] {
            checked += 1
            let paid=Set(areas.indices.filter{mask & (1<<$0) != 0}.map{areas[$0]})
            var state=FirstReefProgress();state.cleared=paid
            var reached:Set<String>=["start"]
            for area in paid {reached.formUnion(FirstReef.neighbors(area,state:state))}
            if goals.isSubset(of:reached) {cheapest=min(cheapest,costs[mask]+snacks)}
            for i in areas.indices where mask & (1<<i) == 0 && reached.contains(areas[i]) {
                let next=mask | (1<<i)
                valid[next]=true
                costs[next]=costs[mask]+ReefCove.objects(in:areas[i]).first{$0.find == .passage}!.cost
            }
        }
        precondition(cheapest>=200 && cheapest<=1000,"Paid bypass route cost is invalid: \(cheapest)")
        precondition(1000-store.progress.glow<=1000,"The paid bypass route must fit its authored budget")
        print("All \(checked) reachable passage sets checked: cheapest required path \(cheapest) Glow (\(Int(ceil(Double(cheapest)/4)))–\(Int(ceil(Double(cheapest)/3))) wins), including shortcuts")
        let shortcut=try fixture(fresh,"cheapest-route")
        let steps:[(String,ReefCove.Find?)]=[("start",.passage),("south",.passage),
            ("food-sand",.food),("food-sand",.passage),("sand",.passage),("lower",.passage),
            ("north",.passage),("food-garden",.food),("north",nil),
            ("food-middle",.food),("food-middle",.passage),("home",nil)]
        for (area,find) in steps {
            if shortcut.progress.firstReef.location != area {precondition(shortcut.visitFirstReef(area) != nil)}
            if let find {
                let object=ReefCove.objects(in:area).first{$0.find == find}!
                precondition(shortcut.uncoverCove(object.id) != nil)
            }
        }
        precondition(shortcut.progress.firstReef.completed && shortcut.startReefBonus())
        precondition(1000-shortcut.progress.glow >= cheapest && 1000-shortcut.progress.glow<=1000)
        print("Shortcut route replayed through actual paid store actions; all optional treasure finds remain unopened")

        var earlyHome=store.progress
        earlyHome.firstReef.bonus=nil;earlyHome.firstReef.completed=false
        earlyHome.firstReef.location="food-middle";earlyHome.firstReef.position=FirstReef.node("food-middle").point
        earlyHome.firstReef.food.remove("food-middle")
        let snack=ReefCove.objects(in:"food-middle").first{$0.find == .food}!
        earlyHome.firstReef.coveSearches?.remove(snack.id)
        let lastSnack=try fixture(earlyHome,"home-before-snacks")
        precondition(lastSnack.progress.firstReef.hasFoundHome && !lastSnack.startReefBonus())
        precondition(snack.isChest && snack.action == "Open")
        precondition(lastSnack.uncoverCove(snack.id) != nil && lastSnack.progress.firstReef.completed)
        precondition(lastSnack.startReefBonus())
        let count=lastSnack.progress.firstReef.food.count,balance=lastSnack.progress.glow
        precondition(lastSnack.uncoverCove(snack.id) == nil)
        precondition(lastSnack.progress.firstReef.food.count == count && lastSnack.progress.glow == balance)
        let loaded=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("home-before-snacks"))
        precondition(loaded.progress.firstReef.completed && loaded.progress.firstReef.food.count == 3)
        print("Home before the last snack unlocks immediately; duplicate taps cannot re-charge or re-award; reload retains the unlock")

        var poor=fresh;poor.glow=0
        let empty=try fixture(poor,"no-glow")
        let chest=ReefCove.objects(in:"start").first{$0.find == .hint}!
        precondition(empty.uncoverCove(chest.id) == nil)
        precondition(empty.progress.firstReef.coveSearches!.isEmpty && empty.progress.hints == poor.hints)
        let shots=ReefCove.objects(in:"start").first{$0.find == .shot}!
        let supplies=try fixture(fresh,"shot-chest")
        precondition(supplies.uncoverCove(shots.id) != nil)
        precondition(supplies.progress.shots == fresh.shots+3 && supplies.progress.glow == fresh.glow-shots.cost)
        let paid=supplies.progress
        precondition(supplies.uncoverCove(shots.id) == nil)
        precondition(supplies.progress.shots == paid.shots && supplies.progress.glow == paid.glow)
        let chestReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("shot-chest"))
        precondition(chestReload.uncoverCove(shots.id) == nil && chestReload.progress.shots == paid.shots)
        print("No Glow leaves a chest closed; shot chests grant once, with repeat taps and reloads preserving the paid state")

        var replay=fresh;replay.completedBloomLevels=[1,2];replay.bloomRewardWins=0
        replay.lifeGiftSeed=(1...10000).map(UInt64.init).first {seed in (1...6).allSatisfy{!ReefStore.hasBonusShot(seed:seed,win:$0)}}!
        let wins=try fixture(replay,"bloom-shots")
        for win in 1...6 {
            // Replays of already cleared levels still count as newly won attempts.
            precondition(wins.startFromBeginning())
            for tap in wins.puzzle.solution()! { wins.tapCoral(tap) }
            precondition(wins.isComplete && wins.progress.bloomWinsTowardShot == win%5)
            precondition(wins.progress.shots == fresh.shots+win/5)
            precondition((wins.puzzle.earnedShot == true) == win.isMultiple(of:5))
            let reloaded=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("bloom-shots"))
            precondition(reloaded.progress.shots == wins.progress.shots && reloaded.progress.bloomWinsTowardShot == win%5)
            wins.tapCoral(0)
            precondition(wins.progress.shots == fresh.shots+win/5 && wins.progress.bloomWinsTowardShot == win%5)
        }
        var legacy=fresh;legacy.lifeGiftSeed=replay.lifeGiftSeed;legacy.version=19;legacy.completedBloomLevels=[1,2,3,4]
        let migrated=try fixture(legacy,"v19-shots")
        precondition(migrated.progress.version == 28 && migrated.progress.shots == legacy.shots)
        precondition(migrated.progress.bloomWinsTowardShot == 4)
        precondition(migrated.startFromLevel(2))
        for tap in migrated.puzzle.solution()! {migrated.tapCoral(tap)}
        precondition(migrated.progress.shots == legacy.shots+1 && migrated.progress.bloomWinsTowardShot == 0)
        print("Every five Bloom wins earns one shot, including replays; reloads and completed boards cannot double-award; v19 migration preserves existing inventory")
        var lucky=fresh;lucky.bloomRewardWins=4
        lucky.lifeGiftSeed=(1...10000).map(UInt64.init).first{ReefStore.hasBonusShot(seed:$0,win:5)}!
        let luckyStore=try fixture(lucky,"bonus-shot")
        precondition(luckyStore.startBloomAttempt())
        // Force a write failure on the winning tap; neither grant nor roll may advance.
        let luckyDir=root.appendingPathComponent("bonus-shot")
        let backup=luckyDir.appendingPathComponent("progress-backup.json")
        if FileManager.default.fileExists(atPath:backup.path) {
            try FileManager.default.moveItem(at:backup,to:luckyDir.appendingPathComponent("retained-backup.json"))
        }
        try FileManager.default.createDirectory(at:backup,withIntermediateDirectories:false)
        let winningTap=luckyStore.puzzle.solution()!.first!
        luckyStore.tapCoral(winningTap)
        precondition(luckyStore.lastSaveFailed && !luckyStore.isComplete)
        precondition(luckyStore.progress.bloomRewardWins == 4 && luckyStore.progress.shots == lucky.shots)
        try FileManager.default.moveItem(at:backup,to:luckyDir.appendingPathComponent("retained-write-blocker"))
        luckyStore.tapCoral(winningTap)
        precondition(luckyStore.isComplete && luckyStore.progress.shots == lucky.shots+2)
        precondition(luckyStore.puzzle.earnedShots == 2)
        let luckyReload=ReefStore(defaults:defaults,saveDirectory:luckyDir)
        precondition(luckyReload.puzzle.earnedShots == 2 && luckyReload.progress.shots == lucky.shots+2)
        let bonusCount=(1...10000).filter{ReefStore.hasBonusShot(seed:42,win:$0)}.count
        precondition((900...1100).contains(bonusCount))
        print("10% extra-shot roll: \(bonusCount)/10,000 fixed samples; fifth-win + lucky bonus displays 2; failure/retry/reload keep the same outcome")
        let sampleWins=Array(1...10000)
        let hintSingles=sampleWins.filter{ReefStore.bonusHints(seed:42,win:$0,pearl:false)==1}.count
        let hintPairs=sampleWins.filter{ReefStore.bonusHints(seed:42,win:$0,pearl:true)-ReefStore.bonusHints(seed:42,win:$0,pearl:false)==2}.count
        let hintBoth=sampleWins.filter{ReefStore.bonusHints(seed:42,win:$0,pearl:true)==3}.count
        precondition((700...900).contains(hintSingles) && (400...600).contains(hintPairs))
        precondition((15...70).contains(hintBoth),"Hint rolls should be independent")
        precondition(sampleWins.allSatisfy{(0...1).contains(ReefStore.bonusHints(seed:42,win:$0,pearl:false))})
        var hintWin=fresh;hintWin.bloomRewardWins=4
        hintWin.puzzle = .make(level:5);hintWin.puzzle.attemptStarted=true;hintWin.puzzle.pearlTarget=99
        hintWin.lifeGiftSeed=(1...10000).map(UInt64.init).first{ReefStore.bonusHints(seed:$0,win:5,pearl:true)==3}!
        let hintStore=try fixture(hintWin,"hint-drops")
        let hintDir=root.appendingPathComponent("hint-drops")
        let hintBackup=hintDir.appendingPathComponent("progress-backup.json")
        if FileManager.default.fileExists(atPath:hintBackup.path) {
            try FileManager.default.moveItem(at:hintBackup,to:hintDir.appendingPathComponent("retained-backup.json"))
        }
        try FileManager.default.createDirectory(at:hintBackup,withIntermediateDirectories:false)
        let hintTaps=hintStore.puzzle.solution()!;precondition(hintTaps.count==1)
        hintStore.tapCoral(hintTaps[0])
        precondition(hintStore.lastSaveFailed && !hintStore.isComplete)
        precondition(hintStore.progress.hints==hintWin.hints && hintStore.progress.bloomRewardWins==4 && hintStore.puzzle.earnedHints==nil)
        try FileManager.default.moveItem(at:hintBackup,to:hintDir.appendingPathComponent("retained-write-blocker"))
        hintStore.tapCoral(hintTaps[0])
        precondition(hintStore.isComplete && hintStore.puzzle.earnedHints==4 && hintStore.progress.hints==hintWin.hints+4)
        let hintsReload=ReefStore(defaults:defaults,saveDirectory:hintDir)
        precondition(hintsReload.puzzle.earnedHints==4 && hintsReload.progress.hints==hintWin.hints+4)
        hintsReload.tapCoral(hintTaps[0])
        precondition(hintsReload.progress.hints==hintWin.hints+4 && hintsReload.progress.bloomRewardWins==5)
        let firstWinBoard=try JSONSerialization.jsonObject(with:JSONEncoder().encode(hintsReload.puzzle)) as! NSDictionary
        let livesBeforeReplay=hintsReload.progress.supplies.lives
        precondition(hintsReload.startFromLevel(5) && hintsReload.isComplete,"Normal Bloom navigation must retain the win")
        precondition(hintsReload.startFromLevel(5,replayCompleted:true) && !hintsReload.isComplete)
        precondition(hintsReload.puzzle.moves==0 && hintsReload.puzzle.earnedHints==nil && hintsReload.puzzle.rewarded==false)
        precondition(hintsReload.progress.bloomResumePuzzle?.earnedHints==4 && hintsReload.progress.supplies.lives==livesBeforeReplay)
        for tap in hintsReload.puzzle.solution()! {hintsReload.tapCoral(tap)}
        let replayHints=ReefStore.bonusHints(seed:hintWin.lifeGiftSeed,win:6,pearl:hintsReload.puzzle.earnedPearl)
        precondition(hintsReload.progress.hints==hintWin.hints+4+replayHints,"Replay gets chance rewards, not another milestone")
        precondition(hintsReload.startFromLatest())
        let restoredWinBoard=try JSONSerialization.jsonObject(with:JSONEncoder().encode(hintsReload.puzzle)) as! NSDictionary
        precondition(restoredWinBoard==firstWinBoard)
        precondition(hintsReload.startFromLevel(6,replayCompleted:true))
        precondition(hintsReload.startFromLevel(5,replayCompleted:true) && !hintsReload.isComplete,"Completed saved checkpoint must also replay")
        precondition(hintsReload.progress.bloomResumePuzzle?.earnedHints==4)
        var unfinished=fresh;unfinished.puzzle = .make(level:8);unfinished.puzzle.attemptStarted=true
        let firstTap=unfinished.puzzle.solution()!.first!;unfinished.puzzle.pulse(at:firstTap);unfinished.puzzle.moves=1
        precondition(!unfinished.puzzle.isComplete)
        let unfinishedStore=try fixture(unfinished,"debug-unfinished")
        precondition(unfinishedStore.startFromLevel(8,replayCompleted:true))
        precondition(unfinishedStore.puzzle.cells==unfinished.puzzle.cells && unfinishedStore.puzzle.moves==1)
        precondition(unfinishedStore.startFromLevel(2,replayCompleted:true))
        for tap in unfinishedStore.puzzle.solution()! {unfinishedStore.tapCoral(tap)}
        precondition(unfinishedStore.startFromLevel(8,replayCompleted:true))
        precondition(unfinishedStore.puzzle.cells==unfinished.puzzle.cells && unfinishedStore.puzzle.moves==1 && unfinishedStore.progress.bloomResumePuzzle==nil)
        var legacyHint=hintStore.progress;legacyHint.version=20;legacyHint.puzzle.earnedHints=nil
        let oldHints=try fixture(legacyHint,"v20-hints")
        precondition(oldHints.progress.version==28 && oldHints.puzzle.earnedHint==true && oldHints.puzzle.earnedHints==nil)
        precondition(oldHints.progress.hints==legacyHint.hints && oldHints.progress.bloomRewardWins==legacyHint.bloomRewardWins)
        print("Hint rolls: \(hintSingles)/10,000 singles, \(hintPairs)/10,000 pearl pairs, \(hintBoth) overlaps. Milestone + both rolls award four atomically; failure/retry/reload preserve the result.")
        print("Debug picker replays current/completed checkpoint levels, preserves unfinished boards and main checkpoints; v20 hint saves migrate without retroactive grants.")
        let intro=try fixture(fresh,"intro")
        precondition(!intro.progress.hasSeenTrailIntro && !intro.progress.hasSeenBonusIntro)
        precondition(!intro.finishIntro(.bonus),"Golf teaching must wait for required tasks")
        let introDir=root.appendingPathComponent("intro")
        let introBackup=introDir.appendingPathComponent("progress-backup.json")
        if FileManager.default.fileExists(atPath:introBackup.path) {
            try FileManager.default.moveItem(at:introBackup,to:introDir.appendingPathComponent("retained-backup.json"))
        }
        try FileManager.default.createDirectory(at:introBackup,withIntermediateDirectories:false)
        precondition(!intro.finishIntro(.trail) && !intro.progress.hasSeenTrailIntro)
        try FileManager.default.moveItem(at:introBackup,to:introDir.appendingPathComponent("retained-write-blocker"))
        precondition(intro.finishIntro(.trail) && intro.finishIntro(.trail))
        let introReload=ReefStore(defaults:defaults,saveDirectory:introDir)
        precondition(introReload.progress.hasSeenTrailIntro && !introReload.progress.hasSeenBonusIntro)
        precondition(introReload.progress.glow == fresh.glow && introReload.progress.shots == fresh.shots)
        var eligible=store.progress;eligible.firstReef.bonus=nil
        let golfIntro=try fixture(eligible,"golf-intro")
        precondition(golfIntro.finishIntro(.bonus) && golfIntro.progress.firstReef.bonus == nil)
        precondition(golfIntro.startReefBonus())
        precondition(golfIntro.progress.shots == eligible.shots && golfIntro.progress.firstReef.bonus?.strokes == 0)
        let golfReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("golf-intro"))
        precondition(golfReload.progress.hasSeenBonusIntro)
        var oldJSON=try JSONSerialization.jsonObject(with:JSONEncoder().encode(legacy)) as! [String:Any]
        oldJSON.removeValue(forKey:"hasSeenTrailIntro");oldJSON.removeValue(forKey:"hasSeenBonusIntro")
        let oldIntro=try JSONDecoder().decode(ReefProgress.self,from:JSONSerialization.data(withJSONObject:oldJSON))
        precondition(!oldIntro.hasSeenTrailIntro && !oldIntro.hasSeenBonusIntro)
        precondition(golfIntro.restartEverything() && !golfIntro.progress.hasSeenTrailIntro && !golfIntro.progress.hasSeenBonusIntro)
        print("Intros: old saves opt in once; Finish/Skip persist, failed saves roll back, golf waits for tasks and costs no shot; debug reset restores both")

        // Reproduce the reported winning-putt save rejection at the actual drawn home.
        for score in 1...FirstReef.turnLimit {
            var win=eligible;win.shots=10;win.firstReef.bonus=FirstReef.newBonus(win.firstReef)
            win.firstReef.bonus!.position=BonusCourse.home+ReefPoint(x:0,y:32)
            win.firstReef.bonus!.strokes=score-1
            let name="holed-\(score)",winning=try fixture(win,name)
            let result=winning.puttFirstReef(drag:.init(x:0,y:-10))
            precondition(result?.outcome.bonus?.holed==true && !winning.lastSaveFailed,"Holed result failed to save")
            precondition(winning.progress.firstReef.bonus!.position==BonusCourse.home)
            precondition(winning.progress.shots==9 && winning.progress.firstReef.bonus!.strokes==score)
            let restored=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent(name))
            precondition(!restored.isSaveBlocked && restored.progress.firstReef.bonus!.holed)
            precondition(restored.progress.firstReef.bonus!.canCollect==(score<=FirstReef.unlockLimit))
            let balance=restored.progress.glow
            precondition(restored.collectReefBonus()==(score<=FirstReef.unlockLimit))
            if score<=FirstReef.unlockLimit {
                precondition(restored.progress.glow==balance+FirstReef.reward(for:score).glow)
                precondition(!restored.collectReefBonus(),"A hole cannot pay twice")
                let claimed=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent(name))
                precondition(claimed.progress.firstReef.nextWorldUnlocked==true)
            }
        }
        print("Holed putts 1–6 save/reload at the drawn home; 1–4 collect once, 5–6 stay practice-only")

        for barrier in [ReefBumper.Kind.kelp,.sand] {
            let object=all.first{$0.barrier==barrier && $0.clearingReward != nil}!
            var seed=fresh;seed.firstReef.location=object.area;seed.firstReef.position=FirstReef.node(object.area).point
            seed.firstReef.visited=["start",object.area]
            let name="clearing-\(object.id)",clearing=try fixture(seed,name)
            let award=object.clearingReward!,before=clearing.progress
            precondition(clearing.uncoverCove(object.id) != nil)
            precondition(clearing.progress.firstReef.clearingRewards?[object.id]==award)
            switch award {
            case .shot:precondition(clearing.progress.shots==before.shots+1)
            case .hint:precondition(clearing.progress.hints==before.hints+1)
            case .life:precondition(clearing.progress.supplies.lives>=before.supplies.lives+1)
            case .lighter:precondition(clearing.progress.supplies.lighters==before.supplies.lighters+1)
            default:preconditionFailure("Unexpected clearing reward")
            }
            precondition(clearing.uncoverCove(object.id)==nil)
            let restored=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent(name))
            precondition(restored.progress.firstReef.clearingRewards?[object.id]==award)
            precondition(restored.uncoverCove(object.id)==nil)
            var old=before;old.version=21;old.firstReef.coveSearches=[object.id]
            let migrated=try fixture(old,"old-clearing-\(object.id)")
            precondition(migrated.progress.firstReef.clearingRewards==nil && migrated.progress.shots==old.shots && migrated.progress.hints==old.hints)
            precondition(migrated.uncoverCove(object.id)==nil,"Do not reward old paid spots retroactively")
        }
        let clearingObject=all.first{$0.clearingReward != nil}!
        var failedSeed=fresh;failedSeed.firstReef.location=clearingObject.area
        failedSeed.firstReef.position=FirstReef.node(clearingObject.area).point
        failedSeed.firstReef.visited=["start",clearingObject.area]
        let failedClear=try fixture(failedSeed,"failed-clearing")
        let failureDir=root.appendingPathComponent("failed-clearing")
        let blocker=failureDir.appendingPathComponent("progress-backup.json")
        try FileManager.default.createDirectory(at:blocker,withIntermediateDirectories:false)
        precondition(failedClear.uncoverCove(clearingObject.id)==nil && failedClear.lastSaveFailed)
        precondition(failedClear.progress.glow==failedSeed.glow && failedClear.progress.firstReef.clearingRewards==nil)
        precondition(failedClear.progress.shots==failedSeed.shots && failedClear.progress.hints==failedSeed.hints)
        try FileManager.default.moveItem(at:blocker,to:failureDir.appendingPathComponent("retained-blocker"))
        precondition(failedClear.uncoverCove(clearingObject.id) != nil)
        print("Kelp/sand supplies: one paid reveal, persistent receipt, no repeat or retroactive grants; failed saves roll back and retry once")

        for node in FirstReef.destinations {
            var state=FirstReefProgress();state.cleared=Set(FirstReef.clearances.map(\.id))
            for next in FirstReef.neighbors(node.id,state:state).map(FirstReef.node) {
                for size in [ReefPoint(x:393,y:620),.init(x:480,y:740)] {
                    let a=ReefCove.routeSeam(from:node.point,to:next.point,size:size)
                    let b=ReefCove.routeSeam(from:next.point,to:node.point,size:size)
                    for n in 0...20 {
                        let frame=ReefCove.travelFrame(from:node.point,to:next.point,start:.init(x:0.5,y:0.51),size:size,fraction:Double(n)/20)
                        precondition((a+frame.oldOffset-b-frame.newOffset).length<0.0001,"Disconnected path during pan")
                    }
                }
            }
        }
        let bounds=ReefPoint(x:393,y:620)
        precondition(ReefCove.mapOffset(.init(x:-500,y:-500),size:bounds,bottomInset:34) == .init(x:0,y:0))
        precondition(ReefCove.mapOffset(.init(x:999,y:999),size:bounds,bottomInset:34) == .init(x:281,y:450))
        print("Every route joins at a shared seam throughout scrolling; flicked map stays inside safe bounds")

        var addingSeed=eligible;addingSeed.currentAdders=3
        addingSeed.firstReef.cleared=Set(FirstReef.clearances.map(\.id))
        addingSeed.firstReef.bonus=FirstReef.newBonus(addingSeed.firstReef)
        let addStore=try fixture(addingSeed,"current-adders")
        let addDir=root.appendingPathComponent("current-adders")
        let position=ReefPoint(x:150,y:483)
        precondition(BonusCourse.canPlaceCurrent(at:position,in:addStore.progress.firstReef))
        for bad in [BonusCourse.home,BonusCourse.currents[0],ReefPoint(x:-100,y:-100),.init(x:.nan,y:100)] {
            precondition(!addStore.addReefCurrent(at:bad,direction:0))
        }
        precondition(!addStore.addReefCurrent(at:position,direction:8) && addStore.progress.currentAdders==3)
        let addBlocker=addDir.appendingPathComponent("progress-backup.json")
        try FileManager.default.createDirectory(at:addBlocker,withIntermediateDirectories:false)
        precondition(!addStore.addReefCurrent(at:position,direction:0) && addStore.progress.currentAdders==3 && addStore.progress.firstReef.bonus?.addedCurrents==nil)
        try FileManager.default.moveItem(at:addBlocker,to:addDir.appendingPathComponent("retained-blocker"))
        precondition(addStore.addReefCurrent(at:position,direction:0) && addStore.progress.currentAdders==2)
        precondition(!addStore.addReefCurrent(at:position,direction:1))
        let placed=addStore.progress.firstReef.bonus!.addedCurrents!
        let addReload=ReefStore(defaults:defaults,saveDirectory:addDir)
        precondition(addReload.progress.firstReef.bonus!.addedCurrents==placed && addReload.progress.currentAdders==2)
        let shot=ReefPoint(x:70,y:-37)
        let withCurrent=FirstReef.putt(drag:shot,from:addReload.progress.firstReef)!
        var noCurrent=addReload.progress.firstReef;noCurrent.bonus!.addedCurrents=nil
        let withoutCurrent=FirstReef.putt(drag:shot,from:noCurrent)!
        precondition((withCurrent.outcome.bonus!.position-withoutCurrent.outcome.bonus!.position).length>10,"Added current must affect the putt")
        precondition(addReload.puttFirstReef(drag:shot) != nil && addReload.progress.firstReef.bonus!.addedCurrents==placed)
        let persistentDirections=addReload.progress.firstReef.bonus!.currents
        precondition(addReload.startReefBonus(retry:true))
        precondition(addReload.progress.firstReef.bonus!.addedCurrents==nil && addReload.progress.currentAdders==2)
        precondition(addReload.progress.firstReef.bonus!.currents==persistentDirections)
        let adderDrops=(1...10000).filter{ReefStore.hasCurrentAdder(seed:42,win:$0)}.count
        precondition((400...600).contains(adderDrops))
        var adderWin=ReefProgress();adderWin.puzzle = .make(level:5);adderWin.puzzle.attemptStarted=true
        adderWin.lifeGiftSeed=(1...10000).map(UInt64.init).first{ReefStore.hasCurrentAdder(seed:$0,win:1)}!
        let adderWinner=try fixture(adderWin,"adder-win")
        for index in adderWinner.puzzle.solution()! {adderWinner.tapCoral(index)}
        precondition(adderWinner.puzzle.earnedCurrentAdder==true && adderWinner.progress.currentAdders==1)
        let winReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("adder-win"))
        precondition(winReload.progress.currentAdders==1 && winReload.puzzle.earnedCurrentAdder==true)
        winReload.tapCoral(0);precondition(winReload.progress.currentAdders==1)
        print("Current adders: \(adderDrops)/10,000 independent Bloom drops; saved once, one-use placement, real physics effect, no duplicate/invalid placements, retry expires only added currents, save rollback verified")
    }
}
