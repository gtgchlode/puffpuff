import Foundation

@main struct GlowPathCheck {
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
        precondition(store.progress.firstReef.nextWorldUnlocked != true)
        open(.passage);visit("south");open(.passage)
        visit("food-sand");open(.food);visit("south")
        visit("hint-shell");open(.passage);visit("lower");open(.passage)
        visit("kelp");open(.passage);visit("food-garden");open(.food);open(.passage)
        visit("north");open(.passage);visit("food-middle");open(.food);open(.passage)
        precondition(!store.progress.firstReef.completed && store.progress.firstReef.nextWorldUnlocked != true)
        visit("home")
        precondition(!store.progress.firstReef.completed, "Visiting the doorstep is not enough; the home lights must be restored")
        precondition(!store.canVisitHome)
        open(.home)
        precondition(store.canVisitHome)
        precondition(store.progress.firstReef.completed && store.progress.firstReef.hasFoundHome)
        precondition(store.progress.firstReef.treasures.isEmpty)
        precondition(!ReefCove.isComplete("home",in:store.progress.firstReef))
        precondition(store.progress.firstReef.nextWorldUnlocked == true,"Optional chests must not gate Trail completion")
        print("Required route example: \(1000-store.progress.glow) Glow; Trail completion available with all six optional treasure finds unopened")
        let all=FirstReef.destinations.flatMap{ReefCove.objects(in:$0.id)}
        let full=all.reduce(0){$0+$1.cost}
        print("Full clear: \(full) Glow = \(Int(ceil(Double(full)/4)))–\(Int(ceil(Double(full)/3))) Bloom wins")
        precondition(all.allSatisfy{(8...24).contains($0.baseCost) && $0.cost==$0.baseCost})
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
        print("Prices 8–24 Lumes; map bearings, separated exit targets and continuous camera/fish motion checked at three phone/Mac sizes")
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
            if goals.isSubset(of:reached) {cheapest=min(cheapest,costs[mask]+snacks+20)}
            for i in areas.indices where mask & (1<<i) == 0 && reached.contains(areas[i]) {
                let next=mask | (1<<i)
                valid[next]=true
                costs[next]=costs[mask]+ReefCove.objects(in:areas[i]).first{$0.find == .passage}!.cost
            }
        }
        precondition(cheapest>=200 && cheapest<=300,"Paid route cost is invalid: \(cheapest)")
        precondition(1000-store.progress.glow<=1000,"The paid bypass route must fit its authored budget")
        print("All \(checked) reachable passage sets checked: cheapest required path \(cheapest) Glow (\(Int(ceil(Double(cheapest)/4)))–\(Int(ceil(Double(cheapest)/3))) wins), including shortcuts")
        let shortcut=try fixture(fresh,"cheapest-route")
        let steps:[(String,ReefCove.Find?)]=[("start",.passage),("south",.passage),
            ("food-sand",.food),("food-sand",.passage),("sand",.passage),("lower",.passage),
            ("north",.passage),("food-garden",.food),("north",nil),
            ("food-middle",.food),("food-middle",.passage),("home",.home)]
        for (area,find) in steps {
            if shortcut.progress.firstReef.location != area {precondition(shortcut.visitFirstReef(area) != nil)}
            if let find {
                let object=ReefCove.objects(in:area).first{$0.find == find}!
                precondition(shortcut.uncoverCove(object.id) != nil)
            }
        }
        precondition(shortcut.progress.firstReef.completed && shortcut.progress.firstReef.nextWorldUnlocked == true)
        precondition(1000-shortcut.progress.glow >= cheapest && 1000-shortcut.progress.glow<=1000)
        print("Shortcut route replayed through actual paid store actions; all optional treasure finds remain unopened")

        var earlyHome=store.progress
        earlyHome.firstReef.bonus=nil;earlyHome.firstReef.completed=false;earlyHome.firstReef.nextWorldUnlocked=false
        earlyHome.firstReef.location="food-middle";earlyHome.firstReef.position=FirstReef.node("food-middle").point
        earlyHome.firstReef.food.remove("food-middle")
        let snack=ReefCove.objects(in:"food-middle").first{$0.find == .food}!
        earlyHome.firstReef.coveSearches?.remove(snack.id)
        let lastSnack=try fixture(earlyHome,"home-before-snacks")
        precondition(lastSnack.progress.firstReef.hasFoundHome && lastSnack.progress.firstReef.nextWorldUnlocked != true)
        precondition(!snack.isChest && snack.action == "Relight garden")
        precondition(lastSnack.uncoverCove(snack.id) != nil && lastSnack.progress.firstReef.completed)
        precondition(lastSnack.progress.firstReef.nextWorldUnlocked == true)
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
        let supply=ReefCove.objects(in:"start").first{$0.slot == 4}!
        let supplies=try fixture(fresh,"supply-chest")
        precondition(supplies.uncoverCove(supply.id) != nil)
        precondition(supplies.progress.hints == fresh.hints+1 && supplies.progress.glow == fresh.glow-supply.cost)
        let paid=supplies.progress
        precondition(supplies.uncoverCove(supply.id) == nil)
        let chestReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("supply-chest"))
        precondition(chestReload.uncoverCove(supply.id) == nil && chestReload.progress.hints == paid.hints)
        print("Supplies cost Lumes and grant once; repeats and reloads cannot charge or grant again")

        var replay=fresh;replay.completedBloomLevels=[1,2];replay.bloomRewardWins=0
        replay.shots=9;replay.currentChangers=3;replay.currentAdders=4;replay.bouncyBlocks=2
        let wins=try fixture(replay,"no-golf-rewards")
        var earnedLumes = fresh.glow
        for win in 1...100 {
            precondition(wins.startFromBeginning())
            for tap in wins.puzzle.solution()! { wins.tapCoral(tap) }
            precondition(wins.isComplete && wins.progress.bloomRewardWins == win)
            precondition(wins.progress.shots == 9 && wins.progress.currentChangers == 3 && wins.progress.currentAdders == 4 && wins.progress.bouncyBlocks == 2)
            precondition(wins.puzzle.earnedShot != true && wins.puzzle.earnedCurrentAdder != true && wins.puzzle.earnedBouncyBlock != true)
            earnedLumes += wins.puzzle.earnedPearl ? 4 : 3
            precondition(wins.progress.glow == earnedLumes)
        }
        print("100 wins earn Lumes and puzzle supplies only; legacy golf balances remain unchanged")

        // Every authored find can be paid for, remains one-time, and grants no golf supply.
        for object in all {
            precondition(object.clearingReward?.isGolfSupply != true)
            var seed=fresh;seed.shots=8;seed.currentChangers=2;seed.currentAdders=3;seed.bouncyBlocks=4
            seed.firstReef.location=object.area;seed.firstReef.position=FirstReef.node(object.area).point
            seed.firstReef.visited=["start",object.area]
            let finding=try fixture(seed,"find-"+object.id)
            precondition(finding.uncoverCove(object.id) != nil)
            precondition(finding.progress.glow==seed.glow-object.cost && finding.uncoverCove(object.id)==nil)
            precondition(finding.progress.shots==8 && finding.progress.currentChangers==2 && finding.progress.currentAdders==3 && finding.progress.bouncyBlocks==4)
        }
        print("All authored finds paid and saved once; no golf prizes remain")

        // Old incomplete, complete, ongoing-golf and collected-golf saves all migrate.
        func equal<T:Encodable>(_ a:T,_ b:T)->Bool {
            let e=JSONEncoder();e.outputFormatting = .sortedKeys
            return try! e.encode(a)==e.encode(b)
        }
        for stage in 0...3 {
            var old=stage==0 ? replay:store.progress
            old.version=28;old.firstReef.rescueRevision=nil;old.firstReef.bubbaRescued=nil;old.firstReef.homeDecorations=nil;old.firstReef.glowPuzzleRevision=nil;old.firstReef.legacyGolfFinds=nil
            old.firstReef.nextWorldUnlocked=stage==3
            old.firstReef.coveSearches?.insert("start:4")
            old.shots=17;old.currentChangers=4;old.currentAdders=5;old.bouncyBlocks=6
            let oldKelp=all.first{$0.legacyChallengeKind == .kelp}!
            old.firstReef.miniChallenges=[oldKelp.id:.fresh(.kelp)]
            if stage>=2 {
                old.firstReef.bonus=FirstReef.newBonus(old.firstReef)
                if stage==3 {
                    old.firstReef.bonus?.position=BonusCourse.home
                    old.firstReef.bonus?.strokes=3;old.firstReef.bonus?.bestStrokes=3
                    old.firstReef.bonus?.holed=true;old.firstReef.bonus?.finished=true;old.firstReef.bonus?.claimed=true
                }
            }
            let name="v28-stage-\(stage)",migrated=try fixture(old,name)
            precondition(!migrated.isSaveBlocked && !migrated.lastSaveFailed && migrated.progress.version==31)
            precondition(migrated.progress.firstReef.nextWorldUnlocked == old.firstReef.completed)
            precondition(migrated.progress.firstReef.legacyGolfFinds?.contains("start:4")==true)
            precondition(migrated.progress.firstReef.food==old.firstReef.food && migrated.progress.firstReef.coveSearches==old.firstReef.coveSearches)
            precondition(migrated.progress.firstReef.miniChallenges==old.firstReef.miniChallenges && equal(migrated.progress.firstReef.bonus,old.firstReef.bonus))
            precondition(equal(migrated.puzzle,old.puzzle) && migrated.progress.glow==old.glow && migrated.progress.shots==17 && migrated.progress.currentAdders==5)
            if stage==3 {
                let optional=ReefCove.objects(in:"home").first{$0.slot==4}!
                precondition(migrated.uncoverCove(optional.id) != nil,"Claimed golf must no longer lock optional exploration")
                precondition(migrated.progress.hints==old.hints+1)
            }
            let reloaded=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent(name))
            precondition(!reloaded.isSaveBlocked && reloaded.progress.firstReef.nextWorldUnlocked==old.firstReef.completed)
        }
        print("v28 migrations preserve boards, balances, opened finds and golf history; completed/claimed trails stay explorable")

        // v29 story migration credits previous visits without changing balances or puzzle data.
        for visitedHome in [false,true] {
            var old=fresh;old.version=29;old.firstReef.rescueRevision=nil
            old.firstReef.bubbaRescued=nil;old.firstReef.homeDecorations=nil
            old.firstReef.food=Set(FirstReef.food.map(\.id))
            if visitedHome {
                old.firstReef.visited?.insert("home");old.firstReef.completed=true;old.firstReef.nextWorldUnlocked=true
            }
            let migrated=try fixture(old,"v29-home-\(visitedHome)")
            precondition(!migrated.isSaveBlocked && !migrated.lastSaveFailed)
            precondition(migrated.progress.firstReef.hasRestoredHome == visitedHome)
            precondition(migrated.progress.firstReef.completed == visitedHome)
            precondition(migrated.progress.glow==old.glow && equal(migrated.puzzle,old.puzzle))
            precondition(migrated.progress.firstReef.homeDecorations?.isEmpty == true)
        }
        let lockedHouse=try fixture(fresh,"house-locked")
        let lockedBefore=lockedHouse.progress
        precondition(!lockedHouse.canVisitHome && !lockedHouse.isHomeShopUnlocked && !lockedHouse.buyHomeItem(.shellSeat))
        precondition(equal(lockedBefore,lockedHouse.progress))
        var houseReady=fresh;houseReady.firstReef=store.progress.firstReef
        precondition(houseReady.firstReef.completed)
        let house=try fixture(houseReady,"house")
        for item in ReefHomeItem.allCases {
            let balance=house.progress.glow,reef=house.progress.firstReef
            precondition(house.buyHomeItem(item))
            precondition(house.progress.glow == balance-item.cost)
            precondition(house.progress.firstReef.homeDecorations?.contains(item.id)==true)
            precondition(house.progress.firstReef.coveSearches==reef.coveSearches && house.progress.firstReef.completed==reef.completed)
            precondition(!house.buyHomeItem(item))
        }
        let homeReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("house"))
        precondition(homeReload.progress.firstReef.homeDecorations?.count==3 && homeReload.progress.glow==house.progress.glow)
        precondition(!empty.buyHomeItem(.shellSeat) && empty.progress.glow==0)
        let homeFailure=try fixture(houseReady,"house-failure")
        try FileManager.default.createDirectory(at:root.appendingPathComponent("house-failure/progress-backup.json"),withIntermediateDirectories:false)
        let homeBefore=homeFailure.progress
        precondition(!homeFailure.buyHomeItem(.shellSeat) && equal(homeFailure.progress,homeBefore))
        print("v29 migration, rescue gating, permanent optional furnishings, repeat/poor purchases, reload and failed-write rollback passed")

        // Existing homes retain ownership/default placement without a new purchase.
        var legacyHome=fresh;legacyHome.version=30
        legacyHome.firstReef.homeDecorations=[ReefHomeItem.shellSeat.id]
        legacyHome.firstReef.homeRoom=nil
        let oldHome=try fixture(legacyHome,"v30-home")
        precondition(oldHome.progress.version==31 && oldHome.progress.glow==legacyHome.glow)
        precondition(oldHome.progress.firstReef.furnishedRoom.placements["shellSeat"]?.position == ReefHomeItem.shellSeat.homePosition)
        precondition(!oldHome.isHomeShopUnlocked && oldHome.canVisitHome)
        precondition(oldHome.arrangeHomeItem(.shellSeat,placement:.init(position:.init(x:0.35,y:0.78))))
        let moved=ReefHomePlacement(position:.init(x:0.36,y:0.82),flipped:true)
        let resources=house.progress
        precondition(house.arrangeHomeItem(.shellSeat,placement:moved))
        precondition(house.setHomeLantern(false))
        precondition(house.progress.glow==resources.glow && equal(house.puzzle,resources.puzzle) && house.progress.supplies==resources.supplies)
        precondition(house.progress.firstReef.coveSearches==resources.firstReef.coveSearches)
        let arranged=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("house"))
        precondition(arranged.progress.firstReef.furnishedRoom.placements["shellSeat"]==moved)
        precondition(!arranged.progress.firstReef.furnishedRoom.lanternOn)
        precondition(arranged.arrangeHomeItem(.shellSeat,placement:nil))
        precondition(arranged.progress.firstReef.homeDecorations!.contains("shellSeat"))
        let stored=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("house"))
        precondition(stored.progress.firstReef.furnishedRoom.placements["shellSeat"]==nil)
        precondition(stored.arrangeHomeItem(.shellSeat,placement:moved))
        precondition(!stored.buyHomeItem(.shellSeat))
        precondition(!empty.arrangeHomeItem(.shellSeat,placement:moved) && !empty.setHomeLantern(false))
        let untouched=stored.progress
        for bad in [ReefPoint(x:-1,y:0.6),.init(x:.infinity,y:0.6),.init(x:0.5,y:.nan),.init(x:0.2,y:0.3),ReefHomeItem.pearlLantern.homePosition] {
            precondition(!stored.arrangeHomeItem(.shellSeat,placement:.init(position:bad)))
            precondition(equal(untouched,stored.progress))
        }
        // Occupied default spots never make a newly bought item collide or fail saving.
        var crowdedSave=houseReady;crowdedSave.firstReef.homeDecorations=["shellSeat"];crowdedSave.firstReef.homeRoom=nil
        let crowded=try fixture(crowdedSave,"occupied-home")
        precondition(crowded.arrangeHomeItem(.shellSeat,placement:.init(position:ReefHomeItem.pearlLantern.homePosition)))
        precondition(crowded.buyHomeItem(.pearlLantern))
        precondition(crowded.progress.firstReef.furnishedRoom.placements["pearlLantern"]?.position != ReefHomeItem.pearlLantern.homePosition)
        precondition(FirstReef.valid(crowded.progress.firstReef))
        let broken=try fixture(house.progress,"home-arrange-failure")
        try FileManager.default.createDirectory(at:root.appendingPathComponent("home-arrange-failure/progress-backup.json"),withIntermediateDirectories:false)
        let brokenBefore=broken.progress
        precondition(!broken.arrangeHomeItem(.shellSeat,placement:nil) && equal(brokenBefore,broken.progress))
        precondition(!broken.setHomeLantern(true) && equal(brokenBefore,broken.progress))
        print("House: v30 ownership retained, placement/flip/storage/light persisted, no extra costs, invalid/overlap rejected, failed writes rolled back")

        // Failed spending saves roll back cost, reveal and reward as a single transaction.
        let fail=try fixture(fresh,"write-failure")
        let failDir=root.appendingPathComponent("write-failure")
        let blocker=failDir.appendingPathComponent("progress-backup.json")
        try FileManager.default.createDirectory(at:blocker,withIntermediateDirectories:false)
        let before=fail.progress
        precondition(fail.uncoverCove(supply.id)==nil && fail.lastSaveFailed)
        precondition(equal(fail.progress,before))
        try FileManager.default.moveItem(at:blocker,to:failDir.appendingPathComponent("retained-write-blocker"))
        precondition(fail.uncoverCove(supply.id) != nil && fail.progress.hints==before.hints+1)
        print("Failed payments retain Lumes, contents and map state; retry awards once")

        // Test copies of the user's real saves without mutating their originals.
        let paths=CommandLine.arguments.dropFirst(2)
        for (index,path) in paths.enumerated() {
            let data=try Data(contentsOf:URL(fileURLWithPath:path))
            let old=try JSONDecoder().decode(ReefProgress.self,from:data)
            let copy=try fixture(old,"real-save-copy-\(index)")
            precondition(!copy.isSaveBlocked && !copy.lastSaveFailed)
            precondition(equal(copy.puzzle,old.puzzle) && equal(copy.progress.bloomResumePuzzle,old.bloomResumePuzzle))
            precondition(copy.progress.glow==old.glow && copy.progress.shots==old.shots && copy.progress.hints==old.hints)
            precondition((old.firstReef.coveSearches ?? []).isSubset(of:copy.progress.firstReef.coveSearches ?? []) && copy.progress.firstReef.food==old.firstReef.food)
        }
        print("Real save copies checked: \(paths.count). Originals untouched.")
    }
}
