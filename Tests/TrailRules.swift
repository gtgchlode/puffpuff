import Foundation
@main struct Check {
 @MainActor static func main() throws {
  setbuf(stdout,nil)
  let root=URL(fileURLWithPath:CommandLine.arguments[1]);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
  let defaults=UserDefaults(suiteName:"puffpuff-tests-\(UUID())")!
  let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
  func normal(_ value:Any,key:String="")->Any {
   if let dict=value as? [String:Any] {return dict.mapValues{$0}.reduce(into:[String:Any]()){$0[$1.key]=normal($1.value,key:$1.key)}}
   if let array=value as? [Any] {
    let values=array.map{normal($0)}
    return ["food","treasures","cleared","visited","coveSearches","completedBloomLevels","clearedObjects","restoredStops","learnedDiscoveries"].contains(key) ? values.sorted{String(describing:$0)<String(describing:$1)}:values
   }
   return value
  }
  func equal<T:Encodable>(_ a:T,_ b:T)->Bool {
   let left=try! JSONSerialization.jsonObject(with:encoder.encode(a),options:.fragmentsAllowed)
   let right=try! JSONSerialization.jsonObject(with:encoder.encode(b),options:.fragmentsAllowed)
   return (normal(left) as! NSObject).isEqual(normal(right))
  }
  func seed(_ progress:ReefProgress,_ name:String)throws->URL {
   let dir=root.appendingPathComponent(name);try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
   try encoder.encode(progress).write(to:dir.appendingPathComponent("progress.json"));return dir
  }
  var old:ReefProgress
  if CommandLine.arguments.count>2 {
   old=try JSONDecoder().decode(ReefProgress.self,from:Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[2])))
  } else {
   old=ReefProgress();old.version=15;old.glow=80;old.hints=2;old.shots=16
   old.puzzle=CoralPuzzle.make(level:42);old.bloomResumePuzzle=CoralPuzzle.make(level:43)
   old.firstReef.coveSearches=nil
   old.firstReef.food=Set(FirstReef.food.map(\.id));old.firstReef.completed=true
   old.firstReef.cleared=["sand","kelp","enemy"];old.firstReef.treasures=["hint-shell"]
   old.firstReef.visited=Set(FirstReef.destinations.map(\.id));old.firstReef.location="home";old.firstReef.position=FirstReef.home
   old.firstReef.bonus=FirstReef.newBonus(old.firstReef)
   old.firstReef.bonus!.currents=nil;old.firstReef.bonus!.courseRevision=2;old.firstReef.bonus!.bestStrokes=2
  }
  let migratedDir=try seed(old,"legacy")
  let migrated=ReefStore(defaults:defaults,saveDirectory:migratedDir)
  precondition(!migrated.isSaveBlocked && !migrated.lastSaveFailed)
  let m=migrated.progress
  precondition(m.version==20 && m.currentChangers==0 && equal(m.puzzle,old.puzzle) && equal(m.bloomResumePuzzle,old.bloomResumePuzzle))
  precondition(m.glow==old.glow && m.hints==old.hints && m.shots==old.shots && equal(m.supplies,old.supplies))
  precondition(m.firstReef.cleared==old.firstReef.cleared && m.firstReef.food==old.firstReef.food && m.firstReef.treasures==old.firstReef.treasures && m.firstReef.visited==old.firstReef.visited && m.firstReef.bonus?.strokes==old.firstReef.bonus?.strokes && m.firstReef.bonus?.bestStrokes==old.firstReef.bonus?.bestStrokes)
  precondition(m.firstReef.bonus?.position==old.firstReef.bonus?.position)
  let again=ReefStore(defaults:defaults,saveDirectory:migratedDir)
  precondition(equal(again.progress,m))
  print("Legacy migration and repeated reload: board, checkpoint, inventory, discoveries, best score, position preserved")

  let fullClearPrice=FirstReef.destinations.flatMap{ReefCove.objects(in:$0.id)}.reduce(0){$0+$1.cost}
  precondition(fullClearPrice==1268)
  precondition(["start","south","food-sand"].map{ReefCove.objects(in:$0).reduce(0){$0+$1.cost}}==[42,52,56])
  print("Course pricing: 1268 Glow for every optional find; required-goal pacing checked by PathGoals; local prices 8–24")
  var fresh=ReefProgress();fresh.glow=2000
  let freshDir=try seed(fresh,"fresh");let store=ReefStore(defaults:defaults,saveDirectory:freshDir)
  precondition(FirstReef.visibleIDs(store.progress.firstReef)==["start"])
  precondition(store.visitFirstReef("south")==nil)
  var visited=Set<String>()
  func explore(_ area:String) {
   visited.insert(area)
   let before=store.progress.firstReef.position
   precondition(!ReefCove.isComplete(area,in:store.progress.firstReef))
   let objects=ReefCove.objects(in:area)
   for (index,object) in objects.enumerated() {
    if object.isGift {precondition((8...12).contains(object.cost) && object.action=="Open")}
    if object.find == .treasure {precondition(object.cost==FirstReef.node(area).glowCost)}
    let balance=store.progress.glow
    let result=store.uncoverCove(object.id)
    precondition(result != nil && store.progress.glow==balance-object.cost && store.progress.firstReef.position==before)
    precondition(ReefCove.isComplete(area,in:store.progress.firstReef)==(index==objects.count-1))
    let snapshot=store.progress
    precondition(store.uncoverCove(object.id)==nil && equal(snapshot,store.progress))
   }
   precondition(ReefCove.isComplete(area,in:store.progress.firstReef))
   for next in FirstReef.neighbors(area,state:store.progress.firstReef) where !visited.contains(next) {
    precondition(store.visitFirstReef(next) != nil);explore(next)
    precondition(store.visitFirstReef(area) != nil)
   }
  }
  explore("start")
  precondition(visited.count==FirstReef.destinations.count)
  precondition(store.progress.firstReef.food.count==3 && store.progress.firstReef.treasures.count==6 && store.progress.firstReef.cleared.count==6 && store.progress.currentChangers==5)
  precondition(store.visitFirstReef("home") != nil && store.progress.firstReef.completed)
  precondition(store.startReefBonus())
  precondition(!store.collectReefBonus())
  let changers=store.progress.currentChangers
  precondition(!store.redirectReefCurrent(0,to:6) && store.progress.currentChangers==changers)
  precondition(store.redirectReefCurrent(0,to:0) && store.progress.currentChangers==changers-1)
  let adjusted=store.progress.firstReef.bonus!.currents!
  precondition(store.startReefBonus(retry:true) && store.progress.firstReef.bonus!.currents==adjusted)
  precondition(store.visitFirstReef("food-middle") != nil && store.startReefBonus())
  let reload=ReefStore(defaults:defaults,saveDirectory:freshDir)
  precondition(reload.progress.firstReef.bonus?.currents==adjusted && reload.progress.currentChangers==changers-1)
  print("All \(visited.count) coves reachable; 104 one-time discoveries including 8 shot chests; 3 foods, 6 chests, 6 permanent clearances, 5 consumable changers; retry/explore/reload persist changes")
  precondition(!ReefCove.isComplete("unknown",in:reload.progress.firstReef))
  for node in FirstReef.destinations {
   precondition(ReefCove.isComplete(node.id,in:reload.progress.firstReef))
   var partial=reload.progress.firstReef
   partial.coveSearches!.remove(ReefCove.objects(in:node.id).last!.id)
   precondition(!ReefCove.isComplete(node.id,in:partial))
   let exits=FirstReef.neighbors(node.id,state:reload.progress.firstReef).map(FirstReef.node)
   for (w,h) in [(340.0,420.0),(390.0,510.0),(480.0,600.0)] {
    for exit in exits {
     let edge=ReefCove.exitEdge(to:exit,from:node.id)
     let back=ReefCove.exitEdge(to:node,from:exit.id)
     precondition(abs(abs(edge.angle-back.angle)-Double.pi)<0.001)
     let p=ReefCove.exitPoint(to:exit,from:node.id,exits:exits,width:w,height:h)
     precondition(p.x>=46 && p.x<=w-46 && p.y>=39 && p.y<=h-39)
     precondition(p.x-46>=104 || p.y-39>=132,"Exit overlaps the mini-map")
     let bearing=ReefCove.exitBearing(to:exit,from:node.id),delta=exit.point-node.point
     precondition(abs(sin(bearing)-delta.x/delta.length)<0.0001)

     for other in exits where other.id != exit.id {
      let q=ReefCove.exitPoint(to:other,from:node.id,exits:exits,width:w,height:h)
      precondition(abs(p.x-q.x)>=92 || abs(p.y-q.y)>=78,"Overlapping exit targets")
     }
    }
   }
  }
  print("All-clear requires every local discovery, survives revisit/reload; gift chests cost 8–12 Glow; all exit targets match their direction and stay separated at phone/Mac sizes")


  var samples=[String:(ReefPoint,FirstReefProgress)]()
  for cleared in [Set<String>(),Set(FirstReef.clearances.map(\.id))] {
   for dirs in [[6,4,6],[0,0,0],[1,1,0]] {
    var state=store.progress.firstReef;state.cleared=cleared;state.bonus=nil;state.bonus=FirstReef.newBonus(state);state.bonus!.currents=dirs
    var wins=0,total=0,first:ReefPoint?
    for angle in stride(from:-150.0,through:-10.0,by:2) {
     for pull in stride(from:50.0,through:110.0,by:2) {
      let drag=ReefPoint(x:cos(angle * .pi/180)*pull,y:sin(angle * .pi/180)*pull)
      let result=FirstReef.putt(drag:drag,from:state)!.outcome;total+=1
      precondition(FirstReef.valid(result))
      if result.bonus!.holed {wins+=1;if first==nil {first=drag}}
     }
    }
    let key="\(cleared.count)-\(dirs)";print("PHYSICS \(key): \(wins)/\(total) hole-in-one launches; first \(String(describing:first))")
    if let first {samples[key]=(first,state)}
    precondition(wins<total/4,"Too automatic")
   }
  }
  guard let sample=samples["6-[0, 0, 0]"] ?? samples["6-[1, 1, 0]"] else {fatalError("No viable full-clear hole in one")}
  var winSave=store.progress;winSave.firstReef=sample.1
  let winDir=try seed(winSave,"win");let winner=ReefStore(defaults:defaults,saveDirectory:winDir)
  let shotBalance=winner.progress.shots
  precondition(winner.puttFirstReef(drag:sample.0)?.outcome.bonus?.holed==true && winner.progress.shots==shotBalance-1)
  let beforeClaim=winner.progress
  precondition(winner.collectReefBonus())
  let claimed=winner.progress;precondition(claimed.firstReef.nextWorldUnlocked==true && claimed.glow==beforeClaim.glow+12)
  precondition(!winner.collectReefBonus() && !winner.startReefBonus(retry:true) && !winner.redirectReefCurrent(0,to:3) && equal(winner.progress,claimed))
  var failureSave=winSave;failureSave.firstReef.bonus!.strokes=6;failureSave.firstReef.bonus!.finished=true;failureSave.firstReef.bonus!.bestStrokes=1
  let failure=ReefStore(defaults:defaults,saveDirectory:try seed(failureSave,"failure"))
  precondition(!failure.collectReefBonus() && failure.startReefBonus(retry:true) && failure.progress.firstReef.bonus?.bestStrokes==1)
  print("Successful round pays once and unlocks; failed retry cannot claim prior best; claim prevents farming")

  let blockedURL=root.appendingPathComponent("not-a-directory");try Data([1]).write(to:blockedURL)
  let blocked=ReefStore(defaults:defaults,saveDirectory:blockedURL)
  let before=blocked.progress
  precondition(!blocked.addDebugSupply(.currents) && equal(before,blocked.progress))
  var noFunds=winSave;noFunds.glow=0;noFunds.currentChangers=0;noFunds.shots=0
  let poor=ReefStore(defaults:defaults,saveDirectory:try seed(noFunds,"poor"))
  precondition(!poor.redirectReefCurrent(0,to:4))
  let poorSnapshot=poor.progress
  precondition(poor.puttFirstReef(drag:sample.0)==nil && equal(poor.progress,poorSnapshot))
  let rollbackDir=try seed(winSave,"rollback")
  let rollback=ReefStore(defaults:defaults,saveDirectory:rollbackDir)
  try FileManager.default.createDirectory(at:rollbackDir.appendingPathComponent("progress-backup.json"),withIntermediateDirectories:false)
  let stable=rollback.progress
  precondition(!rollback.redirectReefCurrent(0,to:4) && equal(stable,rollback.progress))
  precondition(rollback.lastSaveFailed)
  precondition(rollback.puttFirstReef(drag:sample.0)==nil && equal(stable,rollback.progress))
  print("No inventory, duplicate action and failed save never debit resources; paid putt/current rollback verified")

  // A format-16 save gains no resources or tutorials simply by upgrading.
  var v16=winSave;v16.version=16;v16.pendingDiscoveries=[];v16.learnedDiscoveries=[]
  let v16dir=try seed(v16,"version16")
  let v17=ReefStore(defaults:defaults,saveDirectory:v16dir).progress
  precondition(v17.version==20 && equal(v17.firstReef,v16.firstReef) && equal(v17.puzzle,v16.puzzle))
  precondition(v17.shots==v16.shots && v17.pendingDiscoveries.isEmpty && v17.learnedDiscoveries.isEmpty)

  // Zero stock pauses a round; exploration/refills resume its exact ball and score.
  print("Version 16 upgrade preserved state")
  var oneShot=winSave;oneShot.shots=1;oneShot.firstReef.location="home";oneShot.firstReef.position=FirstReef.home;oneShot.firstReef.bonus=FirstReef.newBonus(oneShot.firstReef)
  oneShot.firstReef.coveSearches?.remove("home:4")
  let limitedDir=try seed(oneShot,"limited");let limited=ReefStore(defaults:defaults,saveDirectory:limitedDir)
  let idle=limited.progress
  precondition(limited.puttFirstReef(drag:.init(x:0,y:0))==nil && equal(idle,limited.progress))
  precondition(limited.puttFirstReef(drag:.init(x:-20,y:0)) != nil)
  precondition(limited.progress.shots==0 && limited.progress.firstReef.bonus!.strokes==1 && !limited.progress.firstReef.bonus!.finished)
  let midRound=limited.progress
  precondition(limited.puttFirstReef(drag:sample.0)==nil && equal(limited.progress,midRound))
  let refill=ReefCove.objects(in:"home").first{$0.find == .shot}!
  precondition(limited.uncoverCove(refill.id) != nil && limited.progress.shots==3 && equal(limited.progress.firstReef.bonus,midRound.firstReef.bonus))
  precondition(limited.startReefBonus(retry:true) && limited.progress.shots==3 && limited.progress.firstReef.bonus!.strokes==0)
  for _ in 0..<6 {
   if limited.progress.shots==0 {precondition(limited.addDebugSupply(.shots))}
   precondition(limited.puttFirstReef(drag:.init(x:-20,y:0)) != nil)
  }
  precondition(limited.progress.firstReef.bonus!.strokes==6 && limited.progress.firstReef.bonus!.finished && !limited.progress.firstReef.bonus!.holed)
  let exhausted=limited.progress
  precondition(limited.puttFirstReef(drag:sample.0)==nil && !limited.collectReefBonus() && equal(limited.progress,exhausted))
  precondition(limited.startReefBonus(retry:true) && limited.progress.shots==exhausted.shots)
  print("One token per valid putt; zero-stock resume; six-putt loss; retries never refund stock")

  // First finds survive relaunch and only their successful acknowledgement dismisses them.
  var newPlayer=ReefProgress();newPlayer.glow=10
  let discoveryDir=try seed(newPlayer,"discovery");let discovery=ReefStore(defaults:defaults,saveDirectory:discoveryDir)
  precondition(discovery.uncoverCove("start:4") != nil && discovery.progress.pendingDiscoveries==[.shot])
  let firstReceipt=discovery.discoveryReceipt!
  precondition(firstReceipt.source == .trail && discovery.discoveryItems(for:firstReceipt.id)==[.shot])
  discovery.cancelDiscoveryReceipt()
  precondition(discovery.discoveryItems(for:firstReceipt.id).isEmpty)
  precondition(discovery.uncoverCove("start:4") == nil && discovery.progress.pendingDiscoveries==[.shot])
  let discoveryReload=ReefStore(defaults:defaults,saveDirectory:discoveryDir)
  precondition(discoveryReload.progress.pendingDiscoveries==[.shot] && !discoveryReload.acknowledgeDiscovery(.hint))
  precondition(discoveryReload.discoveryReceipt==nil,"Reload must never schedule old explanations")
  precondition(discoveryReload.acknowledgeDiscovery(.shot) && discoveryReload.progress.learnedDiscoveries.contains(.shot))
  precondition(discoveryReload.uncoverCove("start:4") == nil && discoveryReload.progress.pendingDiscoveries.isEmpty)
  let learned=ReefStore(defaults:defaults,saveDirectory:discoveryDir)
  precondition(learned.progress.learnedDiscoveries.contains(.shot) && learned.progress.pendingDiscoveries.isEmpty)
  let ackDir=try seed(newPlayer,"ack-fail");let ack=ReefStore(defaults:defaults,saveDirectory:ackDir)
  // Use a directory as the backup destination to simulate a write failure, without deleting data.
  var pending=ack.progress;pending.pendingDiscoveries=[.hint]
  let ackFailDir=try seed(pending,"ack-fail-pending");let ackFail=ReefStore(defaults:defaults,saveDirectory:ackFailDir)
  try FileManager.default.createDirectory(at:ackFailDir.appendingPathComponent("progress-backup.json"),withIntermediateDirectories:false)
  let unacked=ackFail.progress
  precondition(!ackFail.acknowledgeDiscovery(.hint) && equal(ackFail.progress,unacked))
  precondition(ackFail.discoveryReceipt==nil)
  var staleSave=newPlayer;staleSave.pendingDiscoveries=[.glow,.life]
  let contextual=ReefStore(defaults:defaults,saveDirectory:try seed(staleSave,"contextual-discovery"))
  precondition(contextual.discoveryReceipt==nil)
  precondition(contextual.uncoverCove("start:4") != nil)
  precondition(contextual.discoveryReceipt!.items==[.shot],"Old pending items must not leak into this pickup")
  precondition(contextual.acknowledgeDiscovery(.shot) && contextual.progress.pendingDiscoveries==[.glow,.life])
  contextual.cancelDiscoveryReceipt()
  precondition(contextual.addDebugSupply(.hints) && contextual.discoveryReceipt==nil)
  precondition(contextual.claimFreeLifeRefill() && contextual.discoveryReceipt==nil)
  var failedFind=newPlayer;failedFind.firstReef.location="start"
  let failedFindDir=try seed(failedFind,"discovery-failed-find")
  let failedFindStore=ReefStore(defaults:defaults,saveDirectory:failedFindDir)
  try FileManager.default.createDirectory(at:failedFindDir.appendingPathComponent("progress-backup.json"),withIntermediateDirectories:false)
  precondition(failedFindStore.uncoverCove("start:4")==nil && failedFindStore.discoveryReceipt==nil)
  var bloomFind=newPlayer;bloomFind.bloomRewardWins=4;bloomFind.puzzle=CoralPuzzle.make(level:5);bloomFind.pendingDiscoveries=[.life]
  let bloomFindDir=try seed(bloomFind,"discovery-bloom-win")
  let bloomFinder=ReefStore(defaults:defaults,saveDirectory:bloomFindDir)
  precondition(bloomFinder.startBloomAttempt())
  for tap in bloomFinder.puzzle.solution()! {bloomFinder.tapCoral(tap)}
  precondition(bloomFinder.isComplete && bloomFinder.discoveryReceipt?.source == .bloom(5))
  precondition([ReefDiscovery.glow,.hint,.shot].allSatisfy{bloomFinder.discoveryReceipt!.items.contains($0)})
  precondition(ReefStore(defaults:defaults,saveDirectory:bloomFindDir).discoveryReceipt==nil)
  print("Discovery receipts match only the current successful pickup; reload, debug/refill and failed saves cannot schedule stale popups; acknowledgements remain atomic")

  var hintBuyerSave=ReefProgress();hintBuyerSave.hints=0;hintBuyerSave.puzzle=CoralPuzzle.make(level:6);hintBuyerSave.puzzle.attemptStarted=true
  let hintBuyerDir=try seed(hintBuyerSave,"hint-buy-and-use")
  let hintBuyer=ReefStore(defaults:defaults,saveDirectory:hintBuyerDir)
  let nextHint=hintBuyer.puzzle.solution()!.first!
  let originalCells=hintBuyer.puzzle.cells,originalMoves=hintBuyer.puzzle.moves
  precondition(hintBuyer.claimFreeHints(source:.purchasePreview))
  precondition(hintBuyer.progress.hints==2 && hintBuyer.puzzle.revealedHint==nextHint && hintBuyer.hint==nextHint)
  precondition(hintBuyer.puzzle.cells==originalCells && hintBuyer.puzzle.moves==originalMoves && hintBuyer.progress.hintRefillHistory.last?.hints==3)
  let purchased=hintBuyer.progress
  precondition(!hintBuyer.claimFreeHints(source:.purchasePreview) && equal(hintBuyer.progress,purchased))
  let hintBuyerReload=ReefStore(defaults:defaults,saveDirectory:hintBuyerDir)
  precondition(hintBuyerReload.progress.hints==2 && hintBuyerReload.puzzle.revealedHint==nextHint && hintBuyerReload.hint==nextHint && hintBuyerReload.discoveryReceipt==nil)
  var alreadyRevealed=hintBuyerSave;alreadyRevealed.puzzle.revealedHint=nextHint
  let existingHint=ReefStore(defaults:defaults,saveDirectory:try seed(alreadyRevealed,"hint-buy-existing-reveal"))
  precondition(existingHint.claimFreeHints(source:.purchasePreview) && existingHint.progress.hints==3 && existingHint.puzzle.revealedHint==nextHint)
  let failedHintDir=try seed(hintBuyerSave,"hint-buy-failed-save")
  let failedHint=ReefStore(defaults:defaults,saveDirectory:failedHintDir);let unbought=failedHint.progress
  try FileManager.default.createDirectory(at:failedHintDir.appendingPathComponent("progress-backup.json"),withIntermediateDirectories:false)
  precondition(!failedHint.claimFreeHints(source:.purchasePreview) && equal(failedHint.progress,unbought) && failedHint.hint==nil)
  print("Buy 3 hints immediately reveals one, leaves 2, preserves moves/cells, persists and rolls back atomically; existing reveals are never charged twice")

  var resetSave=winSave;resetSave.purchaseEntitlements=[.init(transactionID:"test-1",productID:"test.entitlement",purchaseDate:Date())]
  let resetDir=try seed(resetSave,"reset");let reset=ReefStore(defaults:defaults,saveDirectory:resetDir)
  let savedBefore=try Data(contentsOf:resetDir.appendingPathComponent("progress.json"))
  precondition(reset.restartEverything())
  precondition(reset.progress.puzzle.level==1 && reset.progress.firstReef.location=="start" && reset.progress.firstReef.food.isEmpty && reset.progress.firstReef.bonus==nil && reset.progress.completedBloomLevels.isEmpty)
  precondition(equal(reset.progress.purchaseEntitlements,resetSave.purchaseEntitlements) && reset.progress.learnedDiscoveries.isEmpty && reset.progress.pendingDiscoveries.isEmpty)
  let archives=try FileManager.default.contentsOfDirectory(at:resetDir.appendingPathComponent("reset-backups"),includingPropertiesForKeys:nil)
  precondition(archives.count==1)
  let archived=try Data(contentsOf:archives[0].appendingPathComponent("progress.json"))
  precondition(archived==savedBefore)
  let resetReload=ReefStore(defaults:defaults,saveDirectory:resetDir)
  precondition(equal(resetReload.progress,reset.progress))
  let noArchiveDir=try seed(resetSave,"reset-archive-fail");let noArchive=ReefStore(defaults:defaults,saveDirectory:noArchiveDir)
  try Data([1]).write(to:noArchiveDir.appendingPathComponent("reset-backups"))
  let untouched=noArchive.progress
  precondition(!noArchive.restartEverything() && equal(noArchive.progress,untouched))
  let noResetDir=try seed(resetSave,"reset-write-fail");let noReset=ReefStore(defaults:defaults,saveDirectory:noResetDir)
  try FileManager.default.createDirectory(at:noResetDir.appendingPathComponent("progress-backup.json"),withIntermediateDirectories:false)
  let noResetBefore=noReset.progress
  precondition(!noReset.restartEverything() && equal(noReset.progress,noResetBefore))
  print("Debug reset returns to a fresh reef, keeps entitlements, archives exact save and refuses unsafe failures")
 }
}
