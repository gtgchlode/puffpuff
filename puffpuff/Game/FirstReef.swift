import Foundation

/// A compact mini-golf fairway, independent of the quest's branching map.
/// Clearance IDs are the only link: paying in the quest removes the same obstacle here.
enum BonusCourse {
    static let revision = 4
    static let width = 340.0, height = 570.0
    static let tee = ReefPoint(x:80,y:520)
    static let home = ReefPoint(x:260,y:80)
    static let fairway = [tee,.init(x:270,y:420),.init(x:70,y:310),.init(x:270,y:200),home]
    static let laneRadius = 52.0, ballRadius = 7.0, holeRadius = 15.0
    static let currents:[ReefPoint] = [.init(x:220,y:393),.init(x:150,y:266),.init(x:265,y:150)]
    static let currentRadius = 32.0, currentMomentumRetention = 0.72, currentImpulse = 135.0
    static let legacyTee = ReefPoint(x:80,y:490), legacyHome = ReefPoint(x:260,y:100)
    private static let previousCurrents = [6,4,6]
    static let defaultCurrents = [6,1,0]
    static func initialCurrents(_ state:FirstReefProgress)->[Int] {
        guard let bonus=state.bonus,let currents=bonus.currents else {return defaultCurrents}
        // Carry a prior player's custom directions forward, but adapt the old defaults to the new bends.
        if (bonus.courseRevision ?? 2) < revision && currents == previousCurrents {return defaultCurrents}
        return currents
    }
    static func activeCurrents(_ state:FirstReefProgress)->[(position:ReefPoint,direction:Int)] {
        let directions=initialCurrents(state)
        return currents.enumerated().map{($0.element,directions[$0.offset])}
            + (state.bonus?.addedCurrents ?? []).map{($0.position,$0.direction)}
    }
    static func canPlaceCurrent(at point:ReefPoint,in state:FirstReefProgress)->Bool {
        guard point.x.isFinite,point.y.isFinite,
              nearestWater(point,cleared:state.cleared).clearance>=18,
              (point-home).length>=48,
              (state.bonus?.bouncyBlocks ?? []).allSatisfy({($0.position-point).length>=52}),
              activeCurrents(state).allSatisfy({($0.position-point).length>=64}),
              bumpers.filter({!state.cleared.contains($0.clearance ?? "")}).allSatisfy({($0.point-point).length>=$0.radius+18}) else{return false}
        return true
    }
    static func canPlaceBlock(at point:ReefPoint,in state:FirstReefProgress)->Bool {
        point.x.isFinite && point.y.isFinite
            && nearestWater(point,cleared:state.cleared).clearance>=PlacedBouncyBlock.radius+2
            && (point-home).length>=50
            && activeCurrents(state).allSatisfy{($0.position-point).length>=52}
            && (state.bonus?.bouncyBlocks ?? []).allSatisfy{($0.position-point).length>=44}
            && bumpers.filter{!state.cleared.contains($0.clearance ?? "")}.allSatisfy{($0.point-point).length>=$0.radius+PlacedBouncyBlock.radius+3}
    }
    static func currentDirection(_ direction:Int)->ReefPoint {
        let angle = -Double.pi/2+Double(direction)*Double.pi/4
        return .init(x:cos(angle),y:sin(angle))
    }
    static let bumpers: [ReefBumper] = [
        .init(id:"sand",point:.init(x:160,y:478),radius:12,kind:.sand,clearance:"sand"),
        .init(id:"kelp",point:.init(x:220,y:446),radius:12,kind:.kelp,clearance:"kelp"),
        .init(id:"enemy",point:.init(x:175,y:368),radius:12,kind:.enemy,clearance:"enemy"),
        .init(id:"ribbon-kelp",point:.init(x:210,y:233),radius:16,kind:.kelp,clearance:"ribbon-kelp"),
        .init(id:"shell-sand",point:.init(x:105,y:291),radius:15,kind:.sand,clearance:"shell-sand"),
        .init(id:"fin-school",point:.init(x:230,y:110),radius:13,kind:.enemy,clearance:"fin-school")
    ]
    static func nearestWater(_ p:ReefPoint,cleared:Set<String>) -> (center:ReefPoint,radius:Double,clearance:Double) {
        var result=(center:tee,radius:laneRadius,clearance:-Double.infinity)
        for (start,end) in zip(fairway,fairway.dropFirst()) {
            let d=end-start
            let t=min(1,max(0,(p-start).dot(d)/max(0.001,d.dot(d))))
            let q=start+d*t
            let clearance=laneRadius-(p-q).length
            if clearance>result.clearance {result=(q,laneRadius,clearance)}
        }
        if cleared.contains("fin-school") {
            let room=72-(p-home).length
            if room>result.clearance { result=(home,72,room) }
        }
        return result
    }
    static func legacyNearestWater(_ p:ReefPoint,cleared:Set<String>) -> (center:ReefPoint,radius:Double,clearance:Double) {
        let d=legacyHome-legacyTee
        let t=min(1,max(0,(p-legacyTee).dot(d)/max(0.001,d.dot(d))))
        let q=legacyTee+d*t
        let radius=64.0
        var result=(center:q,radius:radius,clearance:radius-(p-q).length)
        if cleared.contains("fin-school") {
            let room=72-(p-legacyHome).length
            if room>result.clearance {result=(legacyHome,72,room)}
        }
        return result
    }
    static func safePosition(_ p:ReefPoint,cleared:Set<String>) -> ReefPoint {
        var result=p
        for _ in 0..<8 {
            let shore=nearestWater(result,cleared:cleared),delta=result-shore.center
            if shore.clearance<ballRadius {
                result=shore.center+delta*((shore.radius-ballRadius-0.2)/max(0.001,delta.length))
            }
            for b in bumpers where !cleared.contains(b.clearance ?? "") {
                let delta=result-b.point,limit=ballRadius+b.radius+0.2
                if delta.length<limit {
                    let normal=delta.length>0.001 ? delta*(1/delta.length) : ReefPoint(x:-1,y:0)
                    result=b.point+normal*limit
                }
            }
        }
        return result
    }
}

struct ReefPoint: Codable, Equatable {
    var x: Double
    var y: Double
    static func + (a: Self, b: Self) -> Self { .init(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Self, b: Self) -> Self { .init(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: Self, b: Double) -> Self { .init(x: a.x * b, y: a.y * b) }
    var length: Double { hypot(x, y) }
    func dot(_ other: Self) -> Double { x * other.x + y * other.y }
}

struct PlacedReefCurrent:Codable,Identifiable,Equatable {
    var id=UUID()
    let position:ReefPoint
    let direction:Int
}

enum ReefGolfAid:String,CaseIterable,Identifiable {
    case current,block
    var id:String {rawValue}
}
struct PlacedBouncyBlock:Codable,Identifiable,Equatable {
    var id=UUID()
    let position:ReefPoint
    static let radius=19.0
}
enum ReefGolfPhysics {
    /// Shared by the final course and every mini challenge, for fish and PuffPuff.
    @discardableResult static func bounce(_ p:inout ReefPoint,velocity v:inout ReefPoint,
                                         radius:Double,off blocks:[PlacedBouncyBlock])->Bool {
        var hit=false
        for block in blocks {
            let delta=p-block.position,limit=radius+PlacedBouncyBlock.radius
            if delta.length<limit {
                let n=delta.length>0.001 ? delta*(1/delta.length):ReefPoint(x:0,y:-1)
                p=block.position+n*(limit+0.05)
                if v.dot(n)<0 {v=(v-n*(2*v.dot(n)))*0.96;hit=true}
            }
        }
        return hit
    }
}

struct ReefBonusProgress: Codable {
    var position: ReefPoint
    var courseRevision: Int? = nil
    var strokes = 0
    var finished = false
    var holed = false
    var bestStrokes: Int?
    var claimed = false
    var attempts = 1
    var currents: [Int]? = nil
    var addedCurrents:[PlacedReefCurrent]? = nil
    var bouncyBlocks:[PlacedBouncyBlock]? = nil

    var canCollect: Bool {
        finished && holed && !claimed && position == BonusCourse.home
            && (1...FirstReef.unlockLimit).contains(strokes)
            && bestStrokes.map { (1...FirstReef.unlockLimit).contains($0) } == true
    }
}

struct FirstReefProgress: Codable {
    var rescueRevision: Int? = 1
    var bubbaRescued: Bool? = false // Legacy serialized home:2 flag; now means home restored, NOT Bailey rescued.
    var homeDecorations: Set<String>? = []
    var homeRoom: ReefHomeRoom? = nil
    var furnishedRoom: ReefHomeRoom { homeRoom ?? ReefHomeRoom.defaults(owned:homeDecorations ?? []) }
    var hasRestoredHome: Bool { bubbaRescued == true }
    var restoredGardens: Set<String> { food } // Preserve the original serialized quest IDs.
    var glowPuzzleRevision: Int? = 1
    var legacyGolfFinds: Set<String>? = []
    var layoutRevision: Int? = 3
    var position = FirstReef.start
    var food: Set<String> = []
    var treasures: Set<String> = []
    var cleared: Set<String> = []
    var shotsTaken = 0 // Retain the old game's history; bonus strokes are separate.
    var completed = false
    var visited: Set<String>? = ["start"]
    var location: String? = "start"
    var bonus: ReefBonusProgress?
    var nextWorldUnlocked: Bool? = false
    var coveSearches: Set<String>? = []
    var clearingRewards: [String:ReefDiscovery]? = nil
    var miniChallenges:[String:ReefMiniAttempt]? = nil
    var hasFoundHome: Bool { completed || visited?.contains("home") == true }
}

struct ReefPickup: Identifiable { let id: String; let point: ReefPoint }
struct ReefBumper: Identifiable {
    enum Kind { case stone, kelp, sand, enemy }
    let id: String
    let point: ReefPoint
    let radius: Double
    let kind: Kind
    var clearance: String? = nil
}
struct ReefClearance: Identifiable { let id: String; let label: String; let cost: Int; let symbol: String }
struct ReefFlightFrame {
    let time: Double
    let position: ReefPoint
    let food: Set<String>
    let treasures: Set<String>
}
struct ReefJourney: Identifiable {
    let id = UUID()
    let puttBegins: Double?
    let clearedObstacle: String?
    let frames: [ReefFlightFrame]
    let outcome: FirstReefProgress
    let newTreasures: Set<String>
    var lifeGift: BloomLifeGift? = nil
    var launchCharge: Double = 0
    var coveDiscovery: String? = nil
    var discoveryText: String? = nil
    var newFood: Set<String> { outcome.food.subtracting(frames.first?.food ?? []) }
    var duration: Double { frames.last?.time ?? 0 }
    func frame(at time: Double) -> ReefFlightFrame {
        let index = frames.lastIndex(where: { $0.time <= time }) ?? 0
        let a = frames[index]
        guard index + 1 < frames.count else { return a }
        let b = frames[index + 1]
        let t = min(1, max(0, (time - a.time) / max(0.001,b.time - a.time)))
        return .init(time: time, position: a.position + (b.position-a.position)*t, food: a.food, treasures: a.treasures)
    }
}

/// The paid exploration graph. Golf data below is retained only to read older saves.
enum FirstReef {
    static let width = 340.0, height = 780.0, radius = 11.0
    static let start = ReefPoint(x: 70, y: 710)
    static let home = ReefPoint(x: 260, y: 100)
    static let turnLimit = 6
    static let par = 4
    static let unlockLimit = par
    struct Destination: Identifiable {
        enum Kind { case path, food, treasure, clearance, home }
        let id: String
        let point: ReefPoint
        let kind: Kind
        let label: String
        var glowCost: Int = 0

        var barrierKind: ReefBumper.Kind? {
            switch id {
            case "kelp", "hint-shell", "ribbon-kelp", "frond-cache": .kelp
            case "sand", "coral-cache", "shell-sand", "lantern-cache": .sand
            case "enemy", "shot-pearl", "fin-school", "pearl-cache": .enemy
            default: nil
            }
        }
        var actionLabel: String {
            if id == "frond-cache" { return "Search the kelp" }
            if id == "lantern-cache" { return "Uncover the sand" }
            if id == "pearl-cache" { return "Chase off guards" }
            return barrierAction
        }
        private var barrierAction: String {
            switch barrierKind {
            case .kelp: "Push through kelp"
            case .sand: "Sweep away sand"
            case .enemy: "Scare off fish"
            default: label
            }
        }
        var puttingBenefit: String? {
            switch id {
            case "ribbon-kelp": "Opens a straighter putting line"
            case "shell-sand": "Removes a bank-shot obstacle"
            case "fin-school": "Makes more room near home"
            default: nil
            }
        }
        var treasureReward: String {
            switch id {
            case "hint-shell": "+1 hint · +2 lives"
            case "shot-pearl": "+1 lighter"
            case "coral-cache": "15 min now · lives refilled · +2 hints"
            case "frond-cache": "+2 lives"
            case "lantern-cache": "+1 lighter"
            case "pearl-cache": "+2 hints"
            default: ""
            }
        }
        var loot: TreasureLoot {
            switch id {
            case "hint-shell": .init(hints:1,lives:2)
            case "shot-pearl": .init(lighters:1)
            case "coral-cache": .init(hints:2,instantBoost:true)
            case "frond-cache": .init(lives:2)
            case "lantern-cache": .init(lighters:1)
            case "pearl-cache": .init(hints:2)
            default: .init()
            }
        }
        enum ChestAccent { case mint, coral, gold }
        var chestAccent: ChestAccent {
            switch id {
            case "hint-shell", "frond-cache": .mint
            case "shot-pearl", "lantern-cache": .coral
            default: .gold
            }
        }

        var clearanceResult: String {
            switch id {
            case "ribbon-kelp": "Ribbon channel open!"
            case "shell-sand": "Sandy passage clear!"
            case "fin-school": "Home approach clear!"
            case "kelp": "Kelp parted!"
            case "sand": "Sand swept away! Shortcut open."
            case "enemy": "Fish scared off!"
            default: "Path open!"
            }
        }
    }
    struct TreasureLoot {
        var hints=0, shots=0, lives=0, lighters=0
        var instantBoost=false
    }
    static let destinations: [Destination] = [
        .init(id:"start",point:start,kind:.path,label:"Start"),
        .init(id:"south",point:.init(x:165,y:660),kind:.path,label:"Fork"),
        .init(id:"food-sand",point:.init(x:276,y:625),kind:.food,label:"Snack"),
        .init(id:"sand",point:.init(x:275,y:530),kind:.clearance,label:"Sweep away sand",glowCost:22),
        .init(id:"lower",point:.init(x:152,y:495),kind:.path,label:"Fork"),
        .init(id:"kelp",point:.init(x:72,y:425),kind:.clearance,label:"Push through kelp",glowCost:22),
        .init(id:"food-garden",point:.init(x:75,y:320),kind:.food,label:"Snack"),
        .init(id:"enemy",point:.init(x:255,y:360),kind:.clearance,label:"Scare off fish",glowCost:24),
        .init(id:"north",point:.init(x:165,y:250),kind:.path,label:"Fork"),
        .init(id:"food-middle",point:.init(x:76,y:165),kind:.food,label:"Snack"),
        .init(id:"home",point:home,kind:.home,label:"Home"),
        .init(id:"hint-shell",point:.init(x:40,y:555),kind:.treasure,label:"Mint chest",glowCost:14),
        .init(id:"shot-pearl",point:.init(x:270,y:230),kind:.treasure,label:"Coral chest",glowCost:16),
        .init(id:"coral-cache",point:.init(x:45,y:68),kind:.treasure,label:"Golden chest",glowCost:18),
        .init(id:"dead-end",point:.init(x:292,y:720),kind:.path,label:"Quiet cove"),
        // Optional dead-end excursions. None holds a required snack or home.
        .init(id:"ribbon-cove",point:.init(x:30,y:260),kind:.path,label:"Ribbon cove"),
        .init(id:"ribbon-kelp",point:.init(x:145,y:237),kind:.clearance,label:"Push through kelp",glowCost:22),
        .init(id:"shell-shelf",point:.init(x:310,y:225),kind:.path,label:"Shell shelf"),
        .init(id:"shell-sand",point:.init(x:226,y:166),kind:.clearance,label:"Sweep away sand",glowCost:20),
        .init(id:"fin-lookout",point:.init(x:315,y:375),kind:.path,label:"Fin lookout"),
        .init(id:"fin-school",point:.init(x:291,y:170),kind:.clearance,label:"Scare off fish",glowCost:22),
        .init(id:"frond-cache",point:.init(x:24,y:340),kind:.treasure,label:"Kelp find",glowCost:12),
        .init(id:"lantern-cache",point:.init(x:315,y:110),kind:.treasure,label:"Buried find",glowCost:14),
        .init(id:"pearl-cache",point:.init(x:302,y:456),kind:.treasure,label:"Guarded find",glowCost:14)
    ]
    static func node(_ id: String) -> Destination { destinations.first { $0.id == id }! }
    static let food = destinations.filter { $0.kind == .food }.map { ReefPickup(id:$0.id,point:$0.point) }
    static let treasures = destinations.filter { $0.kind == .treasure }.map { ReefPickup(id:$0.id,point:$0.point) }
    static let clearances = destinations.filter { $0.kind == .clearance }.map {
        ReefClearance(id:$0.id,label:$0.label,cost:$0.glowCost,symbol:"sparkles")
    }
    static let bumpers: [ReefBumper] = [
        .init(id:"sand",point:node("sand").point,radius:25,kind:.sand,clearance:"sand"),
        .init(id:"kelp",point:node("kelp").point,radius:22,kind:.kelp,clearance:"kelp"),
        .init(id:"enemy",point:node("enemy").point,radius:22,kind:.enemy,clearance:"enemy"),
        .init(id:"stone-a",point:.init(x:133,y:299),radius:12,kind:.stone),
        .init(id:"shell-sand",point:node("shell-sand").point,radius:12,kind:.sand,clearance:"shell-sand"),
        .init(id:"ribbon-kelp",point:node("ribbon-kelp").point,radius:14,kind:.kelp,clearance:"ribbon-kelp"),
        .init(id:"fin-school",point:node("fin-school").point,radius:16,kind:.enemy,clearance:"fin-school")
    ]
    struct Lane: Identifiable {
        let a: String
        let b: String
        let points: [ReefPoint]
        let radius: Double
        var gate: String? = nil
        var id: String { a + "-" + b }
    }
    static func lane(_ a: String,_ b: String,_ bends: [(Double,Double)] = [], gate: String? = nil) -> Lane {
        let p = [node(a).point] + bends.map { ReefPoint(x:$0.0,y:$0.1) } + [node(b).point]
        return Lane(a:a,b:b,points:curve(p),radius:32,gate:gate)
    }
    static let lanes: [Lane] = [
        lane("start","south"), lane("south","food-sand"), lane("food-sand","sand"),
        lane("sand","lower"), lane("south","hint-shell",[(75,650),(40,603)]),
        lane("hint-shell","lower"), lane("food-sand","dead-end"),
        lane("lower","kelp"), lane("kelp","food-garden"), lane("food-garden","north"),
        lane("lower","enemy",[(235,460)]), lane("enemy","north"),
        lane("north","food-middle"), lane("food-middle","coral-cache"),
        lane("north","shot-pearl"), lane("shot-pearl","home"),
        lane("food-middle","home",[(165,128)]),
        // Clearing the sand also opens a useful central channel for the bonus round.
        lane("lower","north",[(180,380)],gate:"sand"),
        lane("food-garden","ribbon-cove"),
        lane("ribbon-cove","ribbon-kelp",[(45,215),(105,220)]),
        lane("shot-pearl","shell-shelf"),
        lane("shell-shelf","shell-sand",[(307,161)]),
        lane("enemy","fin-lookout"),
        lane("fin-lookout","fin-school",[(315,300),(315,230)]),
        lane("food-garden","home",gate:"ribbon-kelp"),
        lane("ribbon-cove","frond-cache"),
        lane("shell-shelf","lantern-cache"),
        lane("fin-lookout","pearl-cache")
    ]
    private static func curve(_ p: [ReefPoint]) -> [ReefPoint] {
        var result:[ReefPoint] = []
        for i in 0..<(p.count-1) {
            let a=p[max(0,i-1)], b=p[i], c=p[i+1], d=p[min(p.count-1,i+2)]
            for j in 0..<18 {
                let t=Double(j)/18,t2=t*t,t3=t2*t
                result.append((b*2+(c-a)*t+(a*2-b*5+c*4-d)*t2+(b*3-a-c*3+d)*t3)*0.5)
            }
        }
        return result+[p.last!]
    }
    static func activeLanes(_ state: FirstReefProgress) -> [Lane] {
        lanes.filter { $0.gate.map(state.cleared.contains) ?? true }
    }
    static func nearestWater(_ p: ReefPoint, cleared: Set<String> = []) -> (center: ReefPoint, radius: Double, clearance: Double) {
        var best = (center:start,radius:32.0,clearance:-Double.infinity)
        for lane in lanes where lane.gate.map(cleared.contains) ?? true {
            for i in 1..<lane.points.count {
                let a=lane.points[i-1],d=lane.points[i]-a
                let t=min(1,max(0,(p-a).dot(d)/max(0.001,d.dot(d))))
                let q=a+d*t,room=lane.radius-(p-q).length
                if room > best.clearance { best=(q,lane.radius,room) }
            }
        }
        if cleared.contains("fin-school") {
            let room = 44 - (p-home).length
            if room > best.clearance { best = (home,44,room) }
        }
        return best
    }
    static func safePosition(_ p: ReefPoint, cleared: Set<String>) -> ReefPoint {
        let shore=nearestWater(p,cleared:cleared),d=p-shore.center
        return shore.clearance >= radius ? p : shore.center+d*((shore.radius-radius-0.2)/max(0.001,d.length))
    }
    static func neighbors(_ id:String,state:FirstReefProgress) -> [String] {
        activeLanes(state).compactMap { $0.a == id ? $0.b : $0.b == id ? $0.a : nil }
    }
    static func isBlocked(_ id:String,state:FirstReefProgress) -> Bool {
        if state.coveSearches != nil {return !ReefCove.passageOpen(id,in:state)}
        let destination = node(id)
        return destination.kind == .clearance && !state.cleared.contains(id)
            || destination.kind == .treasure && !state.treasures.contains(id)
    }
    /// Only a reached, unblocked stop reveals the next choices. Unknown choices hide their contents.
    static func visibleIDs(_ state:FirstReefProgress) -> Set<String> {
        let visited=state.visited ?? ["start"]
        var result=visited
        for id in visited where !isBlocked(id,state:state) {
            result.formUnion(neighbors(id,state:state))
        }
        return result
    }
    static func route(to end:String,state:FirstReefProgress,unrestricted:Bool=false) -> [String]? {
        let start=state.location ?? "start",visited=state.visited ?? ["start"]
        var previous=[start:start],queue=[start],cursor=0
        while cursor < queue.count && previous[end] == nil {
            let current=queue[cursor];cursor += 1
            // At a blocked stop you can always retreat along already explored paths.
            for next in neighbors(current,state:state) where previous[next] == nil {
                if !unrestricted {
                    if current != start && (!visited.contains(current) || isBlocked(current,state:state)) { continue }
                    if isBlocked(current,state:state) && !visited.contains(next) { continue }
                }
                previous[next]=current;queue.append(next)
            }
        }
        guard previous[end] != nil else { return nil }
        var path=[end]
        while path.last != start { path.append(previous[path.last!]!) }
        return path.reversed()
    }
    static func cost(to destination:Destination,from state:FirstReefProgress) -> Int {
        if state.coveSearches != nil {return 0}
        // First arrival reveals the blockage for free. Only the next tap clears it.
        return (state.visited?.contains(destination.id) ?? false) && isBlocked(destination.id, state: state)
            ? destination.glowCost : 0
    }
    static func visit(_ destination:Destination,from state:FirstReefProgress) -> ReefJourney? {
        guard visibleIDs(state).contains(destination.id),
              let route=route(to:destination.id,state:state) else { return nil }
        var next=state,points=[state.position]
        for (a,b) in zip(route,route.dropFirst()) {
            guard let lane=activeLanes(state).first(where:{ ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a) }) else { return nil }
            points += lane.a == a ? lane.points : Array(lane.points.reversed())
        }
        points.append(destination.point)
        let wasVisited=state.visited?.contains(destination.id) ?? false
        next.visited = (state.visited ?? ["start"]).union([destination.id])
        next.location=destination.id;next.position=destination.point
        var cleared:String?
        if state.coveSearches == nil && destination.kind == .clearance && wasVisited && !state.cleared.contains(destination.id) {
            next.cleared.insert(destination.id);cleared=destination.id
        }
        if state.coveSearches == nil && destination.kind == .food { next.food.insert(destination.id) }
        if state.coveSearches == nil && destination.kind == .treasure && wasVisited && !state.treasures.contains(destination.id) {
            next.treasures.insert(destination.id); cleared=destination.id
        }
        if next.rescueRevision == nil && destination.kind == .home && next.food.count == 3 { next.completed=true; next.nextWorldUnlocked=true }
        // Quest discoveries and clearances carry into bonus golf without moving its tee.
        var frames=[ReefFlightFrame(time:0,position:state.position,food:state.food,treasures:state.treasures)]
        var elapsed=0.0,last=state.position
        for point in points.dropFirst() where (point-last).length > 0.01 {
            elapsed += (point-last).length/175
            frames.append(.init(time:elapsed,position:point,food:state.food,treasures:state.treasures));last=point
        }
        elapsed += 0.2
        frames.append(.init(time:elapsed,position:next.position,food:next.food,treasures:next.treasures))
        return .init(puttBegins:nil,clearedObstacle:cleared,frames:frames,outcome:next,newTreasures:next.treasures.subtracting(state.treasures))
    }
    static func migrated(_ state:FirstReefProgress) -> FirstReefProgress {
        guard (state.layoutRevision ?? 1) < 3 else { return state }
        var next=state
        let y=(state.layoutRevision ?? 1) == 1 ? state.position.y/480*height : state.position.y
        let p=ReefPoint(x:state.position.x,y:y)
        let nearest=destinations.min { ($0.point-p).length < ($1.point-p).length }!.id
        next.location=state.completed ? "home" : state.food.isEmpty && state.shotsTaken == 0 ? "start" : nearest
        next.position=node(next.location!).point
        next.visited=["start"]
        // Old saves had no fog; retain access to their earned stops and current position.
        let earned=state.food.union(state.treasures).union(state.cleared).union([next.location!])
        var walker=next;walker.location="start"
        for id in earned { next.visited!.formUnion(route(to:id,state:walker,unrestricted:true) ?? [id]) }
        next.layoutRevision=3;next.nextWorldUnlocked=false
        return next
    }
    static func bonusTee(_ state:FirstReefProgress) -> ReefPoint {
        BonusCourse.tee
    }
    static func newBonus(_ state:FirstReefProgress) -> ReefBonusProgress {
        var result=ReefBonusProgress(position:bonusTee(state))
        result.courseRevision=BonusCourse.revision
        result.currents=BonusCourse.initialCurrents(state)
        result.bestStrokes=state.bonus?.bestStrokes
        result.attempts=(state.bonus?.attempts ?? 0)+1
        return result
    }
    struct BonusReward { let title:String;let glow:Int;let shots:Int;let hints:Int }
    static func reward(for strokes:Int) -> BonusReward {
        switch strokes {
        case 1: .init(title:"Hole in one!",glow:12,shots:3,hints:3)
        case 2: .init(title:"Eagle",glow:10,shots:3,hints:2)
        case 3: .init(title:"Birdie",glow:8,shots:2,hints:1)
        case 4: .init(title:"Par",glow:5,shots:1,hints:1)
        case 5...turnLimit: .init(title:"Over par",glow:0,shots:0,hints:0)
        default: .init(title:"No bonus",glow:0,shots:0,hints:0)
        }
    }
    /// Fixed-step pool-like motion. No reward or save side effects live in the renderer.
    static func putt(drag:ReefPoint,from state:FirstReefProgress) -> ReefJourney? {
        guard var bonus=state.bonus, !bonus.finished,!bonus.claimed,
              (0..<turnLimit).contains(bonus.strokes),
              drag.x.isFinite,drag.y.isFinite,drag.length >= 6 else { return nil }
        var next=state,p=bonus.position
        let home=BonusCourse.home
        let radius=BonusCourse.ballRadius
        let strength=min(1,drag.length/110)
        var v=drag*(1/drag.length)*(90+strength*350)
        var frames=[ReefFlightFrame(time:0,position:p,food:state.food,treasures:state.treasures)]
        let dt=1.0/120.0
        var time=0.0,holed=false
        var touched=Set<Int>()
        let currents=BonusCourse.activeCurrents(state)
        for step in 1...1200 {
            let previous=p
            p=p+v*dt;time += dt
            let shore=BonusCourse.nearestWater(p,cleared:state.cleared)
            if shore.clearance < radius {
                let delta=p-shore.center,n=delta*(1/max(0.0001,delta.length))
                p=shore.center+n*(shore.radius-radius-0.1)
                if v.dot(n)>0 { v=(v-n*(2*v.dot(n)))*0.86 }
            }
            for b in BonusCourse.bumpers where b.clearance.map({!state.cleared.contains($0)}) ?? true {
                let delta=p-b.point,limit=radius+b.radius
                if delta.length < limit {
                    let n=delta.length > 0.001 ? delta*(1/delta.length) : ReefPoint(x:1,y:0)
                    p=b.point+n*(limit+0.1)
                    if v.dot(n)<0 { v=(v-n*(2*v.dot(n)))*0.78 }
                }
            }
            ReefGolfPhysics.bounce(&p,velocity:&v,radius:radius,off:bonus.bouncyBlocks ?? [])
            for i in currents.indices where !touched.contains(i) && (p-currents[i].position).length<BonusCourse.currentRadius {
                // A push steers once through the bend; it never homes toward the doorway.
                v=v*BonusCourse.currentMomentumRetention+BonusCourse.currentDirection(currents[i].direction)*BonusCourse.currentImpulse
                touched.insert(i)
            }
            // Swept capture prevents a fast putt from stepping over the entrance.
            let segment=p-previous
            let t=min(1,max(0,(home-previous).dot(segment)/max(0.001,segment.dot(segment))))
            if (home-(previous+segment*t)).length < BonusCourse.holeRadius {
                p=home;holed=true
            }
            let speed=v.length
            v=v*(max(0,speed-95*dt)/max(0.001,speed))
            if step.isMultiple(of:4) || holed || v.length < 3 {
                frames.append(.init(time:time,position:p,food:state.food,treasures:state.treasures))
            }
            if holed || v.length < 3 { break }
        }
        p=BonusCourse.safePosition(p,cleared:state.cleared)
        if holed { p=home }
        bonus.position=p;bonus.strokes += 1;bonus.holed=holed
        bonus.finished=holed || bonus.strokes >= turnLimit
        if holed { bonus.bestStrokes=min(bonus.bestStrokes ?? turnLimit+1,bonus.strokes) }
        next.bonus=bonus
        frames.append(.init(time:time+0.01,position:p,food:state.food,treasures:state.treasures))
        return .init(puttBegins:0,clearedObstacle:nil,frames:frames,outcome:next,newTreasures:[],launchCharge:strength)
    }
    static func valid(_ p:FirstReefProgress) -> Bool {
        let revision=p.layoutRevision ?? 1
        guard (1...3).contains(revision),p.position.x.isFinite,p.position.y.isFinite,
              (0...width).contains(p.position.x),(0...(revision == 1 ? 480:height)).contains(p.position.y),
              p.food.isSubset(of:Set(food.map(\.id))),p.treasures.isSubset(of:Set(treasures.map(\.id))),
              p.cleared.isSubset(of:Set(clearances.map(\.id))),p.shotsTaken>=0,
              !p.completed || p.food.count == 3 else { return false }
        if let searches=p.coveSearches,!searches.isSubset(of:ReefCove.allIDs) {return false}
        if let rewards=p.clearingRewards {
            guard Set(rewards.keys).isSubset(of:p.coveSearches ?? []),
                  rewards.allSatisfy({id,item in
                      ReefCove.allIDs.contains(id) && [.shot,.hint,.life,.lighter,.currentAdder,.bouncyBlock].contains(item)
                  }) else{return false}
        }
        if let attempts=p.miniChallenges {
            for (id,attempt) in attempts {
                guard let object=destinations.flatMap({ReefCove.objects(in:$0.id)}).first(where:{$0.id==id}),
                      object.legacyChallengeKind==attempt.kind,ReefMiniChallenge.valid(attempt),
                      attempt.result != .won || p.coveSearches?.contains(id)==true else{return false}
            }
        }
        if revision < 3 { return true }
        guard let visited=p.visited,let location=p.location,let unlocked=p.nextWorldUnlocked,
              visited.isSubset(of:Set(destinations.map(\.id))),visited.contains(location),visited.contains("start"),
              p.position == node(location).point else { return false }
        if let b=p.bonus {
            if let currents=b.currents, currents.count != 3 || !currents.allSatisfy({(0..<8).contains($0)}) {return false}
            if let additions=b.addedCurrents {
                guard Set(additions.map(\.id)).count==additions.count else{return false}
                var tested=p;tested.bonus?.addedCurrents=[]
                for current in additions {
                    guard (0..<8).contains(current.direction),BonusCourse.canPlaceCurrent(at:current.position,in:tested) else{return false}
                    tested.bonus?.addedCurrents?.append(current)
                }
            }
            if let blocks=b.bouncyBlocks {
                guard Set(blocks.map(\.id)).count==blocks.count else{return false}
                var tested=p;tested.bonus?.bouncyBlocks=[]
                for block in blocks {
                    guard BonusCourse.canPlaceBlock(at:block.position,in:tested) else{return false}
                    tested.bonus?.bouncyBlocks?.append(block)
                }
            }
            let currentCourse=b.courseRevision == BonusCourse.revision
            let previousCourse=b.courseRevision == 2 || b.courseRevision == 3
            let holePosition=currentCourse ? BonusCourse.home : previousCourse ? BonusCourse.legacyHome : BonusCourse.home
            let room=currentCourse ? BonusCourse.nearestWater(b.position,cleared:p.cleared).clearance :
                previousCourse ? BonusCourse.legacyNearestWater(b.position,cleared:p.cleared).clearance :
                nearestWater(b.position,cleared:p.cleared).clearance
            guard p.completed,b.position.x.isFinite,b.position.y.isFinite,
                  b.courseRevision == nil || currentCourse || previousCourse,
                  room >= (currentCourse || previousCourse ? BonusCourse.ballRadius : radius)-0.5,
                  (0...turnLimit).contains(b.strokes),b.attempts > 0,
                  b.bestStrokes.map({(1...turnLimit).contains($0)}) ?? true,
                  b.finished == (b.holed || b.strokes == turnLimit),
                  !b.holed || (b.position == holePosition && b.strokes > 0 && b.bestStrokes != nil),
                  !b.claimed || b.bestStrokes != nil,
                  p.glowPuzzleRevision != nil || unlocked == b.claimed else { return false }
        } else if p.glowPuzzleRevision == nil && unlocked { return false }
        if p.glowPuzzleRevision != nil {
            guard p.glowPuzzleRevision == 1, unlocked == p.completed,
                  !p.completed || visited.contains("home"),
                  (p.legacyGolfFinds ?? []).isSubset(of:p.coveSearches ?? []) else {return false}
        }
        if let revision=p.rescueRevision {
            guard revision == 1, p.bubbaRescued != nil,
                  (p.homeDecorations ?? []).isSubset(of:Set(ReefHomeItem.allCases.map(\.rawValue))),
                  p.completed == (p.food.count == 3 && p.hasRestoredHome),
                  !p.hasRestoredHome || (visited.contains("home") && p.coveSearches?.contains("home:2") == true) else {return false}
        }
        guard p.furnishedRoom.valid(owned:p.homeDecorations ?? []) else {return false}
        return true
    }
}


/// World pacing is design data, never a counter or a required puzzle-number range.
enum ReefWorldPlan {
    struct World: Identifiable {
        let id:Int
        let title:String
        let story:String
        let glowWins:ClosedRange<Int>
        let built:Bool
    }
    static let worlds:[World] = [
        .init(id:1,title:"The Faded Garden",story:"A storm dimmed the reef. Relight three coral gardens and find PuffPuff’s home.",glowWins:50...100,built:true),
        .init(id:2,title:"The Hidden Reef",story:"Light the hidden coral paths and rescue Bailey, a little clownfish lost in the dark.",glowWins:75...125,built:false),
        .init(id:3,title:"The Deep Blue",story:"Awaken the deep coral lights and guide a baby sea turtle back to its mom.",glowWins:100...150,built:false),
        .init(id:4,title:"The Kelp Maze",story:"Light a safe route through the kelp and rescue Seabiscuit the seahorse.",glowWins:100...150,built:false)
    ]
}

enum ReefHomeItem:String,CaseIterable,Identifiable {
    case shellSeat,pearlLantern,coralPlanter
    var id:String {rawValue}
    var title:String {switch self {case .shellSeat:"Shell seat";case .pearlLantern:"Pearl lantern";case .coralPlanter:"Coral planter"}}
    var cost:Int {switch self {case .shellSeat:12;case .pearlLantern:18;case .coralPlanter:15}}
}


/// Normalized room coordinates keep arrangements independent of screen size and zoom.
struct ReefHomePlacement:Codable,Equatable {
    var position:ReefPoint
    var flipped=false
}
struct ReefHomeRoom:Codable,Equatable {
    var placements:[String:ReefHomePlacement]=[:]
    var lanternOn=true
    static func defaults(owned:Set<String>)->Self {
        var room=Self()
        for item in ReefHomeItem.allCases where owned.contains(item.id) {
            room.placements[item.id] = .init(position:item.homePosition)
        }
        return room
    }
    static func validPosition(_ p:ReefPoint)->Bool {
        p.x.isFinite && p.y.isFinite && (0.12...0.88).contains(p.x) && (0.46...0.86).contains(p.y)
    }
    static func clamped(_ p:ReefPoint)->ReefPoint {
        .init(x:min(0.88,max(0.12,p.x)),y:min(0.86,max(0.46,p.y)))
    }
    func canPlace(_ item:ReefHomeItem,at p:ReefPoint)->Bool {
        Self.validPosition(p) && placements.allSatisfy { key,value in
            key == item.id || abs(value.position.x-p.x)>0.15 || abs(value.position.y-p.y)>0.13
        }
    }
    func firstSpace(for item:ReefHomeItem)->ReefPoint? {
        if canPlace(item,at:item.homePosition) {return item.homePosition}
        for y in [0.56,0.73,0.85] {for x in [0.18,0.38,0.60,0.82] {
            let p=ReefPoint(x:x,y:y);if canPlace(item,at:p) {return p}
        }}
        return nil
    }
    func valid(owned:Set<String>)->Bool {
        placements.allSatisfy {key,value in
            guard let item=ReefHomeItem(rawValue:key),owned.contains(key) else{return false}
            return canPlace(item,at:value.position)
        }
    }
}
extension ReefHomeItem {
    var homePosition:ReefPoint {
        switch self {
        case .shellSeat:.init(x:0.23,y:0.69)
        case .pearlLantern:.init(x:0.53,y:0.59)
        case .coralPlanter:.init(x:0.78,y:0.73)
        }
    }
    var useTitle:String {switch self {case .shellSeat:"Rest";case .pearlLantern:"Light";case .coralPlanter:"Play"}}
}
