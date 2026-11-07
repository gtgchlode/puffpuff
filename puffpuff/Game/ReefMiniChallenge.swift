import Foundation

enum ReefMiniKind:String,Codable {case kelp,enemy}
enum ReefMiniResult:String,Codable {case playing,won,wall,outOfShots}
struct ReefMiniEnemy:Codable,Equatable,Identifiable {
    let id:Int
    var position:ReefPoint
    var captured=false
}
struct ReefMiniAttempt:Codable,Equatable {
    let kind:ReefMiniKind
    var position:ReefPoint
    var enemies:[ReefMiniEnemy]
    var moves=0
    var layout:Int? = nil
    var timedEnemies:Bool? = nil
    var addedCurrents:[PlacedReefCurrent]? = nil
    var bouncyBlocks:[PlacedBouncyBlock]? = nil
    var shotAllowance:Int? = nil
    var moveLimit:Int {timedEnemies == true ? 1:shotAllowance ?? 4}
    var result=ReefMiniResult.playing
    var finished:Bool {result != .playing}
    static func fresh(_ kind:ReefMiniKind,layout:Int=0,timed:Bool=false)->Self {
        .init(kind:kind,position:kind == .kelp ? ReefMiniChallenge.route(layout)[0]:ReefMiniChallenge.tee(layout),
              enemies:kind == .enemy ? (timed ? (0..<2).map{.init(id:$0,position:ReefMiniChallenge.patrol($0,at:0,layout:layout))}:ReefMiniChallenge.school(layout)):[],
              layout:layout,timedEnemies:timed,shotAllowance:kind == .enemy && !timed ? 8:4)
    }
}
struct ReefMiniFrame {
    let time:Double
    let position:ReefPoint
    let enemies:[ReefMiniEnemy]
    var captureProgress:[Int:Double] = [:]
}
struct ReefMiniFlight:Identifiable {
    let id=UUID()
    let frames:[ReefMiniFrame]
    let outcome:ReefMiniAttempt
    var shellHits:Set<Int> = []
    var launchCharge = 0.0
    var duration:Double {frames.last?.time ?? 0}
    func frame(at time:Double)->ReefMiniFrame {
        let index=frames.lastIndex(where:{$0.time<=time}) ?? 0
        let a=frames[index]
        guard index+1<frames.count else{return a}
        let b=frames[index+1],t=min(1,max(0,(time-a.time)/max(0.001,b.time-a.time)))
        let enemies=a.enemies.map {old->ReefMiniEnemy in
            guard let new=b.enemies.first(where:{$0.id==old.id}) else{return old}
            return .init(id:old.id,position:old.position+(new.position-old.position)*t,captured:old.captured || (new.captured && t>=1))
        }
        let captures=Dictionary(uniqueKeysWithValues:enemies.map {enemy in
            let av=a.captureProgress[enemy.id] ?? (a.enemies.first{$0.id==enemy.id}?.captured == true ? 1:0)
            let bv=b.captureProgress[enemy.id] ?? (b.enemies.first{$0.id==enemy.id}?.captured == true ? 1:0)
            return (enemy.id,av+(bv-av)*t)
        })
        return .init(time:time,position:a.position+(b.position-a.position)*t,enemies:enemies,captureProgress:captures)
    }
}
/// Presentation only: Retry swims the existing fish into the continuing school.
/// The moving destination preserves patrol velocity at the end of the return.
struct ReefMiniReturn:Identifiable {
    let id=UUID()
    let from:ReefMiniFrame
    let duration=0.65
    func frame(toward target:ReefMiniFrame,at time:Double)->ReefMiniFrame {
        let t=min(1,max(0,time/duration)),ease=t*t*(3-2*t)
        let enemies=target.enemies.map {new -> ReefMiniEnemy in
            let old=from.enemies.first{$0.id==new.id} ?? new
            return .init(id:new.id,position:old.position+(new.position-old.position)*ease,captured:new.captured)
        }
        let captures=Dictionary(uniqueKeysWithValues:enemies.map {enemy in
            let old=from.captureProgress[enemy.id] ?? (from.enemies.first{$0.id==enemy.id}?.captured == true ? 1:0)
            let new=target.captureProgress[enemy.id] ?? (enemy.captured ? 1:0)
            return (enemy.id,old+(new-old)*ease)
        })
        return .init(time:time,position:from.position+(target.position-from.position)*ease,enemies:enemies,captureProgress:captures)
    }
}

struct ReefMiniShot {
    let flight:ReefMiniFlight
    let discovery:ReefJourney?
}

/// First-reef introductory challenges. Every launch spends an inventory shot in ReefStore.
enum ReefMiniChallenge {
    static let width=340.0,height=500.0,limit=4
    static let fishRadius=10.0,enemyRadius=16.0
    static let kelpStart=ReefPoint(x:70,y:430),kelpHome=ReefPoint(x:250,y:70)
    static let enemyStart=ReefPoint(x:170,y:435),prison=ReefPoint(x:170,y:58)
    static let kelpRoute=[kelpStart,ReefPoint(x:100,y:330),.init(x:205,y:235),kelpHome]
    static let kelpRadius=60.0,prisonRadius=52.0
    // The stable area/slot gives every first-trail encounter its own gentle layout.
    static func layout(for id:String)->Int {
        let objects=FirstReef.destinations.flatMap{ReefCove.objects(in:$0.id)}
        return (objects.firstIndex{$0.id==id} ?? 0)+1
    }
    static func timedEncounter(_ id:String)->Bool {
        let enemies=FirstReef.destinations.flatMap{ReefCove.objects(in:$0.id)}.filter{$0.challengeKind == .enemy}
        return (enemies.firstIndex{$0.id==id} ?? 0).isMultiple(of:3)
    }
    static func route(_ layout:Int)->[ReefPoint] {
        guard layout>0 else{return kelpRoute}
        let n=Double(layout),mirror=layout.isMultiple(of:2)
        let points=[ReefPoint(x:78+Double(layout%7)*3,y:430),
                    .init(x:111+sin(n*0.7)*17,y:324+Double(layout%5)*4),
                    .init(x:204+cos(n*0.8)*18,y:221+Double(layout%6)*4),
                    .init(x:241+Double(layout%5)*3,y:70)]
        return mirror ? points.map{.init(x:width-$0.x,y:$0.y)}:points
    }
    static func tee(_ layout:Int)->ReefPoint {
        (layout==0 || layout==20) ? enemyStart:.init(x:170+Double((layout*11)%17-8)*2,y:435)
    }
    static func school(_ layout:Int)->[ReefMiniEnemy] {
        guard layout>0 else{return [.init(id:0,position:.init(x:150,y:230)),.init(id:1,position:.init(x:190,y:150))]}
        // Lower fork: keep the first fish near the tee's line for a friendly opening.
        if layout==20 {return [.init(id:0,position:.init(x:170,y:229)),.init(id:1,position:.init(x:170,y:155))]}
        return [.init(id:0,position:.init(x:143+Double((layout*7)%17-8)*2.1,y:235+Double((layout*5)%9-4)*3)),
                .init(id:1,position:.init(x:184+Double((layout*11)%19-9)*1.8,y:155+Double((layout*3)%7-3)*4))]
    }
    // Same endpoints are used by the coral entrance drawing and collision solver.
    static let goalWalls:[(ReefPoint,ReefPoint)] = [
        (.init(x:114,y:106),.init(x:114,y:50)),
        (.init(x:114,y:50),.init(x:132,y:24)),
        (.init(x:132,y:24),.init(x:208,y:24)),
        (.init(x:208,y:24),.init(x:226,y:50)),
        (.init(x:226,y:50),.init(x:226,y:106)),
        (.init(x:114,y:106),.init(x:130,y:106)),
        (.init(x:210,y:106),.init(x:226,y:106))
    ]
    static func goalSeat(_ id:Int)->ReefPoint {.init(x:id==0 ? 150:190,y:57)}
    static func kelpRoom(_ p:ReefPoint,layout:Int=0)->Double {
        var distance=Double.infinity
        for (a,b) in zip(route(layout),route(layout).dropFirst()) {
            let d=b-a,t=min(1,max(0,(p-a).dot(d)/max(0.001,d.dot(d))))
            distance=min(distance,(p-(a+d*t)).length)
        }
        return kelpRadius-distance
    }
    static func canPlace(_ aid:ReefGolfAid,at p:ReefPoint,in state:ReefMiniAttempt)->Bool {
        guard p.x.isFinite,p.y.isFinite else{return false}
        let clearance=aid == .block ? PlacedBouncyBlock.radius+3:18
        if state.kind == .kelp {
            guard kelpRoom(p,layout:state.layout ?? 0)>=clearance,
                  (p-route(state.layout ?? 0).last!).length>=50 else{return false}
        } else {
            guard (18+clearance...width-18-clearance).contains(p.x),
                  (140...height-18-clearance).contains(p.y) else{return false}
            // A still-unstruck school must never patrol through a planted block.
            if aid == .block,state.timedEnemies == true {
                for step in 0..<64 {
                    for i in 0..<2 where (p-patrol(i,at:Double(step)/8,layout:state.layout ?? 0)).length<enemyRadius+clearance {return false}
                }
            }
        }
        return (state.addedCurrents ?? []).allSatisfy{($0.position-p).length>=(aid == .current ? 64:52)}
            && (state.bouncyBlocks ?? []).allSatisfy{($0.position-p).length>=(aid == .current ? 52:44)}
    }
    static func clearOfFish(_ p:ReefPoint,in state:ReefMiniAttempt)->Bool {
        (p-state.position).length>=45 && state.enemies.allSatisfy{($0.position-p).length>=45}
    }
    static func valid(_ state:ReefMiniAttempt)->Bool {
        let currents=state.addedCurrents ?? [],blocks=state.bouncyBlocks ?? []
        guard state.shotAllowance == nil || state.shotAllowance == 4 || (state.kind == .enemy && state.timedEnemies != true && (state.shotAllowance == 6 || state.shotAllowance == 8)) else{return false}
        guard Set(currents.map(\.id)).count==currents.count,Set(blocks.map(\.id)).count==blocks.count else{return false}
        var tested=state;tested.addedCurrents=[];tested.bouncyBlocks=[]
        for current in currents {
            guard (0..<8).contains(current.direction),canPlace(.current,at:current.position,in:tested) else{return false}
            tested.addedCurrents?.append(current)
        }
        for block in blocks {
            guard canPlace(.block,at:block.position,in:tested) else{return false}
            tested.bouncyBlocks?.append(block)
        }
        guard (0...state.moveLimit).contains(state.moves),state.position.x.isFinite,state.position.y.isFinite,
              (-5...width+5).contains(state.position.x),(-5...height+5).contains(state.position.y),
              state.moves>0 || state.result == .playing else{return false}
        switch state.kind {
        case .kelp:
            return state.enemies.isEmpty && (state.result != .won || state.position==route(state.layout ?? 0).last!)
                && (state.result != .outOfShots || state.moves==state.moveLimit)
                && (state.result != .playing || state.moves<state.moveLimit)
        case .enemy:
            return state.enemies.map(\.id)==[0,1] && state.result != .wall
                && state.enemies.allSatisfy{$0.position.x.isFinite && $0.position.y.isFinite && (0...width).contains($0.position.x) && (0...height).contains($0.position.y)}
                && (state.result == .won ? state.enemies.allSatisfy(\.captured):!state.enemies.allSatisfy(\.captured))
                && (state.result != .outOfShots || state.moves==state.moveLimit)
                && (state.result != .playing || state.moves<state.moveLimit)
        }
    }
    static func patrol(_ index:Int,at time:Double,layout:Int=0)->ReefPoint {
        // A gently weaving school: the pair lines up briefly for a friendly timing shot.
        let sway=sin(time * .pi/4+Double(layout%5)*0.3)*16
        let center=170+Double(layout%5-2)*2
        return index==0 ? .init(x:center+sway,y:202+Double(layout%4)*3)
            :.init(x:center-sway*0.30,y:137+Double(layout%3)*3)
    }
    static func restingFrame(_ state:ReefMiniAttempt,patrolTime:Double?=nil)->ReefMiniFrame {
        var enemies=state.enemies
        if state.moves == 0,let patrolTime {
            for i in enemies.indices {enemies[i].position=patrol(i,at:patrolTime,layout:state.layout ?? 0)}
        }
        return .init(time:0,position:state.position,enemies:enemies)
    }
    static func shoot(_ drag:ReefPoint,from state:ReefMiniAttempt,patrolTime:Double?=nil,shells:[ReefPoint]=[])->ReefMiniFlight? {
        guard valid(state),!state.finished,drag.x.isFinite,drag.y.isFinite,drag.length>=6 else{return nil}
        let patrolTime=patrolTime ?? (state.timedEnemies == true ? 0:nil)
        var next=state,p=state.position
        let home=route(state.layout ?? 0).last!
        var velocity=drag*(1/drag.length)*(65+min(1,drag.length/110)*265)
        var enemies=state.enemies,enemyVelocity=Array(repeating:ReefPoint(x:0,y:0),count:enemies.count)
        if let patrolTime {for i in enemies.indices {enemies[i].position=patrol(i,at:patrolTime,layout:state.layout ?? 0)}}
        var struck=Set<Int>(),shellHits=Set<Int>()
        let currents=state.addedCurrents ?? [],blocks=state.bouncyBlocks ?? []
        var puffCurrents=Set<Int>(),fishCurrents=Array(repeating:Set<Int>(),count:state.enemies.count)
        func push(_ p:ReefPoint,_ velocity:inout ReefPoint,_ touched:inout Set<Int>) {
            for i in currents.indices where !touched.contains(i) && (p-currents[i].position).length<BonusCourse.currentRadius {
                velocity=velocity*BonusCourse.currentMomentumRetention+BonusCourse.currentDirection(currents[i].direction)*BonusCourse.currentImpulse
                touched.insert(i)
            }
        }
        var captures:[Int:(start:Double,from:ReefPoint)]=[:]
        for i in enemies.indices where enemies[i].captured && enemies[i].position==prison {
            enemies[i].position=goalSeat(enemies[i].id)
        }
        let dt=1.0/120.0
        var frames=[ReefMiniFrame(time:0,position:p,enemies:enemies)],time=0.0
        func slow(_ v:ReefPoint,_ rate:Double)->ReefPoint {v*(max(0,v.length-rate*dt)/max(0.0001,v.length))}
        func bounce(_ point:inout ReefPoint,_ v:inout ReefPoint,radius:Double) {
            let minX=18+radius,maxX=width-18-radius,minY=20+radius,maxY=height-18-radius
            if point.x<minX {point.x=minX;v.x=abs(v.x)*0.72}
            if point.x>maxX {point.x=maxX;v.x = -abs(v.x)*0.72}
            if point.y<minY {point.y=minY;v.y=abs(v.y)*0.72}
            if point.y>maxY {point.y=maxY;v.y = -abs(v.y)*0.72}
        }
        func goalBounce(_ point:inout ReefPoint,_ v:inout ReefPoint,radius:Double) {
            for (a,b) in goalWalls {
                let segment=b-a,fraction=min(1,max(0,(point-a).dot(segment)/segment.dot(segment)))
                let closest=a+segment*fraction,delta=point-closest,distance=delta.length
                let contact=radius+4
                guard distance<contact else{continue}
                let normal=distance>0.0001 ? delta*(1/distance):ReefPoint(x:0,y:1)
                point=closest+normal*(contact+0.01)
                if v.dot(normal)<0 {v=(v-normal*(2*v.dot(normal)))*0.72}
            }
        }
        func captureValues()->[Int:Double] {
            Dictionary(uniqueKeysWithValues:enemies.filter(\.captured).map {enemy in
                (enemy.id,captures[enemy.id].map{min(1,max(0,(time-$0.start)/0.55))} ?? 1)
            })
        }
        for step in 1...1200 {
            let previous=p;p=p+velocity*dt;time += dt
            ReefGolfPhysics.bounce(&p,velocity:&velocity,radius:fishRadius,off:blocks)
            push(p,&velocity,&puffCurrents)
            if state.kind == .kelp {
                if kelpRoom(p,layout:state.layout ?? 0)<fishRadius {p=previous;next.result = .wall;velocity = .init(x:0,y:0)}
                else if (p-home).length<20 {p=home;next.result = .won;velocity = .init(x:0,y:0)}
            } else {
                bounce(&p,&velocity,radius:fishRadius)
                goalBounce(&p,&velocity,radius:fishRadius)
                for (index,shell) in shells.enumerated() {
                    let delta=p-shell,distance=delta.length,limit=fishRadius+22
                    if distance<limit {
                        let normal=distance>0.001 ? delta*(1/distance):ReefPoint(x:0,y:-1)
                        p=shell+normal*(limit+0.05)
                        if velocity.dot(normal)<0 {velocity=(velocity-normal*(2*velocity.dot(normal)))*0.9;shellHits.insert(index)}
                    }
                }
                for i in enemies.indices where !enemies[i].captured {
                    if let patrolTime,!struck.contains(i) {
                        enemies[i].position=patrol(i,at:patrolTime+time,layout:state.layout ?? 0)
                        enemyVelocity[i] = .init(x:0,y:0)
                    } else {enemies[i].position=enemies[i].position+enemyVelocity[i]*dt}
                    if ReefGolfPhysics.bounce(&enemies[i].position,velocity:&enemyVelocity[i],radius:enemyRadius,off:blocks) {struck.insert(i)}
                    if struck.contains(i) {push(enemies[i].position,&enemyVelocity[i],&fishCurrents[i])}
                    goalBounce(&enemies[i].position,&enemyVelocity[i],radius:enemyRadius)
                    // Once inside the opening, the fish stays caught at any speed.
                    // The entrance walls still resolve contact before this test.
                    if abs(enemies[i].position.x-prison.x)<34,
                       enemies[i].position.y<88 {
                        captures[enemies[i].id]=(time,enemies[i].position)
                        enemies[i].captured=true;enemyVelocity[i] = .init(x:0,y:0)
                        continue
                    }
                    bounce(&enemies[i].position,&enemyVelocity[i],radius:enemyRadius)
                    let delta=enemies[i].position-p,distance=delta.length,limit=fishRadius+enemyRadius
                    if distance<limit {
                        let normal=distance>0.001 ? delta*(1/distance):ReefPoint(x:0,y:-1)
                        let approach=(velocity-enemyVelocity[i]).dot(normal)
                        if approach>0 {
                            // Puff Puff passes most of the push to the small fish.
                            struck.insert(i)
                            let impulse=approach*1.25
                            enemyVelocity[i]=enemyVelocity[i]+normal*impulse
                            velocity=velocity-normal*(impulse*0.72)
                        }
                        let correction=normal*((limit-distance)*0.5+0.01)
                        enemies[i].position=enemies[i].position+correction;p=p-correction
                    }
                    enemyVelocity[i]=slow(enemyVelocity[i],62)
                }
                for i in enemies.indices where !enemies[i].captured {
                    for j in enemies.indices where j>i && !enemies[j].captured {
                        let delta=enemies[j].position-enemies[i].position,d=delta.length
                        if d<enemyRadius*2 {
                            let n=d>0.001 ? delta*(1/d):ReefPoint(x:1,y:0)
                            let approach=(enemyVelocity[i]-enemyVelocity[j]).dot(n)
                            if approach>0 {
                                struck.insert(i);struck.insert(j)
                                let transfer=patrolTime == nil ? 0.85:0.45
                                enemyVelocity[i]=enemyVelocity[i]-n*(approach*transfer)
                                enemyVelocity[j]=enemyVelocity[j]+n*(approach*transfer)
                            }
                            let correction=n*((enemyRadius*2-d)*0.5+0.01)
                            enemies[i].position=enemies[i].position-correction
                            enemies[j].position=enemies[j].position+correction
                        }
                    }
                }
                for i in enemies.indices {
                    guard let capture=captures[enemies[i].id] else{continue}
                    let t=min(1,max(0,(time-capture.start)/0.55)),ease=t*t*(3-2*t)
                    enemies[i].position=capture.from+(goalSeat(enemies[i].id)-capture.from)*ease
                }
                if enemies.allSatisfy(\.captured),captureValues().values.allSatisfy({$0>=1}) {next.result = .won}
            }
            velocity=slow(velocity,state.kind == .kelp ? 115:95)
            let stopped=velocity.length<2 && enemyVelocity.allSatisfy{$0.length<2}
                && captureValues().values.allSatisfy{$0>=1}
            if step.isMultiple(of:4) || stopped || next.finished {frames.append(.init(time:time,position:p,enemies:enemies,captureProgress:captureValues()))}
            if stopped || next.finished {break}
        }
        next.position=p;next.enemies=enemies;next.moves += 1
        if next.result == .playing && next.moves==state.moveLimit {next.result = .outOfShots}
        frames.append(.init(time:time+0.01,position:p,enemies:enemies,captureProgress:captureValues()))
        return .init(frames:frames,outcome:next,shellHits:shellHits,launchCharge:min(1,drag.length/110))
    }
}
