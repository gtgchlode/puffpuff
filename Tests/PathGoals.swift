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
        precondition(all.allSatisfy{(8...24).contains($0.cost)})
        for node in FirstReef.destinations {
            let prices=ReefCove.objects(in:node.id).map(\.cost)
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
        print("Prices 8–24 Glow with bounded local spread; map bearings, separated exit targets and continuous camera/fish motion checked at three phone/Mac sizes")
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
        precondition(cheapest>=200 && cheapest<=300,"Required path pacing fell outside 50–100 wins: \(cheapest)")
        precondition(1000-store.progress.glow<=300,"The ordinary route must also fit the target")
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
        precondition(1000-shortcut.progress.glow == cheapest,"The minimum must be playable with real store transactions")
        print("Cheapest route replayed through actual paid store actions; all optional treasure finds remain unopened")

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
        precondition(migrated.progress.version == 20 && migrated.progress.shots == legacy.shots)
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
    }
}
