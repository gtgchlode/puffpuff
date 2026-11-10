import Foundation
@main struct MiniChecks {
 @MainActor static func main() throws {
  setbuf(stdout,nil)
  let root=URL(fileURLWithPath:CommandLine.arguments[1]);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
  let defaults=UserDefaults(suiteName:"puffpuff-mini-checks-\(UUID())")!
  func fixture(_ p:ReefProgress,_ name:String)throws->ReefStore {
   let directory=root.appendingPathComponent(name);try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
   try JSONEncoder().encode(p).write(to:directory.appendingPathComponent("progress.json"))
   return ReefStore(defaults:defaults,saveDirectory:directory)
  }
  let objects=FirstReef.destinations.flatMap{ReefCove.objects(in:$0.id)}
  let kelp=objects.first{$0.challengeKind == .kelp && $0.clearingReward != nil}!
  let enemy=objects.first{$0.challengeKind == .enemy && !ReefMiniChallenge.timedEncounter($0.id)}!
  func seed(_ object:ReefCove.Object)->ReefProgress {
   var p=ReefProgress();p.shots=10;p.glow=1000
   p.firstReef.location=object.area;p.firstReef.position=FirstReef.node(object.area).point;p.firstReef.visited=["start",object.area]
   return p
  }
  let store=try fixture(seed(kelp),"kelp")
  precondition(store.beginCoveChallenge(kelp.id));precondition(store.progress.shots==10)
  precondition(store.shootCoveChallenge(kelp.id,drag:.init(x:1,y:1))==nil && store.progress.shots==10)
  let bad=store.shootCoveChallenge(kelp.id,drag:.init(x:-110,y:0))!
  precondition(bad.flight.outcome.result == .wall && store.progress.shots==9)
  precondition(store.shootCoveChallenge(kelp.id,drag:.init(x:40,y:-90))==nil)
  precondition(store.beginCoveChallenge(kelp.id,retry:true) && store.progress.shots==9)
  let reload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("kelp"))
  precondition(reload.progress.firstReef.miniChallenges?[kelp.id]?.moves==0 && reload.progress.shots==9)
  var last:ReefMiniShot?
  for target in ReefMiniChallenge.route(reload.progress.firstReef.miniChallenges![kelp.id]!.layout ?? 0).dropFirst() {
   let state=reload.progress.firstReef.miniChallenges![kelp.id]!,delta=target-state.position
   let power=(sqrt(2*115*delta.length)-65)/265*110
   last=reload.shootCoveChallenge(kelp.id,drag:delta*(power/delta.length));precondition(last != nil)
  }
  precondition(last?.flight.outcome.result == .won && last?.discovery != nil)
  precondition(reload.progress.glow==1000 && reload.progress.firstReef.coveSearches!.contains(kelp.id))
  let saved=try JSONEncoder().encode(reload.progress)
  precondition(!reload.beginCoveChallenge(kelp.id,retry:true) && reload.uncoverCove(kelp.id)==nil)
  let wonReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("kelp"))
  precondition(wonReload.progress.firstReef.miniChallenges?[kelp.id]?.result == .won)
  let savedObject=try JSONSerialization.jsonObject(with:saved) as! NSDictionary
  let reloadedObject=try JSONSerialization.jsonObject(with:JSONEncoder().encode(wonReload.progress)) as! NSDictionary
  precondition(savedObject==reloadedObject)
  let one=ReefMiniChallenge.shoot(.init(x:39.860191,y:-89.527455),from:.fresh(.kelp))!
  precondition(one.outcome.result == .won)
  var short=ReefMiniAttempt.fresh(.kelp)
  for i in 1...4 {short=ReefMiniChallenge.shoot(.init(x:0,y:-6),from:short)!.outcome;precondition(short.moves==i)}
  precondition(short.result == .outOfShots)
  print("Kelp: 3-shot route, tighter hole-in-one, wall loss, 4-shot limit, retry and relaunch; clear/reward once")
  let bowling=try fixture(seed(enemy),"enemy");precondition(bowling.beginCoveChallenge(enemy.id))
  for d in [ReefPoint(x:-10.487446648177832,y:-109.49891991614174),.init(x:-11.450798898713723,y:-99.34223273402513)] {precondition(bowling.shootCoveChallenge(enemy.id,drag:d) != nil)}
  precondition(bowling.progress.firstReef.miniChallenges?[enemy.id]?.result == .won && bowling.progress.shots==8)
  let bypass=try fixture(seed(kelp),"bypass");precondition(bypass.beginCoveChallenge(kelp.id));precondition(bypass.uncoverCove(kelp.id) != nil)
  precondition(bypass.progress.glow==1000-kelp.baseCost*4 && bypass.shootCoveChallenge(kelp.id,drag:.init(x:40,y:-90))==nil)
  var zero=seed(kelp);zero.shots=0;zero.glow=0
  let empty=try fixture(zero,"zero");precondition(empty.beginCoveChallenge(kelp.id))
  precondition(empty.shootCoveChallenge(kelp.id,drag:.init(x:40,y:-90))==nil && empty.uncoverCove(kelp.id)==nil)
  var failSeed=seed(kelp);failSeed.firstReef.miniChallenges=[kelp.id:.fresh(.kelp)]
  let fail=try fixture(failSeed,"failure"),block=root.appendingPathComponent("failure/progress-backup.json")
  try FileManager.default.createDirectory(at:block,withIntermediateDirectories:false)
  precondition(fail.shootCoveChallenge(kelp.id,drag:.init(x:39.860191,y:-89.527455))==nil && fail.lastSaveFailed)
  precondition(fail.progress.shots==10 && fail.progress.glow==1000 && fail.progress.firstReef.miniChallenges?[kelp.id]?.moves==0)
  precondition(!(fail.progress.firstReef.coveSearches ?? []).contains(kelp.id))
  try FileManager.default.moveItem(at:block,to:root.appendingPathComponent("failure/retained-blocker"))
  precondition(fail.shootCoveChallenge(kelp.id,drag:.init(x:39.860191,y:-89.527455))?.discovery != nil)
  var old=seed(kelp);old.version=22
  let migrated=try fixture(old,"migration")
  precondition(migrated.progress.version==28 && migrated.progress.shots==old.shots && migrated.progress.glow==old.glow && migrated.progress.firstReef.miniChallenges==nil)
  print("Production: one shot per launch, free entry/retry, 4× Glow alternative, zero-resource guards, atomic save rollback, v22 migration")
  let timed=ReefMiniChallenge.shoot(.init(x:2.966457219712592,y:-84.94822029662313),from:.fresh(.enemy,layout:3,timed:true),patrolTime:0)!
  precondition(timed.outcome.result == .won && timed.outcome.moves==1)
  precondition(timed.frames.contains{$0.captureProgress.values.contains{$0>0 && $0<1}})
  for (a,b) in zip(timed.frames,timed.frames.dropFirst()) {
   for (old,new) in zip(a.enemies,b.enemies) {
    precondition((new.position-old.position).length<20,"Capture must never teleport")
   }
  }
  let miss=ReefMiniChallenge.shoot(.init(x:110,y:0),from:.fresh(.enemy,layout:3,timed:true),patrolTime:0)!
  precondition(miss.outcome.result == .outOfShots && miss.outcome.moves==1)
  // A fast fish crossing into the entrance stays captured, with a smooth entry.
  var fast=ReefMiniAttempt.fresh(.enemy)
  fast.position = .init(x:170,y:146)
  fast.enemies=[.init(id:0,position:.init(x:170,y:104)),.init(id:1,position:ReefMiniChallenge.goalSeat(1),captured:true)]
  let fastFlight=ReefMiniChallenge.shoot(.init(x:0,y:-110),from:fast)!
  precondition(fastFlight.outcome.result == .won)
  let caught=fastFlight.frames.firstIndex{$0.enemies[0].captured}!
  precondition(fastFlight.frames[caught].time<0.3)
  precondition(fastFlight.frames.dropFirst(caught).allSatisfy{$0.enemies[0].captured && $0.enemies[1].captured})
  precondition(fastFlight.outcome.enemies[0].position == ReefMiniChallenge.goalSeat(0))
  var extra=ReefMiniAttempt.fresh(.enemy)
  for i in 1...8 {
   extra=ReefMiniChallenge.shoot(.init(x:6,y:0),from:extra)!.outcome
   precondition(extra.moves==i && extra.result == (i==8 ? .outOfShots:.playing))
  }
  var oldMiss=seed(enemy),oldEnemy=ReefMiniAttempt.fresh(.enemy)
  oldMiss.version=25;oldEnemy.shotAllowance=nil;oldEnemy.moves=4;oldEnemy.result = .outOfShots
  oldMiss.firstReef.miniChallenges=[enemy.id:oldEnemy]
  let resumed=try fixture(oldMiss,"eight-shot-migration")
  let resumedAttempt=resumed.progress.firstReef.miniChallenges![enemy.id]!
  precondition(resumedAttempt.moveLimit==8 && resumedAttempt.moves==4 && resumedAttempt.result == .playing)
  precondition(resumedAttempt.position==oldEnemy.position && resumedAttempt.enemies==oldEnemy.enemies && resumed.progress.shots==oldMiss.shots)
  print("Enemy: eight-shot budget; old four-shot misses keep their state and gain four tries; fast entries never bounce out")
  let oldAttempt=Data("{\"kind\":\"kelp\",\"position\":{\"x\":70,\"y\":430},\"enemies\":[],\"moves\":0,\"result\":\"playing\"}".utf8)
  let decoded=try JSONDecoder().decode(ReefMiniAttempt.self,from:oldAttempt)
  precondition(decoded.layout==nil && decoded.timedEnemies==nil && ReefMiniChallenge.valid(decoded))
  print("Timing: one-shot limit, continuous capture frames, and older attempts retained")
  let solutionsURL=URL(fileURLWithPath:CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("MiniLayoutSolutions.json")
  let solutions=try JSONDecoder().decode([String:[[Double]]].self,from:Data(contentsOf:solutionsURL))
  var fingerprints=Set<String>(),kelpCount=0,enemyCount=0,timedCount=0
  for object in objects {
   guard let kind=object.challengeKind else{continue}
   let layout=ReefMiniChallenge.layout(for:object.id),timing=kind == .enemy && ReefMiniChallenge.timedEncounter(object.id)
   var attempt=ReefMiniAttempt.fresh(kind,layout:layout,timed:timing)
   let geometry=kind == .kelp ? ReefMiniChallenge.route(layout):[attempt.position]+attempt.enemies.map(\.position)
   let fingerprint=geometry.map{"\($0.x),\($0.y)"}.joined(separator:";")
   precondition(fingerprints.insert(fingerprint).inserted,"Every encounter should differ")
   if kind == .kelp {
    kelpCount+=1
    for target in ReefMiniChallenge.route(layout).dropFirst() {
     let delta=target-attempt.position,power=(sqrt(2*115*delta.length)-65)/265*110
     attempt=ReefMiniChallenge.shoot(delta*(power/delta.length),from:attempt)!.outcome
    }
   } else {
    enemyCount+=1;if timing {timedCount+=1}
    guard let shots=solutions[object.id] else{fatalError("Missing solution: \(object.id)")}
    for d in shots {
     let flight=ReefMiniChallenge.shoot(.init(x:d[0],y:d[1]),from:attempt,patrolTime:d.count>2 ? d[2]:nil)!
     precondition(ReefMiniChallenge.valid(flight.outcome))
     attempt=flight.outcome
    }
   }
   precondition(attempt.result == .won && attempt.moves<=3,"Keep Trail One easy: \(object.id)")
  }
  precondition(kelpCount==25 && enemyCount==32 && timedCount==11)
  var arranged=ReefMiniAttempt.fresh(.enemy),banked=false
  for d in [ReefPoint(x:-96.59258262890683,y:-25.881904510252102),
            .init(x:-25,y:-43.30127018922194),.init(x:42.42640687119285,y:-42.426406871192846)] {
   let flight=ReefMiniChallenge.shoot(d,from:arranged,shells:[.init(x:220,y:350),.init(x:275,y:200)])!
   banked = banked || !flight.shellHits.isEmpty;arranged=flight.outcome
  }
  precondition(arranged.result == .won && banked)

  // Rendering and launch receive the same arena phase, including the ocean loop seam.
  let timingObjects=objects.filter{$0.challengeKind == .enemy && ReefMiniChallenge.timedEncounter($0.id)}
  for object in timingObjects {
   let fresh=ReefMiniAttempt.fresh(.enemy,layout:ReefMiniChallenge.layout(for:object.id),timed:true)
   for phase in [0.0,1.3,3.9,7.999,8,47.999,48] {
    let visible=ReefMiniChallenge.restingFrame(fresh,patrolTime:phase)
    let shot=ReefMiniChallenge.shoot(.init(x:0,y:-100),from:fresh,patrolTime:phase)!
    precondition(shot.frames.first!.enemies==visible.enemies,"Release jumped away from the visible school")
    let returning=ReefMiniReturn(from:shot.frames.last!)
    var prior=returning.frame(toward:visible,at:0)
    precondition(prior.position==shot.outcome.position && prior.enemies.map(\.position)==shot.outcome.enemies.map(\.position))
    for step in 1...120 {
     let time=returning.duration*Double(step)/120
     let target=ReefMiniChallenge.restingFrame(fresh,patrolTime:phase+time)
     let next=returning.frame(toward:target,at:time)
     precondition((next.position-prior.position).length<10)
     for (a,b) in zip(prior.enemies,next.enemies) {precondition((b.position-a.position).length<10)}
     if step==120 {precondition(next.position==target.position && next.enemies==target.enemies)}
     prior=next
    }
   }
   for i in 0..<2 {
    precondition((ReefMiniChallenge.patrol(i,at:48,layout:fresh.layout!)-ReefMiniChallenge.patrol(i,at:0,layout:fresh.layout!)).length<0.000001)
   }
  }
  print("Timing: all 11 schools launch from their visible phase; continuous Retry joins the live patrol without position or loop jumps")

  let timedObject=timingObjects[0]
  let grid=stride(from:45.0,through:295,by:10).flatMap{x in stride(from:150.0,through:430,by:10).map{ReefPoint(x:x,y:$0)}}
  for (index,object) in [kelp,enemy,timedObject].enumerated() {
   var p=seed(object);p.currentAdders=2;p.bouncyBlocks=2
   let name="aids-\(index)",aids=try fixture(p,name)
   precondition(aids.beginCoveChallenge(object.id))
   let state=aids.progress.firstReef.miniChallenges![object.id]!
   let current=grid.first{ReefMiniChallenge.canPlace(.current,at:$0,in:state) && ReefMiniChallenge.clearOfFish($0,in:state)}!
   precondition(!aids.addCoveAid(.current,to:object.id,at:current,direction:8) && aids.progress.currentAdders==2)
   precondition(!aids.addCoveAid(.block,to:object.id,at:.init(x:.nan,y:0)) && aids.progress.bouncyBlocks==2)
   precondition(aids.addCoveAid(.current,to:object.id,at:current,direction:0))
   precondition(!aids.addCoveAid(.current,to:object.id,at:current,direction:0))
   let updated=aids.progress.firstReef.miniChallenges![object.id]!
   let block=grid.first{ReefMiniChallenge.canPlace(.block,at:$0,in:updated) && ReefMiniChallenge.clearOfFish($0,in:updated)}!
   precondition(aids.addCoveAid(.block,to:object.id,at:block))
   precondition(aids.progress.currentAdders==1 && aids.progress.bouncyBlocks==1 && aids.progress.shots==p.shots)
   let reload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent(name))
   precondition(!reload.isSaveBlocked && reload.progress.firstReef.miniChallenges![object.id]==aids.progress.firstReef.miniChallenges![object.id])
   let before=reload.progress.firstReef.miniChallenges![object.id]!
   precondition(ReefMiniChallenge.valid(before))
   precondition(reload.shootCoveChallenge(object.id,drag:.init(x:110,y:0),patrolTime:2) != nil)
   precondition(!reload.lastSaveFailed && reload.progress.shots==p.shots-1)
   precondition(reload.beginCoveChallenge(object.id,retry:true))
   let retry=reload.progress.firstReef.miniChallenges![object.id]!
   precondition(retry.addedCurrents==nil && retry.bouncyBlocks==nil && reload.progress.currentAdders==1 && reload.progress.bouncyBlocks==1)
  }
  print("Aids: kelp, timed and multi-shot challenges persist placements, charge once, reject invalid/duplicate placement, keep shot costs and clear on Retry without refund")

  var rollbackSeed=seed(kelp);rollbackSeed.bouncyBlocks=1;rollbackSeed.currentAdders=1
  let rollback=try fixture(rollbackSeed,"aid-save-failure")
  precondition(rollback.beginCoveChallenge(kelp.id))
  let state=rollback.progress.firstReef.miniChallenges![kelp.id]!
  let backupURL=root.appendingPathComponent("aid-save-failure/progress-backup.json")
  try FileManager.default.moveItem(at:backupURL,to:root.appendingPathComponent("aid-save-failure/retained-backup.json"))
  try FileManager.default.createDirectory(at:backupURL,withIntermediateDirectories:false)
  for aid in ReefGolfAid.allCases {
   let point=grid.first{ReefMiniChallenge.canPlace(aid,at:$0,in:state) && ReefMiniChallenge.clearOfFish($0,in:state)}!
   precondition(!rollback.addCoveAid(aid,to:kelp.id,at:point))
   precondition(rollback.progress.bouncyBlocks==1 && rollback.progress.currentAdders==1 && rollback.progress.firstReef.miniChallenges![kelp.id]==state)
  }
  var legacy=seed(enemy);legacy.version=23
  let legacyStore=try fixture(legacy,"v23-aids")
  precondition(legacyStore.progress.version==28 && legacyStore.progress.bouncyBlocks==0 && legacyStore.progress.shots==legacy.shots)

  // A current changes trajectory; the same cushion reflects a fish and Puff Puff.
  let plain=ReefMiniAttempt.fresh(.kelp)
  var flowing=plain;flowing.addedCurrents=[.init(position:.init(x:90,y:365),direction:2)]
  precondition(ReefMiniChallenge.valid(flowing))
  let drag=ReefPoint(x:30,y:-100)
  let baseline=ReefMiniChallenge.shoot(drag,from:plain)!,boosted=ReefMiniChallenge.shoot(drag,from:flowing)!
  precondition((baseline.outcome.position-boosted.outcome.position).length>10)
  for radius in [ReefMiniChallenge.fishRadius,ReefMiniChallenge.enemyRadius,BonusCourse.ballRadius] {
   var point=ReefPoint(x:100,y:120),v=ReefPoint(x:0,y:-100)
   precondition(ReefGolfPhysics.bounce(&point,velocity:&v,radius:radius,off:[.init(position:.init(x:100,y:100))]))
   precondition(v.y>0 && abs(v.length-96)<0.001)
  }
  let blockFinds=objects.filter{$0.clearingReward == .bouncyBlock}
  precondition(blockFinds.count==4)
  for object in blockFinds {
   let found=try fixture(seed(object),"block-find-\(object.id)")
   precondition(found.uncoverCove(object.id) != nil && found.progress.bouncyBlocks==1)
   precondition(found.uncoverCove(object.id)==nil && found.progress.bouncyBlocks==1)
  }
  let dropCount=(1...10000).filter{ReefStore.hasBouncyBlock(seed:42,win:$0)}.count
  precondition((400...600).contains(dropCount))
  var bloom=ReefProgress()
  bloom.lifeGiftSeed=(1...10000).map(UInt64.init).first{ReefStore.hasBouncyBlock(seed:$0,win:1)}!
  let reward=try fixture(bloom,"bloom-block")
  precondition(reward.startBloomAttempt())
  for tap in reward.puzzle.solution()! {reward.tapCoral(tap)}
  precondition(reward.isComplete && reward.puzzle.earnedBouncyBlock==true && reward.progress.bouncyBlocks==1)
  let rewardReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("bloom-block"))
  precondition(rewardReload.puzzle.earnedBouncyBlock==true && rewardReload.progress.bouncyBlocks==1)
  rewardReload.tapCoral(0);precondition(rewardReload.progress.bouncyBlocks==1)
  print("Blocks: \(dropCount)/10,000 Bloom rolls; four one-time Trail finds; reward reload/no-duplication and v23 migration; failed placement saves preserve both inventories")


  var golf=ReefProgress();golf.bouncyBlocks=2;golf.currentAdders=2;golf.shots=10
  golf.firstReef.location="home";golf.firstReef.position=FirstReef.home
  golf.firstReef.visited=Set(FirstReef.destinations.map(\.id));golf.firstReef.food=Set(FirstReef.food.map(\.id))
  golf.firstReef.completed=true;golf.firstReef.coveSearches=ReefCove.allIDs
  golf.firstReef.cleared=Set(FirstReef.clearances.map(\.id));golf.firstReef.bonus=FirstReef.newBonus(golf.firstReef)
  let finalGolf=try fixture(golf,"bonus-block")
  let point=grid.first{BonusCourse.canPlaceBlock(at:$0,in:golf.firstReef) && ($0-golf.firstReef.bonus!.position).length>=45}!
  precondition(!finalGolf.addReefBlock(at:BonusCourse.home) && finalGolf.progress.bouncyBlocks==2)
  precondition(finalGolf.addReefBlock(at:point) && finalGolf.progress.bouncyBlocks==1)
  precondition(!finalGolf.addReefBlock(at:point) && finalGolf.progress.bouncyBlocks==1)
  let current=grid.first{BonusCourse.canPlaceCurrent(at:$0,in:finalGolf.progress.firstReef)}!
  precondition(finalGolf.addReefCurrent(at:current,direction:0))
  let golfReload=ReefStore(defaults:defaults,saveDirectory:root.appendingPathComponent("bonus-block"))
  precondition(!golfReload.isSaveBlocked && golfReload.progress.firstReef.bonus?.bouncyBlocks?.count==1 && golfReload.progress.bouncyBlocks==1)
  precondition(golfReload.puttFirstReef(drag:.init(x:90,y:-50)) != nil && !golfReload.lastSaveFailed)
  precondition(golfReload.startReefBonus(retry:true))
  precondition(golfReload.progress.firstReef.bonus?.bouncyBlocks==nil && golfReload.progress.firstReef.bonus?.addedCurrents==nil)
  precondition(golfReload.progress.bouncyBlocks==1 && golfReload.progress.currentAdders==1)
  print("Final golf: blocks/currents coexist, persist through putting/relaunch and disappear on Retry without inventory refunds")
  print("25 distinct kelp layouts; 21 multiple-shot and 11 timing enemy layouts; all win in 1–3 shots. Shell setup retained and solvable.")

 }
}
