#if DEBUG
import SwiftUI

struct ReefDesignLab:View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var family=0
    @State private var golfIndex=0
    @State private var newGolf=true
    @State private var slingIndex=0
    @State private var pathIndex=0
    @State private var golfers=LabGolfKind.allCases.map(LabGolf.init)
    @State private var slingers=SlingTrial.allCases.map(SlingLab.init)
    @State private var paths=LabPathKind.allCases.map(ReefSearchLab.init)
    @AppStorage("puffpuff.lab.favorites") private var favorites=""
    private var selectedID:String {family == 0 && newGolf ? "sling-\(slingIndex)":"\(family)-\(family == 0 ? golfIndex:pathIndex)"}
    private var selectedIndex:Int {family == 1 ? pathIndex:newGolf ? slingIndex:golfIndex}
    private func trialName(_ index:Int)->String {family == 1 ? LabPathKind.allCases[index].name:newGolf ? SlingTrial.allCases[index].name:LabGolfKind.allCases[index].name}
    private var kept:Bool {favorites.split(separator:",").map(String.init).contains(selectedID)}
    var body:some View {
        OceanScene {
            VStack(spacing:8) {
                HStack {
                    Text("Playground").reefFont(size:25,weight:.semibold,display:true)
                    Spacer()
                    Button("Done") {dismiss()}.buttonStyle(ReefButtonStyle(kind:.quiet))
                }
                HStack(spacing:16) {
                    familyButton("Golf",0);familyButton("Paths",1)
                    if family == 0 {
                        Menu {
                            Button("Sling + currents") {newGolf=true}
                            Button("Original eight") {newGolf=false}
                        } label: {Text(newGolf ? "New":"Original").reefFont(size:12)}
                            .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Golf collection")
                    }
                    Spacer()
                    Button {toggleKeep()} label: {Label(kept ? "Kept":"Keep",systemImage:kept ? "heart.fill":"heart")}
                        .buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("Keep this idea")
                }
                HStack(spacing:3) {
                    ForEach(0..<8) {index in
                        Button {if family == 1 {pathIndex=index}else if newGolf {slingIndex=index}else{golfIndex=index}} label: {
                            Text("\(index+1)").reefFont(size:15,weight:.semibold)
                                .frame(maxWidth:.infinity,minHeight:44)
                                .background(SeaGlassShape(seed:Double(index)).fill(selectedIndex == index ? ReefTheme.honey.opacity(0.6):ReefTheme.glass.opacity(0.35)))
                        }.buttonStyle(ReefButtonStyle(kind:.navigation))
                            .accessibilityLabel("\(index+1). \(trialName(index))")
                    }
                }
                ScrollView {
                    VStack(spacing:12) {
                        if family == 0 {
                            if newGolf {ReefSlingLabView(game:slingers[slingIndex]).id(slingIndex)}
                            else {LabGolfView(game:golfers[golfIndex]).id(golfIndex)}
                        } else {
                            ReefSearchLabView(game:paths[pathIndex]) {finds in
                                if newGolf {slingers[slingIndex].explore(finds)}else{golfers[golfIndex].explore(finds)}
                                family=0
                            }.id(pathIndex)
                        }
                        Text("Rough trials · your real save and supplies stay untouched")
                            .reefFont(size:11).foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center)
                    }.padding(.vertical,6)
                }.scrollIndicators(.visible)
                    .scrollIndicatorsFlash(onAppear:true)
                    .frame(maxHeight:.infinity)
                    .id(selectedID)
            }.padding(16).frame(maxWidth:620).frame(maxWidth:.infinity)
        }.foregroundStyle(ReefTheme.ink).environment(\.reefPaused,false)
        .task(id:"\(family)-\(newGolf)-\(golfIndex)-\(slingIndex)-\(scenePhase)") {
            guard family == 0,scenePhase == .active else {return}
            let game=golfers[golfIndex]
            let sling=slingers[slingIndex],isNew=newGolf
            while !Task.isCancelled {
                do {try await Task.sleep(for:.milliseconds(16))} catch {return}
                if scenePhase == .active {if isNew {sling.tick(1.0/60)}else{game.tick(1.0/60)}}
            }
        }
        #if os(macOS)
        .frame(minWidth:470,idealWidth:540,minHeight:560,idealHeight:820)
        #endif
    }
    private func familyButton(_ title:String,_ value:Int)->some View {
        Button {family=value} label: {
            Text(title).reefFont(size:18,weight:family == value ? .bold:.regular)
                .foregroundStyle(family == value ? ReefTheme.ink:ReefTheme.muted)
        }.buttonStyle(ReefButtonStyle(kind:.quiet))
    }
    private func toggleKeep() {
        var saved=Set(favorites.split(separator:",").map(String.init))
        if kept {saved.remove(selectedID)}else{saved.insert(selectedID)}
        favorites=saved.sorted().joined(separator:",")
    }
}

struct LabGolfView:View {
    @Bindable var game:LabGolf
    @State private var drag:[ReefPoint]=[]
    @State private var showBonuses=false
    var body:some View {
        VStack(spacing:10) {
            Text("\(game.kind.id+1). \(game.kind.name)").reefFont(size:23,weight:.semibold,display:true)
            Text(game.kind.instruction).reefFont(size:13).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            HStack {
                Text("Trail finds").reefFont(size:13)
                ForEach(0..<4) {finds in
                    Button {game.explore(finds);drag=[]} label: {
                        Text("\(finds)/3").reefFont(size:12,weight:.semibold).frame(minWidth:36,minHeight:36)
                            .background(SeaGlassShape(seed:Double(finds)).fill(game.finds == finds ? ReefTheme.honey.opacity(0.55):ReefTheme.glass.opacity(0.3)))
                    }.buttonStyle(ReefButtonStyle(kind:.navigation)).disabled(game.moving)
                }
            }
            HStack {
                Text("\(game.shots)/4 shots").reefFont(size:13,weight:.semibold)
                Spacer()
                Button("Bonuses") {showBonuses.toggle()}.buttonStyle(ReefButtonStyle(kind:.quiet))
                Button("Retry") {game.reset();drag=[]}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }.frame(maxWidth:350)
            if showBonuses {
                Text("1 shot: 12 Glow + hint + lighter\n2: 8 Glow + hint · 3: 5 Glow · 4: 2 Glow\nMiss home: nothing. Retry, then collect one best set.")
                    .reefFont(size:12).multilineTextAlignment(.center)
            }
            board.aspectRatio(0.75,contentMode:.fit).frame(maxWidth:300)
                .overlay(alignment:.bottomTrailing) {
                    VStack(spacing:5) { controls }.padding(.trailing,12).padding(.bottom,12)
                }
            if game.won || game.shots>=4 && !game.moving {
                Text(game.reward).reefFont(size:14,weight:.semibold).foregroundStyle(ReefTheme.gold)
                if game.won {
                    Button(game.collected ? "Collected in this trial":"Collect trial bonuses") {game.collected=true}
                        .buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.collected)
                }
            } else if !game.message.isEmpty {Text(game.message).reefFont(size:12)}
            Text(game.kind.advantage).reefFont(size:13).foregroundStyle(ReefTheme.muted)
                .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
        }.padding(.horizontal,6)
    }
    private var board:some View {
        GeometryReader {geometry in
            let scale=geometry.size.width/300
            Canvas {c,size in
                var world=c;world.scaleBy(x:scale,y:scale)
                LabSketch.course(in:world)
                if game.kind != .stop && game.kind != .bank && game.kind != .currents {
                    for (i,p) in game.blockers.enumerated() {LabSketch.obstacle(i,in:world,at:p,size:43)}
                }
                if game.kind == .bank {
                    for (i,p) in game.banks.enumerated() {
                        LabSketch.line([game.ball,p,game.home],in:world,color:ReefTheme.gold.opacity(game.bank == i ? 0.8:0.15),dashed:true)
                        if i>game.finds {LabSketch.obstacle(0,in:world,at:p+(game.home-p)*0.48,size:30)}
                    }
                }
                if game.kind == .currents {
                    LabSketch.line([.init(x:75,y:350)]+game.gates+[game.home],in:world,color:ReefTheme.gold.opacity(0.5),dashed:true)
                }
                if game.kind == .stop {
                    LabSketch.line([.init(x:75,y:350),.init(x:185,y:205),game.home],in:world,color:ReefTheme.glint.opacity(0.7),dashed:true)
                    world.stroke(LabSketch.circle(game.home,17+Double(game.finds)*6),with:.color(ReefTheme.honey),lineWidth:3)
                }
                LabSketch.home(in:world,at:game.home)
                let aim=game.phase == 0 ? game.angle:game.lockedAngle
                if game.kind == .rhythm && !game.moving && !game.ended {
                    let end=game.ball+ReefPoint(x:cos(aim)*90,y:sin(aim)*90)
                    LabSketch.line([game.ball,end],in:world,color:ReefTheme.gold,dashed:true)
                }
                if !drag.isEmpty {
                    if game.kind == .draw {LabSketch.line(drag,in:world,color:ReefTheme.gold,dashed:false)}
                    else if let first=drag.first,let last=drag.last {
                        let v=game.kind == .sling ? first-last:last-first
                        LabSketch.line([game.ball,game.ball+v],in:world,color:ReefTheme.gold,dashed:true)
                    }
                }
                LabSketch.fish(in:world,at:game.ball,charged:drag.isEmpty ? 0.1:0.6,happy:game.won)
            }
            .allowsHitTesting(false)
            // Only Puff Puff owns the aiming drag; the surrounding water scrolls.
            if [.putt,.sling,.draw].contains(game.kind), !game.moving, !game.ended {
                Color.clear.frame(width:60,height:60).contentShape(Rectangle())
                    .position(x:game.ball.x*scale,y:game.ball.y*scale)
                    .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("lab-golf-board"))
                .onChanged {value in
                    guard !game.moving,!game.ended else{return}
                    let start=ReefPoint(x:value.startLocation.x/scale,y:value.startLocation.y/scale)
                    let p=ReefPoint(x:value.location.x/scale,y:value.location.y/scale)
                    if drag.isEmpty {drag=[start]}
                    if game.kind == .draw {drag.append(p)}else{drag=[start,p]}
                }.onEnded {value in
                    guard !game.moving,!game.ended else {drag=[];return}
                    let start=ReefPoint(x:value.startLocation.x/scale,y:value.startLocation.y/scale)
                    let end=ReefPoint(x:value.location.x/scale,y:value.location.y/scale)
                    if game.kind == .draw {game.traced(drag)}
                    if game.kind == .putt {game.launch(end-start)}
                    if game.kind == .sling {game.launch(start-end)}
                    drag=[]
                })
            }
            if game.kind == .target, !game.moving, !game.ended {
                Color.clear.contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded {value in
                        game.send(to:.init(x:value.location.x/scale,y:value.location.y/scale))
                    })
            }
            if game.kind == .bank {
                ForEach(0..<4) {i in
                    Button {game.bank=i} label: {
                        Text("\(i+1)").reefFont(size:13,weight:.bold).frame(width:44,height:44)
                            .background(SeaGlassShape(seed:Double(i)).fill(game.bank == i ? ReefTheme.honey:ReefTheme.glass))
                    }.buttonStyle(.plain).position(x:game.banks[i].x*scale,y:game.banks[i].y*scale)
                        .disabled(game.moving || game.ended).accessibilityLabel("Bank route \(i+1)")
                }
            }
            if game.kind == .currents {
                ForEach(0..<3) {i in
                    Button {game.turn(i)} label: {
                        Image(systemName:"arrow.up").rotationEffect(.degrees(Double(game.valves[i])*90))
                            .frame(width:44,height:44).background(SeaGlassShape(seed:Double(i)).fill(i<game.finds ? ReefTheme.honey:ReefTheme.glass))
                    }.buttonStyle(.plain).position(x:game.gates[i].x*scale,y:game.gates[i].y*scale)
                        .disabled(game.moving || game.ended || i<game.finds).accessibilityLabel("Turn current \(i+1)")
                }
            }
        }.coordinateSpace(name:"lab-golf-board")
    }
    @ViewBuilder private var controls:some View {
        switch game.kind {
        case .stop:
            Button(game.moving ? "Stop!":"Go") {game.startStop()}.buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.ended && !game.moving)
        case .rhythm:
            if game.phase == 1 && !game.moving {
                GeometryReader {g in
                    ZStack(alignment:.leading) {
                        Capsule().fill(ReefTheme.glass)
                        Capsule().fill(ReefTheme.honey).frame(width:g.size.width*game.power)
                    }
                }.frame(width:110,height:12)
            }
            Button(game.phase == 0 ? "Lock aim":"Puff!") {game.rhythmTap()}.buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.moving || game.ended)
        case .bank:
            Button("Puff route \(game.bank+1)") {game.bankPuff()}.buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.moving || game.ended)
        case .currents:
            Button("Puff!") {game.currentPuff()}.buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.moving || game.ended)
        case .draw:
            Text("Ink: \(420+game.finds*60)").reefFont(size:12).foregroundStyle(ReefTheme.muted)
        default: EmptyView()
        }
    }
}

struct LabPathView:View {
    @Bindable var game:LabPath
    let onGolf:(Int)->Void
    var body:some View {
        VStack(spacing:11) {
            Text("\(game.kind.id+1). \(game.kind.name)").reefFont(size:23,weight:.semibold,display:true)
            Text(game.kind.instruction).reefFont(size:13).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            HStack(spacing:14) {
                ReefIconLabel("\(game.glow)",.glow,size:22)
                Label("\(game.foods.count)/3",systemImage:"leaf.fill")
                Label("\(game.finds.count)/3",systemImage:"gift.fill")
                Spacer()
                Button("Reset") {game.reset()}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }.reefFont(size:13,weight:.semibold)
            if game.kind == .fog || game.kind == .garden {islandBoard}
            else if game.kind == .hunt {huntBoard}
            else if game.kind == .hub && game.stage<0 {hubBoard}
            else {closeup}
            if !game.message.isEmpty {Text(game.message).reefFont(size:13,weight:.semibold).multilineTextAlignment(.center)}
            navigation
            HStack {
                Button("Bloom · +8 trial Glow") {game.glow += 8;game.message="8 trial Glow added"}.buttonStyle(ReefButtonStyle(kind:.quiet))
                if game.foods.count == 3 && !game.won && [.hub,.hunt,.current].contains(game.kind) {
                    Button("Go home") {game.returnHome()}.buttonStyle(ReefButtonStyle(kind:.action))
                }
            }
            if game.won {
                Text("\(game.finds.count)/3 putting advantages found").reefFont(size:15,weight:.semibold)
                Button("Try these finds in golf") {onGolf(game.finds.count)}.buttonStyle(ReefButtonStyle(kind:.action))
            }
            Text(game.kind.idea).reefFont(size:13).foregroundStyle(ReefTheme.muted).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
        }.padding(.horizontal,6)
    }
    private var islandBoard:some View {
        GeometryReader {g in
            let scale=g.size.width/300
            ZStack {
                Canvas {c,_ in
                    var world=c;world.scaleBy(x:scale,y:scale)
                    for (a,b) in game.edges {
                        if game.kind == .garden || game.visited.contains(a) || game.visited.contains(b) {
                            LabSketch.line([game.node(a).point,game.node(b).point],in:world,color:ReefTheme.glint.opacity(0.35),dashed:true)
                        }
                    }
                }
                ForEach(game.nodes) {node in
                    nodeButton(node.id,compact:true)
                        .position(x:node.point.x*scale,y:node.point.y*scale)
                        .opacity(game.available(node.id) || game.visited.contains(node.id) ? 1:game.kind == .fog ? 0.16:0.4)
                }
            }
        }.frame(maxWidth:330).aspectRatio(0.75,contentMode:.fit)
    }
    private var huntBoard:some View {
        VStack(spacing:18) {
            Text("Sonar: three snacks are hidden among six hiding places.").reefFont(size:12).foregroundStyle(ReefTheme.muted)
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:20) {
                ForEach([2,3,5,6,8,9],id:\.self) {nodeButton($0)}
            }
            nodeButton(12)
        }.padding(.vertical,12)
    }
    private var hubBoard:some View {
        VStack(spacing:22) {
            Canvas {c,s in LabSketch.home(in:c,at:.init(x:s.width/2,y:80))}.frame(height:100)
            ForEach(0..<3) {region in
                Button {game.stage=region;game.message=""} label: {
                    HStack {
                        Image(systemName:["leaf","sun.max","fish"][region])
                        Text(["Kelp grove","Sand shelf","Fish passage"][region])
                        Spacer()
                        if game.foods.contains(region) {Image(systemName:"checkmark")}
                    }.padding(15).background(MembraneSurface(tint:ReefTheme.cyan,intensity:0.6))
                }.buttonStyle(ReefButtonStyle(kind:.navigation))
            }
        }
    }
    private var closeup:some View {
        VStack(spacing:12) {
            ZStack {
                Canvas {c,size in
                    c.fill(SeaGlassShape(seed:Double(game.stage+game.location)).path(in:CGRect(origin:.zero,size:size)),with:.color(ReefTheme.glass.opacity(0.45)))
                    for i in 0..<4 {LabSketch.obstacle((i+game.kind.id)%3,in:c,at:.init(x:25+Double(i)*80,y:55+Double(i%2)*55),size:45)}
                    LabSketch.fish(in:c,at:.init(x:size.width/2,y:size.height*0.65),charged:0,happy:game.won)
                }.frame(height:150).accessibilityHidden(true)
                if game.kind == .coves {
                    Text(game.location == 0 ? "Lagoon edge":game.current.isHome ? "Home":"Cove \(game.location)").reefFont(size:16,weight:.semibold).offset(y:-55)
                } else {
                    Text(game.kind == .current ? "Fork \(game.stage+1) · loop \(game.loops+1)":"\(["Shallows","Reef","Deep water","Home"][max(0,min(3,game.stage))])")
                        .reefFont(size:16,weight:.semibold).offset(y:-55)
                }
            }
            if game.kind == .coves && !game.cleared.contains(game.location) {nodeButton(game.location)}
            if game.kind == .current {
                HStack {nodeButton(game.choices[0],direction:"← Left");nodeButton(game.choices[1],direction:"Right →")}
                    .simultaneousGesture(DragGesture(minimumDistance:35).onEnded {v in
                        guard abs(v.translation.width)>abs(v.translation.height)*1.5 else{return}
                        game.enter(game.choices[v.translation.width<0 ? 0:1])
                    })
            } else {
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
                    ForEach(game.choices,id:\.self) {nodeButton($0)}
                }
            }
        }
    }
    @ViewBuilder private var navigation:some View {
        if game.kind == .side || game.kind == .dive {
            HStack {
                Button(game.kind == .dive ? "↑ Ascend":"← Previous") {game.stage=max(0,game.stage-1);game.message=""}
                    .buttonStyle(ReefButtonStyle(kind:.quiet)).disabled(game.stage == 0 || game.won)
                Spacer()
                Button(game.kind == .dive ? "Dive ↓":"Next →") {game.stage=min(3,game.stage+1);game.message=""}
                    .buttonStyle(ReefButtonStyle(kind:.quiet)).disabled(game.stage == 3 || game.won)
            }
        }
        if game.kind == .hub && game.stage>=0 {
            Button("Back to home") {game.stage = -1;game.message=""}.buttonStyle(ReefButtonStyle(kind:.quiet))
        }
    }
    private func nodeButton(_ id:Int,compact:Bool=false,direction:String?=nil)->some View {
        let node=game.node(id),visited=game.visited.contains(id),clear=game.cleared.contains(id)
        return Button {game.enter(id)} label: {
            VStack(spacing:5) {
                if let direction {Text(direction).reefFont(size:13,weight:.semibold)}
                ZStack {
                    SeaGlassShape(seed:Double(id)).fill(clear ? ReefTheme.cyan.opacity(0.6):visited ? ReefTheme.sand:ReefTheme.abyss.opacity(0.7))
                    Image(systemName:node.isHome ? "house.fill":clear ? (node.food != nil ? "leaf.fill":node.find != nil ? "gift.fill":"checkmark"):visited ? ["leaf","sun.max","fish"][node.barrier]:"questionmark")
                        .foregroundStyle(clear || visited ? ReefTheme.ink:ReefTheme.glint)
                    if game.location == id && compact {Circle().stroke(ReefTheme.gold,lineWidth:3)}
                }.frame(width:compact ? 40:54,height:compact ? 40:54)
                if !compact {
                    Text(node.isHome ? "Home":clear ? "Uncovered":visited || game.kind == .garden || game.kind == .current ? "\(node.action) · \(node.cost) Glow":game.kind == .hunt ? "Scan · 1 Glow":"Explore")
                        .reefFont(size:12,weight:.semibold).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                }
            }.padding(compact ? 0:10).frame(maxWidth:compact ? 44:.infinity)
                .background {if !compact {MembraneSurface(tint:ReefTheme.cyan,intensity:0.45)}}
        }.buttonStyle(ReefButtonStyle(kind:.navigation)).disabled(!game.available(id) || game.won)
            .accessibilityLabel(node.isHome ? "Home":clear ? "Uncovered place \(id)":visited ? "\(node.action), \(node.cost) Glow":"Explore place \(id)")
    }
}

enum LabSketch {
    static func circle(_ p:ReefPoint,_ r:Double)->Path {Path(ellipseIn:CGRect(x:p.x-r,y:p.y-r,width:r*2,height:r*2))}
    static func line(_ points:[ReefPoint],in c:GraphicsContext,color:Color,dashed:Bool) {
        guard let first=points.first else{return};var path=Path();path.move(to:CGPoint(x:first.x,y:first.y))
        for p in points.dropFirst(){path.addLine(to:CGPoint(x:p.x,y:p.y))}
        c.stroke(path,with:.color(color),style:.init(lineWidth:2,lineCap:.round,lineJoin:.round,dash:dashed ? [3,7]:[]))
    }
    static func course(in c:GraphicsContext) {
        let rect=CGRect(x:20,y:20,width:260,height:360)
        let shape=Path(roundedRect:rect,cornerRadius:20)
        c.fill(shape,with:.color(ReefTheme.glass.opacity(0.62)))
        c.stroke(shape,with:.color(ReefTheme.sand),lineWidth:6)
        c.stroke(shape,with:.color(ReefTheme.muted.opacity(0.3)),lineWidth:1)
        for i in 0..<20 {c.fill(circle(.init(x:35+WaterDrawing.seed(i,salt:4)*230,y:30+WaterDrawing.seed(i,salt:7)*340),1),with:.color(ReefTheme.glint.opacity(0.6)))}
    }
    static func fish(in c:GraphicsContext,at p:ReefPoint,charged:Double,happy:Bool) {
        var fish=c;fish.translateBy(x:p.x-173.0/320*42,y:p.y-144.0/270*35)
        PipRenderer.drawPose(in:fish,size:CGSize(width:42,height:35),time:0,inflation:charged,joy:happy ? 1:0)
    }
    static func home(in c:GraphicsContext,at p:ReefPoint) {
        c.fill(circle(p,18),with:.color(ReefTheme.abyss))
        c.stroke(circle(p,18),with:.color(ReefTheme.honey),lineWidth:3)
        var pole=Path();pole.move(to:CGPoint(x:p.x+19,y:p.y));pole.addLine(to:CGPoint(x:p.x+19,y:p.y-34))
        c.stroke(pole,with:.color(ReefTheme.gold),lineWidth:2)
        var flag=Path();flag.move(to:CGPoint(x:p.x+19,y:p.y-34));flag.addLine(to:CGPoint(x:p.x+39,y:p.y-27));flag.addLine(to:CGPoint(x:p.x+19,y:p.y-20));flag.closeSubpath()
        c.fill(flag,with:.color(ReefTheme.coral))
        c.draw(Text("Home").font(ReefTypography.font(size:10,weight:.bold)).foregroundColor(ReefTheme.ink),at:CGPoint(x:p.x,y:p.y+29))
    }
    static func obstacle(_ kind:Int,in c:GraphicsContext,at p:ReefPoint,size:Double) {
        TrailArt.draw(kind%3 == 0 ? .kelpForest:kind%3 == 1 ? .sandpit:.enemySchool,in:c,at:CGPoint(x:p.x,y:p.y),size:size,time:0)
    }
}
#endif
