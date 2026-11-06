import Foundation

/// Stable authored discoveries inside the existing saved quest areas.
enum ReefCove {
    enum Find { case passage,food,treasure,coral,hint,lives,lighter,current,shot }
    struct Object:Identifiable {
        let area:String
        let slot:Int
        let find:Find
        let barrier:ReefBumper.Kind
        let cost:Int
        var id:String {"\(area):\(slot)"}
        var isGift:Bool {[Find.hint,.lives,.lighter,.current,.shot].contains(find)}
        // A closed chest may hide a quest item as well as optional supplies.
        var isChest:Bool {isGift || find == .food}
        var action:String {
            if isChest { return "Open" }
            return switch barrier {
            case .kelp:"Clear kelp"
            case .sand:"Sweep sand"
            case .enemy:"Scare off fish"
            case .stone:"Lift shells"
            }
        }
        var result:String {
            switch find {
            case .passage: FirstReef.node(area).puttingBenefit ?? "Passage found"
            case .food:"Snack found!"
            case .treasure:FirstReef.node(area).treasureReward
            case .coral:"Coral lit"
            case .hint:"+1 hint"
            case .lives:"+2 lives"
            case .lighter:"+1 lighter"
            case .current:"+1 current changer"
            case .shot:"+3 shots"
            }
        }
    }
    static let shotAreas:Set<String> = ["start","south","lower","north","home","ribbon-cove","shell-shelf","fin-lookout"]
    static let shotsPerFind = 3
    // Keep the required route at 50–100 Bloom wins, with comparable local prices.
    // Small finds are 8–12 Glow; onward passages/snacks top out at 24.
    private static let passageCosts:[String:Int] = [
        "start":10,"south":16,"food-sand":20,"lower":22,"food-garden":22,
        "north":22,"food-middle":22,"home":16,"hint-shell":20,"shot-pearl":22,
        "coral-cache":16,"dead-end":12,"ribbon-cove":18,"shell-shelf":18,
        "fin-lookout":18,"frond-cache":14,"lantern-cache":14,"pearl-cache":14
    ]
    private static let snackCosts:[String:Int] = ["food-sand":20,"food-garden":22,"food-middle":24]
    private static let deepCoves:Set<String> = [
        "home","shot-pearl","coral-cache","ribbon-cove","ribbon-kelp",
        "shell-shelf","shell-sand","fin-lookout","fin-school",
        "frond-cache","lantern-cache","pearl-cache"
    ]
    private static func supplyCost(in area:String)->Int {area == "start" ? 8:deepCoves.contains(area) ? 12:10}
    static func objects(in area:String)->[Object] {
        guard let index=FirstReef.destinations.firstIndex(where:{$0.id == area}) else{return []}
        let node=FirstReef.node(area),passage=(index*3+2)%4,prize=(passage+2)%4
        var objects = (0..<4).map {slot in
            let find:Find
            if slot == passage {find = .passage}
            else if slot == prize {
                if node.kind == .food {find = .food}
                else if node.kind == .treasure {find = .treasure}
                else if area == "start" {find = .hint}
                else if area == "lower" {find = .lives}
                else if area == "north" {find = .lighter}
                else if ["south","ribbon-cove","shell-shelf","fin-lookout","dead-end"].contains(area) {find = .current}
                else {find = .coral}
            } else {find = .coral}
            let barrier:[ReefBumper.Kind]=[.kelp,.sand,.enemy]
            let cost:Int
            switch find {
            case .passage: cost = node.kind == .clearance ? node.glowCost : passageCosts[area] ?? 16
            case .treasure: cost = node.glowCost
            case .food: cost = snackCosts[area] ?? 22
            case .coral: cost = deepCoves.contains(area) ? 10:8
            default: cost = supplyCost(in:area)
            }
            return Object(area:area,slot:slot,find:find,
                          barrier:(find == .treasure || find == .passage && node.kind == .clearance) ? node.barrierKind ?? .kelp:barrier[(index+slot)%3],cost:cost)
        }
        if shotAreas.contains(area) {objects.append(.init(area:area,slot:4,find:.shot,barrier:.sand,cost:supplyCost(in:area)))}
        return objects
    }
    static func isComplete(_ area:String,in state:FirstReefProgress)->Bool {
        let objects=objects(in:area)
        guard !objects.isEmpty,let found=state.coveSearches else{return false}
        return objects.allSatisfy {found.contains($0.id)}
    }
    enum ExitEdge:String,CaseIterable {
        case top,bottom,left,right
        var angle:Double {switch self {case .top:0;case .bottom:Double.pi;case .left:-Double.pi/2;case .right:Double.pi/2}}
    }
    static func exitEdge(to destination:FirstReef.Destination,from area:String)->ExitEdge {
        let delta=destination.point-FirstReef.node(area).point
        if abs(delta.y)>=abs(delta.x) {return delta.y<0 ? .top:.bottom}
        return delta.x<0 ? .left:.right
    }
    static func exitBearing(to destination:FirstReef.Destination,from area:String)->Double {
        let delta=destination.point-FirstReef.node(area).point
        return atan2(delta.x,-delta.y)
    }
    static func exitDirectionName(to destination:FirstReef.Destination,from area:String)->String {
        let names=["up","up and right","right","down and right","down","down and left","left","up and left"]
        let step=Int((exitBearing(to:destination,from:area) / (.pi/4)).rounded())
        return names[(step+8)%8]
    }
    static func objectPoint(_ slot:Int,in area:String,width:Double,height:Double)->ReefPoint {
        if slot == 4,area == "home" {return .init(x:width*0.82,y:height*0.48)}
        let y=slot == 0 ? max(height*0.29,min(206,height*0.38)):height*([0.29,0.30,0.69,0.69,0.42][slot])
        return .init(x:width*([0.24,0.76,0.24,0.76,0.5][slot]),y:y)
    }
    static func exitPoint(to destination:FirstReef.Destination,from area:String,exits:[FirstReef.Destination],width:Double,height:Double,contentHeight:Double?=nil)->ReefPoint {
        exitLayout(from:area,exits:exits,width:width,height:height,contentHeight:contentHeight)[destination.id] ?? .init(x:width/2,y:height-44)
    }
    static func exitLayout(from area:String,exits:[FirstReef.Destination],width:Double,height:Double,contentHeight:Double?=nil)->[String:ReefPoint] {
        let center=ReefPoint(x:width/2,y:height/2),rx=max(1,width/2-48),ry=max(1,height/2-44)
        struct Choice {let id:String;let candidates:[ReefPoint];let fallback:[ReefPoint];let target:ReefPoint}
        var perimeter:[ReefPoint]=[]
        for x in stride(from:158.0,through:width-48,by:4) {perimeter.append(.init(x:x,y:44))}
        for x in stride(from:48.0,through:width-48,by:4) {perimeter.append(.init(x:x,y:height-44))}
        for y in stride(from:178.0,through:height-44,by:4) {perimeter.append(.init(x:48,y:y))}
        for y in stride(from:44.0,through:height-44,by:4) {perimeter.append(.init(x:width-48,y:y))}
        let localObjects=objects(in:area)
        let clearPerimeter=perimeter.filter {p in
            localObjects.allSatisfy {object in
                let q=objectPoint(object.slot,in:area,width:width,height:contentHeight ?? height)
                // Reserve the visible price/chest, in addition to other exit labels.
                let dx=abs(p.x-q.x),dy=abs(p.y-(q.y+(object.isChest ? 8:0)))
                return dx >= (object.isChest ? 94:102) || dy >= (object.isChest ? 75:71)
            }
        }
        var choices:[Choice]=[]
        for destination in exits {
            let delta=destination.point-FirstReef.node(area).point
            let span=max(1,max(abs(delta.x),abs(delta.y)))
            let target=center+ReefPoint(x:delta.x/span*rx,y:delta.y/span*ry)
            func correctSide(_ p:ReefPoint)->Bool {
                (abs(delta.x)/span<0.2 || (p.x-center.x)*delta.x>0)
                    && (abs(delta.y)/span<0.2 || (p.y-center.y)*delta.y>0)
            }
            var candidates=clearPerimeter.filter(correctSide)
            if candidates.isEmpty {candidates=perimeter.filter(correctSide)}
            candidates.sort {($0-target).length < ($1-target).length}
            let fallback=perimeter.filter(correctSide).sorted {($0-target).length < ($1-target).length}
            choices.append(Choice(id:destination.id,candidates:candidates,fallback:fallback,target:target))
        }
        choices.sort {a,b in
            if a.candidates.count == b.candidates.count {return a.id < b.id}
            return a.candidates.count < b.candidates.count
        }
        var result:[String:ReefPoint]=[:]
        for choice in choices {
            var point=choice.candidates.first ?? choice.target
            for candidate in choice.candidates+choice.fallback {
                let clear=result.values.allSatisfy {other in
                    abs(candidate.x-other.x)>=98 || abs(candidate.y-other.y)>=82
                }
                if clear {point=candidate;break}
            }
            result[choice.id]=point
        }
        return result
    }

    struct TravelFrame {
        let oldOffset:ReefPoint
        let newOffset:ReefPoint
        let fish:ReefPoint
        let progress:Double
    }
    /// Fish and camera share world coordinates: no pose swap at the cove boundary.
    static func travelFrame(from:ReefPoint,to:ReefPoint,start:ReefPoint,size:ReefPoint,fraction:Double)->TravelFrame {
        func ease(_ value:Double)->Double {let t=min(1,max(0,value));return t*t*(3-2*t)}
        let delta=to-from,span=max(1,max(abs(delta.x),abs(delta.y)))
        let step=ReefPoint(x:delta.x/span*size.x,y:delta.y/span*size.y)
        let swim=ease(fraction),camera=ease((fraction-0.20)/0.60)
        let origin=ReefPoint(x:start.x*size.x,y:start.y*size.y)
        let destination=step+ReefPoint(x:size.x*0.5,y:size.y*0.51)
        return .init(oldOffset:step * -camera,newOffset:step * (1-camera),
                     fish:origin+(destination-origin)*swim-step*camera,progress:swim)
    }
    static var allIDs:Set<String> {Set(FirstReef.destinations.flatMap{objects(in:$0.id).map(\.id)})}
    static func passageOpen(_ area:String,in state:FirstReefProgress)->Bool {
        guard let searches=state.coveSearches else {
            let node=FirstReef.node(area)
            return node.kind == .clearance ? state.cleared.contains(area):node.kind == .treasure ? state.treasures.contains(area):true
        }
        return objects(in:area).contains {$0.find == .passage && searches.contains($0.id)}
    }
    static func migrate(_ state:FirstReefProgress)->FirstReefProgress {
        guard state.coveSearches == nil else{return state}
        var result=state,opened=Set<String>()
        // Preserve every discovered route and all previously earned objects.
        for area in state.visited ?? ["start"] {
            for object in objects(in:area) {
                if object.find == .passage && passageOpen(area,in:state) || object.find == .food && state.food.contains(area) || object.find == .treasure && state.treasures.contains(area) {
                    opened.insert(object.id)
                }
            }
        }
        result.coveSearches=opened
        return result
    }
    static func uncover(_ object:Object,from state:FirstReefProgress)->ReefJourney? {
        guard state.bonus?.claimed != true,state.location == object.area,
              objects(in:object.area).contains(where:{$0.id == object.id}),
              !(state.coveSearches ?? []).contains(object.id) else{return nil}
        var next=state
        next.coveSearches=(state.coveSearches ?? []).union([object.id])
        var clearance:String?
        switch object.find {
        case .food:next.food.insert(object.area)
        case .treasure:next.treasures.insert(object.area);clearance=object.area
        case .passage:
            if FirstReef.node(object.area).kind == .clearance {next.cleared.insert(object.area);clearance=object.area}
        default:break
        }
        // Finding home before the last snack still counts. Optional finds never gate golf.
        if next.food.count == FirstReef.food.count && next.hasFoundHome { next.completed=true }
        let frames=[ReefFlightFrame(time:0,position:state.position,food:state.food,treasures:state.treasures),
                    .init(time:0.55,position:state.position,food:next.food,treasures:next.treasures)]
        return .init(puttBegins:nil,clearedObstacle:clearance,frames:frames,outcome:next,
                     newTreasures:next.treasures.subtracting(state.treasures),coveDiscovery:object.id,discoveryText:object.result)
    }
}
