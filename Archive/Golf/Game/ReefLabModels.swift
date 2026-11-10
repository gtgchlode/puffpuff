import Foundation
import Observation

// Disposable design experiments. Deliberately no ReefStore, save or purchase access.
enum LabGolfKind: Int, CaseIterable, Identifiable {
    case putt, sling, stop, rhythm, bank, currents, draw, target
    var id:Int { rawValue }
    var name:String { ["Soft putt","Slingshot","Bubble stop","Aim + puff","Bank builder","Current gates","Draw a route","Tap to send"][id] }
    var instruction:String { [
        "Drag from Puff Puff toward your shot. Longer = stronger.",
        "Pull back from Puff Puff, then release like a slingshot.",
        "Tap Go, then tap Stop as he reaches home.",
        "Tap to lock the moving aim, then tap to lock power.",
        "Choose a numbered bank route, then tap Puff.",
        "Turn the three currents to point along the dotted route, then Puff.",
        "Draw a path from Puff Puff. Avoid coral and stay within your ink.",
        "Tap a landing spot. Puff Puff chooses the power; blockers still stop him."
    ][id] }
    var advantage:String { [
        "Each find clears one coral bumper, opening a cleaner shot.",
        "Finds clear bumpers and widen the home entrance.",
        "Finds slow the swim and make the stopping window wider.",
        "Finds slow the aim and power meters, and clear bumpers.",
        "One bank route starts open. Each find opens another route to home.",
        "Each find sets one current correctly, so fewer turns need solving.",
        "Each find removes a coral and gives you more drawing distance.",
        "Each find removes a blocker. With all three, a tap on home sends him straight in."
    ][id] }
}

@Observable final class LabGolf {
    let kind:LabGolfKind
    var finds=0
    var ball=ReefPoint(x:75,y:350)
    let home=ReefPoint(x:225,y:60)
    var shots=0
    var best:Int?=nil
    var won=false
    var collected=false
    var moving=false
    var velocity=ReefPoint(x:0,y:0)
    var clock=0.0
    var progress=0.0
    var phase=0
    var lockedAngle = -Double.pi/2
    var bank=0
    var valves=[2,3,1]
    var route:[ReefPoint]=[]
    var message=""
    var ink:[ReefPoint]=[]
    init(_ kind:LabGolfKind) { self.kind=kind }
    var ended:Bool { won || shots>=4 || collected }
    var blockers:[ReefPoint] { Array([ReefPoint(x:125,y:250),.init(x:195,y:160),.init(x:240,y:100)].dropFirst(finds)) }
    var holeRadius:Double { kind == .sling ? 14+Double(finds)*4 : 17 }
    var angle:Double { -Double.pi/2 + sin(clock*(1.7-Double(finds)*0.28))*0.95 }
    var power:Double { 0.2+0.8*(0.5+0.5*sin(clock*(3.4-Double(finds)*0.55))) }
    var gates:[ReefPoint] { [.init(x:75,y:275),.init(x:225,y:275),.init(x:225,y:145)] }
    var correct:[Int] { [1,0,0] }
    var banks:[ReefPoint] { [.init(x:25,y:210),.init(x:275,y:255),.init(x:25,y:130),.init(x:275,y:175)] }
    var reward:String {
        guard won else { return shots>=4 ? "No bonus · try again" : "Home within 4 shots" }
        let score=best ?? shots
        return score == 1 ? "All bonuses · 12 Glow + hint + lighter" : score == 2 ? "8 Glow + hint" : score == 3 ? "5 Glow" : "2 Glow"
    }
    func reset(keepingBest:Bool=true) {
        ball = .init(x:75,y:350); shots=0;won=false;collected=false;moving=false
        velocity = .init(x:0,y:0);route=[];ink=[];phase=0;progress=0;message=""
        if !keepingBest { best=nil }
        valves=[2,3,1]
        for i in 0..<finds { valves[i]=correct[i] }
    }
    func explore(_ amount:Int) { finds=amount;reset(keepingBest:false) }
    func finish(_ p:ReefPoint) {
        ball=p;moving=false;route=[];phase=0
        won=(p-home).length<=holeRadius
        if won { ball=home;best=min(best ?? 99,shots);message="Home!" }
        else { message=shots>=4 ? "Out of shots" : "Try another shot" }
    }
    func launch(_ vector:ReefPoint) {
        guard !moving,!ended,vector.length>=5 else { return }
        shots += 1; moving=true;message="";ink=[]
        velocity=vector*(1/vector.length)*(100+min(110,vector.length)*2.7)
    }
    func beginRoute(_ points:[ReefPoint]) {
        guard !moving,!ended,points.count>1 else { return }
        shots += 1;moving=true;message="";ball=points[0];route=Array(points.dropFirst())
    }
    func startStop() {
        guard !won,!collected else { return }
        if moving {
            let window=0.035+Double(finds)*0.018
            finish(abs(progress-1)<window ? home:ball)
        } else if !ended { shots += 1;progress=0;ball = .init(x:75,y:350);moving=true;message="" }
    }
    func rhythmTap() {
        guard !moving,!ended else { return }
        if phase == 0 { lockedAngle=angle;phase=1 }
        else { let strength=20+power*90;launch(.init(x:cos(lockedAngle)*strength,y:sin(lockedAngle)*strength));phase=0 }
    }
    func bankPuff() {
        let turn=banks[bank]
        let end=bank<=finds ? home:turn+(home-turn)*0.48
        beginRoute([ball,turn,end])
    }
    func turn(_ gate:Int) { guard !moving,!ended,gate>=finds else { return };valves[gate]=(valves[gate]+1)%4 }
    func currentPuff() {
        var points=[ReefPoint(x:75,y:350)]
        for i in 0..<3 {
            points.append(gates[i])
            if valves[i] != correct[i] {
                let dirs=[ReefPoint(x:0,y:-1),.init(x:1,y:0),.init(x:0,y:1),.init(x:-1,y:0)]
                let p=gates[i]+dirs[valves[i]]*55
                points.append(.init(x:min(275,max(25,p.x)),y:min(375,max(25,p.y))))
                beginRoute(points);return
            }
        }
        points.append(home);beginRoute(points)
    }
    func traced(_ points:[ReefPoint]) {
        guard points.count>1,(points[0]-ball).length<35 else { return }
        var path=[ball],length=0.0
        outer: for end in points.dropFirst() {
            let start=path.last!,delta=end-start
            let steps=max(1,Int(delta.length/3))
            for n in 1...steps {
                let p=start+delta*(Double(n)/Double(steps))
                length += (p-path.last!).length
                if length>420+Double(finds)*60 || p.x<21 || p.x>279 || p.y<21 || p.y>379 { break outer }
                if blockers.contains(where:{($0-p).length<24}) { break outer }
                path.append(p)
                if (p-home).length<holeRadius { path.append(home);break outer }
            }
        }
        ink=[];beginRoute(path)
    }
    func send(to target:ReefPoint) {
        let end=(target-home).length<30 ? home:target
        guard end.x>=21,end.x<=279,end.y>=21,end.y<=379 else { return }
        let delta=end-ball,steps=max(1,Int(delta.length/3));var points=[ball]
        for n in 1...steps {
            let p=ball+delta*(Double(n)/Double(steps))
            if blockers.contains(where:{($0-p).length<24}) { break }
            points.append(p)
        }
        beginRoute(points)
    }
    func tick(_ dt:Double) {
        clock += dt
        guard moving else { return }
        if kind == .stop {
            progress += dt*(0.4-Double(finds)*0.065)
            let t=progress
            ball = .init(x:75+150*min(1,t)+sin(t * .pi)*35,y:350-290*t)
            if progress>1.16 { finish(ball) }
            return
        }
        if !route.isEmpty {
            var distance=dt*260
            while let target=route.first,distance>0 {
                let d=target-ball
                if d.length<=distance { ball=target;distance -= d.length;route.removeFirst() }
                else { ball=ball+d*(distance/d.length);distance=0 }
            }
            if route.isEmpty { finish(ball) }
            return
        }
        for _ in 0..<2 {
            let step=dt/2,previous=ball
            ball=ball+velocity*step
            if ball.x<27 {ball.x=27;velocity.x=abs(velocity.x)*0.88}
            if ball.x>273 {ball.x=273;velocity.x = -abs(velocity.x)*0.88}
            if ball.y<27 {ball.y=27;velocity.y=abs(velocity.y)*0.88}
            if ball.y>373 {ball.y=373;velocity.y = -abs(velocity.y)*0.88}
            for obstacle in blockers {
                let d=ball-obstacle
                if d.length<25 {
                    let normal=d*(1/max(0.01,d.length));ball=obstacle+normal*25
                    if velocity.dot(normal)<0 {velocity=(velocity-normal*(2*velocity.dot(normal)))*0.82}
                }
            }
            let d=ball-previous
            let t=min(1,max(0,(home-previous).dot(d)/max(0.001,d.dot(d))))
            if (home-(previous+d*t)).length<holeRadius && velocity.length<280 {finish(home);return}
            let speed=velocity.length
            velocity=velocity*(max(0,speed-95*step)/max(0.01,speed))
            if velocity.length<4 {finish(ball);return}
        }
    }
}

enum LabPathKind:Int,CaseIterable,Identifiable {
    case coves, fog, side, garden, dive, hub, hunt, current
    var id:Int {rawValue}
    var name:String {["Cove doors","Fog islands","Side swim","Reef garden","Depth dive","Home + spokes","Sonar hunt","Current forks"][id]}
    var instruction:String {[
        "Choose a doorway. Explore branches, clear blockers, and return for missed finds.",
        "Tap a neighboring island to swim there. Unknown islands reveal only on arrival.",
        "Move left or right through three scenes. Tap obstacles to uncover local finds.",
        "Clear connected patches outward from the starting coral. No walking back and forth.",
        "Choose a shelf, then dive deeper. Ascend to explore the shelf you passed.",
        "Visit three regions from home. Each has food and an optional hidden cache.",
        "Scan a hiding place for 1 Glow, then pay to uncover it. Find three snacks and home.",
        "Choose left or right at each fork. One-way currents loop back for missed branches."
    ][id]}
    var idea:String {[
        "The closest to FarmVille quests: personal little scenes with optional side doors.",
        "Exploration is about uncovering geography and finding a route through the fog.",
        "A scrolling storybook: fewer map decisions, more things to uncover in each scene.",
        "Spend Glow to grow your cleared territory. Side patches hide putting advantages.",
        "A vertical expedition: choosing when to go deeper versus searching sideways.",
        "A readable home base. Visit regions in any order, with almost no backtracking.",
        "A search game: spend a little to investigate, then decide whether the find is worth uncovering.",
        "Quick left/right choices. Detours cost another loop, rather than manual backtracking."
    ][id]}
}
struct LabPathNode:Identifiable {
    let id:Int
    let point:ReefPoint
    let food:Int?
    let find:Int?
    let barrier:Int
    let cost:Int
    var isHome:Bool {id == 12}
    var label:String {isHome ? "Home" : ["Kelp","Sand","Fish"][barrier]}
    var action:String {["Part kelp","Sweep sand","Scare fish"][barrier]}
    var reward:String {food != nil ? "Snack found!" : find.map { ["Hint + easier golf","Lives + easier golf","Lighter + easier golf"][$0] } ?? "Passage open"}
}
@Observable final class LabPath {
    let kind:LabPathKind
    var visited:Set<Int>=[0]
    var cleared:Set<Int>=[0]
    var foods:Set<Int>=[]
    var finds:Set<Int>=[]
    var location=0
    var stage=0
    var glow=18
    var loops=0
    var won=false
    var message=""
    init(_ kind:LabPathKind) {self.kind=kind; if kind == .hub {stage = -1}}
    let foodIDs=[2,5,8],findIDs=[3,6,9]
    var nodes:[LabPathNode] {
        let points:[ReefPoint]=[.init(x:150,y:360),.init(x:150,y:310),.init(x:80,y:260),.init(x:245,y:285),.init(x:140,y:220),.init(x:75,y:175),.init(x:245,y:190),.init(x:150,y:135),.init(x:75,y:90),.init(x:245,y:100),.init(x:150,y:65),.init(x:260,y:35),.init(x:150,y:25)]
        return (0..<13).map { id in
            let food=foodIDs.firstIndex(of:id),find=findIDs.firstIndex(of:id)
            return LabPathNode(id:id,point:points[id],food:food,find:find,barrier:(id+kind.id)%3,cost:food != nil ? 2:find != nil ? 4:0)
        }
    }
    var edges:[(Int,Int)] {[(0,1),(1,2),(1,3),(2,4),(4,5),(4,6),(5,7),(7,8),(7,9),(8,10),(10,12),(9,11)]}
    func node(_ id:Int)->LabPathNode {nodes[id]}
    func neighbors(_ id:Int)->[Int] {edges.compactMap {$0.0 == id ? $0.1:$0.1 == id ? $0.0:nil}}
    var current:LabPathNode {node(location)}
    var choices:[Int] {
        if kind == .side || kind == .dive || kind == .hub || kind == .current {
            guard (0..<3).contains(stage) else {return [12]}
            return [foodIDs[stage],findIDs[stage]]
        }
        if kind == .hunt {return [2,3,5,6,8,9,12]}
        if kind == .fog || kind == .garden {return Array(0..<13)}
        return neighbors(location)
    }
    func available(_ id:Int)->Bool {
        if kind == .fog {return id == location || (cleared.contains(location) && neighbors(location).contains(id)) || cleared.contains(id) && neighbors(location).contains(id)}
        if kind == .garden {return cleared.contains(id) || neighbors(id).contains(where:cleared.contains)}
        if kind == .coves {return id == location || neighbors(location).contains(id) && (cleared.contains(location) || visited.contains(id))}
        return choices.contains(id)
    }
    func enter(_ id:Int) {
        guard !won,available(id) else {return}
        let target=node(id)
        if target.isHome {
            if foods.count == 3 {won=true;location=id;message="Home! Your finds help in every golf demo."}
            else {message="Find \(3-foods.count) more snacks."}
            return
        }
        let wasVisited=visited.contains(id)
        if kind == .hunt && !wasVisited {
            guard glow>=1 else {message="Need Glow. Try the Bloom refill.";return}
            glow -= 1
        }
        visited.insert(id);location=id
        if cleared.contains(id) {
            message="Already uncovered"
            if kind == .current {stage=(stage+1)%3;if stage == 0 {loops += 1}}
            if kind == .dive {stage=min(3,stage+1)}
            return
        }
        if target.cost == 0 {cleared.insert(id);message="Passage open";return}
        if !wasVisited && kind != .garden && kind != .current {
            message="\(target.action) · \(target.cost) Glow";return
        }
        guard glow>=target.cost else {message="Need \(target.cost) Glow. Try the Bloom refill.";return}
        glow -= target.cost;cleared.insert(id)
        if let food=target.food {foods.insert(food)}
        if let find=target.find {finds.insert(find)}
        message=target.reward
        if kind == .dive {stage=min(3,stage+1)}
        if kind == .current {stage += 1;if stage == 3 {stage=0;loops += 1}}
    }
    func reset() {visited=[0];cleared=[0];foods=[];finds=[];location=0;stage=kind == .hub ? -1:0;glow=18;won=false;message="";loops=0}
    func returnHome() {if foods.count==3 {won=true;location=12;message="Home! Your finds help in every golf demo."} else {message="Find \(3-foods.count) more snacks."}}
}
