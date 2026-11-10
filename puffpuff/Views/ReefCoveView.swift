import SwiftUI

struct CoveActionTiming {
    let scares:Bool
    let eats:Bool
    let treasure:Bool
    let restores:Bool
    var clearedAt:Double {scares ? 1.65:0.8}
    var eatAt:Double {clearedAt+0.15}
    var duration:Double {clearedAt+(treasure || restores ? 1.55:0.45)}
    init(_ object:ReefCove.Object) {
        scares=object.barrier == .enemy && !object.isChest && object.find != .food && object.find != .home
        eats=false
        restores=object.find == .food || object.find == .home
        treasure=object.isChest || object.find == .treasure || object.clearingReward != nil
    }
}

struct ReefCoveView:View {
    let progress:FirstReefProgress
    let departure:FirstReefProgress?
    let journey:ReefJourney?
    let elapsed:Double
    let time:Double
    let reduceMotion:Bool
    let enabled:Bool
    let onVisit:(FirstReef.Destination)->Void
    let onUncover:(ReefCove.Object)->Void
    let onMap:()->Void
    var bottomInset:Double = 0
    @Environment(\.reefPaused) private var paused
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedID:String?
    @State private var mapPosition=ReefPoint(x:0,y:0)
    @GestureState private var mapDrag=CGSize.zero
    @State private var rest=CGPoint(x:0.5,y:0.51)
    @State private var swimFrom=CGPoint(x:0.5,y:0.51)
    @State private var swimBegan=Date()
    @State private var swimDuration=0.7
    @State private var swimming=false
    @State private var hasSwum=false
    @State private var actionFrom=CGPoint(x:0.5,y:0.51)
    @State private var arrivalFrom:CGPoint?
    @State private var facing=1.0
    private var area:String {progress.location ?? "start"}
    private var objects:[ReefCove.Object] {ReefCove.objects(in:area)}
    private var searches:Set<String> {progress.coveSearches ?? []}
    private var hasPatrollingEnemies:Bool {
        objects.contains { object in
            object.barrier == .enemy && !object.isChest && object.find != .food && object.find != .home
                && !searches.contains(object.id)
        }
    }
    private var action:ReefCove.Object? {objects.first{$0.id == journey?.coveDiscovery}}
    private var exits:[FirstReef.Destination] {
        FirstReef.neighbors(area,state:progress).filter {
            ReefCove.passageOpen(area,in:progress) || progress.visited?.contains($0) == true
        }.map(FirstReef.node)
    }
    var body:some View {
        GeometryReader {g in
            TimelineView(.animation(minimumInterval:1.0/30,paused:(!swimming && !hasPatrollingEnemies) || paused || reduceMotion)) { clock in
                scene(size:g.size,now:clock.date)
            }
        }
        .accessibilityElement(children:.contain).accessibilityLabel(ReefQuestView.areaName(area))
        .onChange(of:area) {_,_ in
            rest = .init(x:0.5,y:0.51);swimFrom=rest;swimming=false;hasSwum=false;selectedID=nil
            if let departure {facing=progress.position.x>=departure.position.x ? 1:-1}
        }
        .onChange(of:paused) {_,value in if value {holdSwim();selectedID=nil} }
        .onChange(of:scenePhase) {_,value in if value != .active {holdSwim()} }
        .onChange(of:journey?.id) {old,new in if new == nil && old != nil {swimming=false} }
        .task(id:swimBegan) {
            guard swimming else{return}
            let began=swimBegan
            do {
                try await Task.sleep(for:.seconds(swimDuration))
                guard !Task.isCancelled,swimBegan == began else{return}
                swimming=false
            } catch {}
        }
    }
    private func travel(in size:CGSize)->ReefCove.TravelFrame? {
        guard !reduceMotion,let journey,journey.coveDiscovery == nil,
              let departure,departure.location != area else{return nil}
        let start=arrivalFrom ?? CGPoint(x:0.5,y:0.51)
        return ReefCove.travelFrame(from:departure.position,to:progress.position,
                                   start:.init(x:start.x,y:start.y),size:.init(x:size.width,y:size.height),
                                   fraction:elapsed/ReefQuestView.duration(journey))
    }
    private func scene(size:CGSize,now:Date)->some View {
        let movement=travel(in:size),pose=fishPose(size:size,now:now)
        let exitPositions=exitPositions(in:size)
        return ZStack {
            LinearGradient(colors:[ReefTheme.deep,ReefTheme.glass,ReefTheme.deep],startPoint:.topLeading,endPoint:.bottomTrailing)
            Color.clear.contentShape(Rectangle()).onTapGesture {p in
                guard enabled else{return};selectedID=nil;swim(to:p,in:size)
            }
            if let movement,let departure {
                let previous=ReefCoveView(progress:departure,departure:nil,journey:nil,elapsed:0,time:time,
                                          reduceMotion:reduceMotion,enabled:false,onVisit:{_ in},onUncover:{_ in},onMap:{},bottomInset:bottomInset)
                previous.ground(size:size,pose:pose)
                    .offset(x:movement.oldOffset.x,y:movement.oldOffset.y)
                ground(size:size,pose:pose)
                    .offset(x:movement.newOffset.x,y:movement.newOffset.y)
                Canvas {c,s in drawTravelDarkness(in:c,size:s,movement:movement,previous:previous,fish:pose.point)}
                    .allowsHitTesting(false).accessibilityHidden(true)
                previous.foreground(size:size,pose:pose,interactive:false)
                    .offset(x:movement.oldOffset.x,y:movement.oldOffset.y).allowsHitTesting(false).accessibilityHidden(true)
                foreground(size:size,pose:pose,interactive:!paused && journey == nil)
                    .offset(x:movement.newOffset.x,y:movement.newOffset.y)
            } else {
                ground(size:size,pose:pose)
                Canvas {c,s in drawDarkness(in:c,size:s,fish:pose.point)}.allowsHitTesting(false).accessibilityHidden(true)
                foreground(size:size,pose:pose,interactive:!paused && journey == nil)
            }
            Canvas {c,s in drawFish(in:c,pose:pose,size:s)}.allowsHitTesting(false).accessibilityHidden(true)
            if journey == nil { ForEach(exits) {destination in
                if let p=exitPositions[destination.id] {
                    exitButton(destination).position(x:p.x,y:p.y)
                }
            } }
            miniMap(size:size,movement:movement)
            if let selectedID,let object=objects.first(where:{$0.id == selectedID}),!searches.contains(object.id) {
                Color.clear.contentShape(Rectangle()).onTapGesture {p in
                    self.selectedID=nil
                    if enabled {swim(to:p,in:size)}
                }.accessibilityLabel("Dismiss details").accessibilityAddTraits(.isButton)
                let halfHeight=86.0
                details(object,size:size)
                    .position(x:min(size.width-140,max(140,point(object.slot,in:size).x)),
                              y:min(size.height-bottomInset-halfHeight-12,max(halfHeight+12,point(object.slot,in:size).y+(object.slot<2 ? 120:-120))))
                    .accessibilityAction(named:"Dismiss") {self.selectedID=nil}
            }
        }.clipped().coordinateSpace(name:"reef-cove")
    }
    private func miniMap(size:CGSize,movement:ReefCove.TravelFrame?)->some View {
        let bounds=ReefPoint(x:size.width,y:size.height)
        let offset=ReefCove.mapOffset(mapPosition+ReefPoint(x:mapDrag.width,y:mapDrag.height),size:bounds,bottomInset:bottomInset)
        return ReefMiniMap(progress:progress,position:departure.map {
            $0.position+(progress.position-$0.position)*(movement?.progress ?? 1)
        } ?? progress.position,onExpand:{selectedID=nil;onMap()})
            .frame(width:96,height:120)
            .highPriorityGesture(DragGesture(minimumDistance:8,coordinateSpace:.named("reef-cove"))
                .updating($mapDrag) {value,state,_ in state=value.translation}
                .onEnded {value in
                    let drag=ReefPoint(x:value.translation.width,y:value.translation.height)
                    let projected=ReefPoint(x:value.predictedEndTranslation.width,y:value.predictedEndTranslation.height)-drag
                    // Keep a fast flick gentle; never launch the chart across the whole screen.
                    let coast=reduceMotion ? ReefPoint(x:0,y:0):projected*min(1,70/max(1,projected.length))
                    let proposed=mapPosition+drag+coast
                    withAnimation(reduceMotion ? nil:.easeOut(duration:0.28)) {
                        mapPosition=ReefCove.mapOffset(proposed,size:bounds,bottomInset:bottomInset)
                    }
                })
            .position(x:56+offset.x,y:68+offset.y)
            .allowsHitTesting(journey == nil && !paused)
            .accessibilityHint("Tap to expand. Drag or flick to move the map.")
            .accessibilityAction(named:"Return to upper left") {mapPosition = .init(x:0,y:0)}
    }
    private func ground(size:CGSize,pose:CoveFishPose)->some View {
        let artSize=min(128,min(size.width*0.36,size.height*0.27))
        let bleed=size.width*0.5
        // Render planted coral beyond the viewport so a pan never exposes cut edges.
        return Canvas {raw,_ in
            var c=raw;c.translateBy(x:bleed,y:bleed)
            let s=size
            drawPaths(in:c,size:s)
            for object in objects.prefix(4) {
                let p=point(object.slot,in:s)
                let bed=SeaGlassShape(seed:Double(object.slot+area.count)).path(in:
                    CGRect(x:p.x-s.width*0.23,y:p.y-s.height*0.035,width:s.width*0.46,height:s.height*0.20))
                let life=light(object)
                c.fill(bed,with:.color(CoralArt.blend(0x747F70,0xEAD7A6,life).opacity(0.20)))
                for chip in 0..<9 {
                    let x=p.x+Double((chip*31+object.slot*17)%97-48)*s.width/300
                    let y=p.y+s.height*0.10+Double((chip*13)%19)
                    c.fill(Path(ellipseIn:.init(x:x,y:y,width:4+Double(chip%3)*3,height:2.5)),with:.color(Color(hex:0xA2AA94).opacity((1-life)*0.55)))
                }
            }
            WaterDrawing.caustics(in:c,size:s,time:time,strength:0.14+0.31*areaRestoration)
            for i in 0..<4 {
                let x=Double(i)*s.width/3
                var ray=Path();ray.move(to:.init(x:x,y:0));ray.addLine(to:.init(x:x-75,y:s.height));ray.addLine(to:.init(x:x+40,y:s.height));ray.closeSubpath()
                c.fill(ray,with:.color(ReefTheme.glint.opacity(0.015+areaRestoration*0.035)))
            }
            drawGarden(in:c,size:s)

            for object in objects {drawObject(object,in:c,size:s,artSize:artSize,pose:pose)}
        }
        .frame(width:size.width+bleed*2,height:size.height+bleed*2)
        .frame(width:size.width,height:size.height)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
    // The departing cove is a drawing snapshot, not an installed SwiftUI view.
    // Resolve environment-driven interaction in scene(), never through that snapshot.
    private func foreground(size:CGSize,pose:CoveFishPose,interactive:Bool)->some View {
        let artSize=min(128,min(size.width*0.36,size.height*0.27))
        return ZStack {
            Canvas {c,s in
                for object in objects where object.isChest || object.find == .treasure {
                    drawTreasure(object,in:c,size:s,artSize:artSize)

                }
                for object in objects {
                    drawRestoration(object,in:c,size:s,artSize:artSize)
                    drawKelpGate(object,in:c,size:s,artSize:artSize)
                    drawEnemyPatrol(object,in:c,size:s,artSize:artSize)
                    if let item=progress.clearingRewards?[object.id],
                       action?.id == object.id,!reduceMotion {
                        let reveal=elapsed-CoveActionTiming(object).clearedAt
                        if reveal<1.55 {
                            var prize=c;prize.opacity *= max(0,min(1,(1.55-reveal)/0.3))
                            ReefTreasureArt.draw([.init(item:item)],in:prize,at:point(object.slot,in:s),chestSize:artSize,elapsed:reveal)
                        }
                    }
                }
                drawLifeGift(in:c,size:s)
            }.allowsHitTesting(false).accessibilityHidden(true)
            ForEach(objects.filter{!searches.contains($0.id)}) {object in
                Button {
                    guard enabled,interactive else{return}
                    swim(to:standPoint(object,in:size),in:size)
                    selectedID=object.id
                } label: {
                    VStack(spacing:0) {
                        if object.isChest {Spacer(minLength:0)}
                        HStack(spacing:0) {
                            ReefIcon(.glowKey,size:object.isChest ? 33:43,sparkleSeed:object.slot+area.utf8.reduce(0){$0+Int($1)})
                            Text("\(object.cost)").reefFont(size:object.isChest ? 18:20,weight:.semibold)
                        }.padding(.leading,4).padding(.trailing,12).padding(.vertical,4)
                            .background(MembraneShape().fill(ReefTheme.glass.opacity(0.98)))
                    }.frame(width:artSize+10,height:artSize+20)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(!enabled || !interactive)
                    .position(point(object.slot,in:size))
                    .accessibilityLabel(object.isChest ? "Open treasure chest, \(object.cost) Lumes":"\(object.cost) Lumes to uncover hiding place \(object.slot+1)")
                    .accessibilityHint("Show the action and Lumes price.")
            }

        }
    }
    private func details(_ object:ReefCove.Object,size:CGSize)->some View {
        VStack(spacing:16) {
            Text(object.action).reefFont(size:18,weight:.semibold)
                .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                .frame(maxWidth:.infinity)
            Button {
                actionFrom=freeSpot(at:Date())
                facing=object.slot%2 == 0 ? -1:1
                selectedID=nil;onUncover(object)
            } label: {
                HStack(spacing:8) {Text("\(object.cost) Lumes").reefFont(size:16,weight:.semibold);ReefIcon(.glow,size:27)}
                    .frame(maxWidth:.infinity,alignment:.center)
            }.buttonStyle(ReefButtonStyle(kind:.action)).disabled(!enabled)
                .accessibilityLabel("\(object.cost) Lumes, \(object.action.lowercased())")
        }.padding(.horizontal,24).padding(.top,18).padding(.bottom,26).frame(width:min(280,size.width-24))
            .background(MembraneShape().fill(ReefTheme.glass))
            .shadow(color:ReefTheme.abyss.opacity(0.4),radius:12,y:4)
            .contentShape(Rectangle()).onTapGesture {}
    }
    private func light(_ object:ReefCove.Object)->Double {
        guard searches.contains(object.id) else{return 0}
        guard let action,action.id == object.id,!reduceMotion else{return 1}
        return smooth((elapsed-CoveActionTiming(action).clearedAt)/0.65)
    }
    private var areaRestoration:Double { objects.isEmpty ? 0:objects.map(light).reduce(0,+)/Double(objects.count) }
    private func restoration(at p:CGPoint,size:CGSize)->Double {
        guard let nearest=objects.min(by:{
            let a=point($0.slot,in:size),b=point($1.slot,in:size)
            return hypot(a.x-p.x,a.y-p.y)<hypot(b.x-p.x,b.y-p.y)
        }) else{return 0}
        return light(nearest)
    }
    private func pathTint(restoration:Double)->Color {
        let amount=min(1,max(0,restoration))
        func blend(_ from:UInt32,_ to:UInt32)->UInt32 {
            func component(_ shift:UInt32)->UInt32 {
                let a=Double((from>>shift)&255),b=Double((to>>shift)&255)
                return UInt32((a+(b-a)*amount).rounded())
            }
            return (component(16)<<16)|(component(8)<<8)|component(0)
        }
        return .adaptive(light:blend(0x5F5747,0xEAD7A6),dark:blend(0x213A3A,0x91BBB1))
    }
    private func drawPaths(in context:GraphicsContext,size:CGSize,overShadow:Bool=false) {
        let center=CGPoint(x:size.width*0.5,y:size.height*0.51)
        let exitsHere=exitPositions(in:size)
        let routeExits=exits.filter{exitsHere[$0.id] != nil}
        let connections=objects.map { (point($0.slot,in:size),light($0)) }
            + routeExits.map {destination in
                let p=exitsHere[destination.id]!
                return (CGPoint(x:p.x,y:p.y),areaRestoration)
            }
        for (index,connection) in connections.enumerated() {
            let end=connection.0,dx=end.x-center.x,dy=end.y-center.y
            let bend=Double(index%2 == 0 ? 1:-1)*min(26,abs(dy)*0.16)
            var path=Path();path.move(to:center)
            path.addCurve(to:end,
                          control1:.init(x:center.x+dx*0.22+bend,y:center.y+dy*0.42),
                          control2:.init(x:center.x+dx*0.78-bend,y:center.y+dy*0.72))
            if index>=objects.count {
                let destination=routeExits[index-objects.count]
                let canvas=ReefPoint(x:size.width,y:size.height)
                let step=ReefCove.travelStep(from:FirstReef.node(area).point,to:destination.point,size:canvas)
                let seam=ReefCove.routeSeam(from:FirstReef.node(area).point,to:destination.point,size:canvas)
                path.addCurve(to:.init(x:seam.x,y:seam.y),
                              control1:.init(x:end.x+(seam.x-end.x)*0.45,y:end.y+(seam.y-end.y)*0.45),
                              control2:.init(x:seam.x-step.x*0.12,y:seam.y-step.y*0.12))
            }
            let wornPath=pathTint(restoration:connection.1)
            var sand=context
            sand.addFilter(.blur(radius:overShadow ? 1.2:1.8))
            sand.stroke(path,with:.color(wornPath.opacity(overShadow ? 0.12+connection.1*0.035:0.38+connection.1*0.08)),
                        style:.init(lineWidth:index<objects.count ? 24:32,lineCap:.round))
            if !overShadow {
                context.stroke(path,with:.color(ReefTheme.glint.opacity(0.015+connection.1*0.075)),
                               style:.init(lineWidth:9,lineCap:.round))
            }
        }
    }
    private func drawGarden(in c:GraphicsContext,size:CGSize) {
        let seed=area.utf8.reduce(0){$0+Int($1)}
        var plants:[CoveCoralPlant]=[]
        // Overlapping little gardens wrap each discovery, leaving the middle swimmable.
        for object in objects.prefix(4) {
            let p=point(object.slot,in:size)
            for j in 0..<3 {
                let side=object.slot%2 == 0 ? -1.0:1.0
                let dx=[side*0.12,-side*0.075,side*0.015][j]*size.width
                let dy=[0.075,0.105,0.16][j]*size.height
                plants.append(.init(x:p.x+dx,y:p.y+dy,size:size.width*[0.31,0.28,0.34][j],
                    species:(seed+object.slot+j)%3,opacity:j == 0 ? 0.72:0.96,seed:Double(object.slot*3+j),restored:light(object)))
            }
        }
        // Cropped foreground fronds and larger corals make this a close-up reef.
        let edges:[(Double,Double,Double)]=[(-0.04,0.34,0.42),(0.98,0.20,0.37),
            (0.03,0.97,0.46),(0.22,1.06,0.44),(0.76,1.03,0.46),(1.03,0.78,0.40)]
        for (i,edge) in edges.enumerated() {
            plants.append(.init(x:edge.0*size.width,y:edge.1*size.height,size:edge.2*size.width,
                species:(seed+i+1)%3,opacity:0.88,seed:Double(i+20),
                restored:restoration(at:.init(x:edge.0*size.width,y:edge.1*size.height),size:size)))
        }
        for plant in plants.sorted(by:{$0.y<$1.y}) {
            var coral=c;coral.opacity=plant.opacity
            ReefRestorationArt.coral(CoralSpecies.allCases[plant.species],in:coral,
                at:.init(x:plant.x,y:plant.y),size:plant.size,time:time,
                seed:plant.seed,moving:!reduceMotion,restored:plant.restored)
        }
        if seed%3 != 1 {
            let health=restoration(at:.init(x:0,y:size.height*0.88),size:size)
            var kelp=c;kelp.opacity=0.42+health*0.10
            kelp.addFilter(.saturation(0.1+health*0.9))
            TrailArt.draw(.kelpForest,in:kelp,at:.init(x:-size.width*0.08,y:size.height*0.88),
                size:size.width*0.64,time:health>0.5 && !reduceMotion ? time:0)
        }
        // Slow, sparse plankton stays part of the shared, pausable ocean clock.
        for i in 0..<20 {
            let x=Double((i*73+seed*17)%997)/997*size.width
            let y=Double((i*137+seed*11)%991)/991*size.height
            let drift=reduceMotion ? 0:sin(time/8000 * .pi*2+Double(i))*2
            c.fill(Path(ellipseIn:.init(x:x+drift,y:y,width:i%4 == 0 ? 2:1.1,height:i%4 == 0 ? 2:1.1)),
                with:.color(ReefTheme.glint.opacity((i%3 == 0 ? 0.5:0.23)*(0.15+0.85*restoration(at:.init(x:x,y:y),size:size)))))
        }
    }
    private func drawTravelDarkness(in c:GraphicsContext,size:CGSize,movement:ReefCove.TravelFrame,previous:ReefCoveView,fish:CGPoint) {
        // One continuous water shadow covers both coves, including diagonal gaps.
        let bounds=Path(CGRect(origin:.zero,size:size))
        let scenes=[(previous,movement.oldOffset),(self,movement.newOffset)]
        c.drawLayer {shade in
            shade.fill(bounds,with:.color(ReefTheme.abyss.opacity(0.89)))
            shade.blendMode = .destinationOut
            for (scene,offset) in scenes {
                for object in scene.objects where scene.searches.contains(object.id) {
                    let local=scene.point(object.slot,in:size)
                    let p=CGPoint(x:local.x+offset.x,y:local.y+offset.y)
                    let radius=min(size.width*0.62,size.height*0.39)
                    let glow=Gradient(stops:[.init(color:.white,location:0),.init(color:.white.opacity(0.95),location:0.38),.init(color:.clear,location:1)])
                    shade.fill(bounds,with:.radialGradient(glow,center:p,startRadius:0,endRadius:radius))
                }
            }
            shade.fill(bounds,with:.radialGradient(Gradient(colors:[.white.opacity(0.52),.clear]),center:fish,startRadius:8,endRadius:75))
        }
        for (scene,offset) in scenes {
            var translated=c;translated.translateBy(x:offset.x,y:offset.y)
            scene.drawPaths(in:translated,size:size,overShadow:true)
            scene.drawTumbleweeds(in:translated,size:size)
            for object in scene.objects where scene.searches.contains(object.id) {
                let local=scene.point(object.slot,in:size),p=CGPoint(x:local.x+offset.x,y:local.y+offset.y)
                c.fill(bounds,with:.radialGradient(Gradient(colors:[ReefTheme.honey.opacity(0.1),.clear]),center:p,startRadius:0,endRadius:100))
            }
        }
    }
    private func drawDarkness(in c:GraphicsContext,size:CGSize,fish:CGPoint) {
        let bounds=Path(CGRect(origin:.zero,size:size))
        c.drawLayer {shade in
            shade.fill(bounds,with:.color(ReefTheme.abyss.opacity(0.89)))
            shade.blendMode = .destinationOut
            for object in objects {
                let amount=light(object);guard amount>0 else{continue}
                let p=point(object.slot,in:size),radius=min(size.width*0.62,size.height*0.39)
                let glow=Gradient(stops:[.init(color:.white.opacity(amount),location:0),.init(color:.white.opacity(amount*0.95),location:0.38),.init(color:.clear,location:1)])
                shade.fill(bounds,with:.radialGradient(glow,center:p,startRadius:0,endRadius:radius))
            }
            // A small fish halo permits navigation without lighting unpaid sections.
            shade.fill(bounds,with:.radialGradient(Gradient(colors:[.white.opacity(0.52),.clear]),center:fish,startRadius:8,endRadius:75))
        }
        // A faint sandy trace remains readable in the dark; paid pools still own the light.
        drawPaths(in:c,size:size,overShadow:true)
        for object in objects where light(object)>0 {
            let p=point(object.slot,in:size),amount=light(object)
            c.fill(bounds,with:.radialGradient(Gradient(colors:[ReefTheme.honey.opacity(0.1*amount),.clear]),center:p,startRadius:0,endRadius:100))
        }
        drawTumbleweeds(in:c,size:size)
    }
    private func drawTumbleweeds(in context:GraphicsContext,size:CGSize) {
        let seed=area.utf8.reduce(0){$0+Int($1)}
        let darkStrand=Color.adaptive(light:0x766348,dark:0x91A999)
        let lightStrand=Color.adaptive(light:0xA28B63,dark:0xC0CBAF)
        for i in 0..<3 {
            let drift=reduceMotion ? (Double(i)+0.5)/3:(time/48000+Double(i)*0.37).truncatingRemainder(dividingBy:1)
            let x=(drift*1.18-0.09)*size.width
            let lane=0.22+Double((seed+i*29)%54)/100
            let y=lane*size.height+(reduceMotion ? 0:sin(time/8000 * .pi*2+Double(i)*2.1)*7)
            let center=CGPoint(x:x,y:y)
            let restored=restoration(at:center,size:size)
            let opacity=0.44*(1-restored)
            guard opacity>0.04 else{continue}

            var weed=context
            weed.translateBy(x:center.x,y:center.y)
            if !reduceMotion {weed.rotate(by:.radians(time/8000 * .pi*2*Double(i%2 == 0 ? 1:-1)))}
            weed.opacity=opacity
            let radius=9.0+Double((seed+i*11)%5)
            for strand in 0..<10 {
                let angle=Double(strand)/10 * .pi*2+Double(i)*0.47
                let length=radius*(0.7+Double((strand*7+i)%5)*0.075)
                let base=CGPoint(x:cos(angle)*radius*0.12,y:sin(angle)*radius*0.12)
                let tip=CGPoint(x:cos(angle)*length,y:sin(angle)*length)
                let control=CGPoint(x:cos(angle+0.5)*length*0.48,y:sin(angle+0.5)*length*0.48)
                var twig=Path();twig.move(to:base);twig.addQuadCurve(to:tip,control:control)
                weed.stroke(twig,with:.color(strand%3 == 0 ? lightStrand:darkStrand),
                            style:.init(lineWidth:strand%3 == 0 ? 1.45:1.1,lineCap:.round))

                let split=CGPoint(x:base.x+(tip.x-base.x)*0.62,y:base.y+(tip.y-base.y)*0.62)
                let branchAngle=angle+(strand%2 == 0 ? 0.75:-0.75)
                let branchTip=CGPoint(x:split.x+cos(branchAngle)*radius*0.40,y:split.y+sin(branchAngle)*radius*0.40)
                var branch=Path();branch.move(to:split);branch.addQuadCurve(to:branchTip,control:CGPoint(x:split.x+cos(branchAngle+0.35)*radius*0.22,y:split.y+sin(branchAngle+0.35)*radius*0.22))
                weed.stroke(branch,with:.color(darkStrand),style:.init(lineWidth:0.9,lineCap:.round))
            }
        }
    }
    private func drawObject(_ object:ReefCove.Object,in c:GraphicsContext,size:CGSize,artSize:Double,pose:CoveFishPose) {
        let p=point(object.slot,in:size),active=action?.id == object.id,timing=CoveActionTiming(object)
        let opened=searches.contains(object.id),reveal=active && !reduceMotion ? smooth((elapsed-timing.clearedAt)/0.4):opened ? 1.0:0.0
        if object.find != .food && object.find != .home && !object.isChest && object.barrier != .kelp && (!opened || active && reveal<1) {
            var obstacle=c
            if active && timing.scares && !reduceMotion {
                let flee=smooth((elapsed-0.9)/0.85)
                obstacle.translateBy(x:facing*flee*size.width*0.75,y:-flee*size.height*0.18)
                obstacle.opacity=1-flee
            } else {obstacle.opacity=1-reveal}
            // Enemy fish live above the shadow; their planted kelp remains in the reef.
            if object.barrier == .enemy {obstacle=c;obstacle.opacity=0.75}
            TrailArt.draw(object.barrier == .sand ? .sandpit:.kelpForest,in:obstacle,at:p,size:artSize,time:reduceMotion ? 0:time)
        }
        guard opened,object.find != .food,object.find != .home else{return}
        var found=c;found.opacity=reveal
        if object.find == .treasure || object.isChest {
            // Rendered above the water shadow, with the saved prize contents.
            return
        } else if object.find == .passage {
            for n in 0..<3 {
                var wave=Path();wave.move(to:.init(x:p.x-artSize*0.3,y:p.y+Double(n-1)*14))
                wave.addQuadCurve(to:.init(x:p.x+artSize*0.3,y:p.y+Double(n-1)*14-7),control:.init(x:p.x,y:p.y+Double(n-1)*14+7))
                found.stroke(wave,with:.color(ReefTheme.glint.opacity(0.8)),style:.init(lineWidth:3,lineCap:.round))
            }
        } else {
            var coral=found;coral.translateBy(x:p.x-artSize*0.4,y:p.y-artSize*0.4);coral.scaleBy(x:artSize*0.008,y:artSize*0.008)
            let species=CoralSpecies.allCases[(object.slot+area.count)%3]
            for path in [species.left,species.right,species.body] {coral.fill(path,with:.color(Color(hex:species.color)))}
            coral.stroke(species.veins,with:.color(Color(hex:species.tip)),style:.init(lineWidth:2.8,lineCap:.round))
        }
    }
    private func drawKelpGate(_ object:ReefCove.Object,in c:GraphicsContext,size:CGSize,artSize:Double) {
        guard object.barrier == .kelp,!object.isChest,object.find != .food,object.find != .home else{return}
        let opened=searches.contains(object.id),active=action?.id == object.id
        let spread=opened ? (active && !reduceMotion ? smooth((elapsed-0.10)/0.65):1):0
        let p=point(object.slot,in:size)
        var plants=c;plants.addFilter(.saturation(0.18+spread*0.94))
        TrailArt.draw(.kelpForest,in:plants,at:.init(x:p.x,y:p.y-artSize*0.02),
                      size:artSize*1.28,time:reduceMotion ? 0:time,spread:spread)
    }
    private func drawEnemyPatrol(_ object:ReefCove.Object,in c:GraphicsContext,size:CGSize,artSize:Double) {
        guard object.barrier == .enemy,!object.isChest,object.find != .food,object.find != .home else{return}
        let active=action?.id == object.id
        guard !searches.contains(object.id) || active && !reduceMotion else{return}
        let flee=active && !reduceMotion ? smooth((elapsed-0.9)/0.85):0
        guard flee<1 else{return}
        let p=point(object.slot,in:size)
        TrailArt.drawPatrol(in:c,at:.init(x:p.x,y:p.y-artSize*0.12),size:artSize,
                           time:time,moving:!reduceMotion,flee:flee,direction:facing)
    }
    private func drawTreasure(_ object:ReefCove.Object,in c:GraphicsContext,size:CGSize,artSize:Double) {
        let opened=searches.contains(object.id)
        guard object.isChest || opened else { return }
        let active=action?.id == object.id
        let revealTime=active && !reduceMotion ? elapsed-CoveActionTiming(object).clearedAt : nil
        let revealed=opened && (revealTime == nil || revealTime! >= 0)
        let chestSize=artSize*(object.isChest ? 0.85:0.9)
        let p=point(object.slot,in:size)
        let asset:TrailArt.Asset=object.isChest
            ? (revealed ? .chestMintOpen:.chestMint)
            : FirstReef.node(area).chestArt(open:revealed)
        var chest=c
        if !object.isChest && !revealed { chest.opacity=0 }
        if !revealed,object.isChest {
            let glow=c
            let halo=CGRect(x:p.x-chestSize*0.6,y:p.y-chestSize*0.5,width:chestSize*1.2,height:chestSize)
            glow.fill(Path(ellipseIn:halo),with:.radialGradient(Gradient(colors:[ReefTheme.gold.opacity(0.25),.clear]),center:p,startRadius:2,endRadius:chestSize*0.6))
            // Keep the user-edited lid fully closed; the key below it is the action.
            chest.addFilter(.brightness(0.04))
        }
        TrailArt.draw(asset,in:chest,at:p,size:chestSize)
        guard revealed,let revealTime,revealTime<1.55 else{return}
        var prize=c;prize.opacity *= max(0,min(1,(1.55-revealTime)/0.3))
        ReefTreasureArt.draw(ReefTreasureArt.contents(for:object,in:progress),in:prize,at:p,chestSize:chestSize,elapsed:revealTime)
        if object.find == .food { ReefTreasureArt.bubbles(in:c,at:p,chestSize:chestSize,elapsed:revealTime) }
    }
    private func drawRestoration(_ object:ReefCove.Object,in c:GraphicsContext,size:CGSize,artSize:Double) {
        guard object.find == .food || object.find == .home else{return}
        let p=point(object.slot,in:size),opened=searches.contains(object.id)
        let amount=light(object)
        if object.find == .home {
            var cottage=c;cottage.addFilter(.saturation(0.08+amount*0.92));cottage.addFilter(.brightness(-0.18*(1-amount)))
            CoralHomeArt.draw(in:cottage,at:.init(x:p.x,y:p.y+artSize*0.37),scale:artSize*1.12/300,open:opened)
        } else {
            for i in 0..<3 {
                ReefRestorationArt.coral(CoralSpecies.allCases[i],in:c,
                    at:.init(x:p.x+Double(i-1)*artSize*0.28,y:p.y+Double(i%2)*12),size:artSize*0.75,
                    time:time,seed:Double(i),moving:opened && !reduceMotion,restored:amount)
            }
        }
        if action?.id == object.id,opened,!reduceMotion {
            let t=max(0,elapsed-CoveActionTiming(object).clearedAt)
            if t<1.4 {
                var halo=c;halo.addFilter(.blur(radius:12));halo.opacity=sin(min(1,t/1.4) * .pi)*0.45
                halo.fill(Path(ellipseIn:.init(x:p.x-artSize*0.55,y:p.y-artSize*0.55,width:artSize*1.1,height:artSize*1.1)),with:.color(ReefTheme.gold))
                ReefTreasureArt.bubbles(in:c,at:p,chestSize:artSize,elapsed:t)
            }
        }
    }
    private func drawLifeGift(in c:GraphicsContext,size:CGSize) {
        guard let gift=journey?.lifeGift else{return}
        // The golden chest already displays its guaranteed boost among its contents.
        if let action,action.find == .treasure,FirstReef.node(area).loot.instantBoost,gift == .instant {return}
        let revealAt=action.map{CoveActionTiming($0).clearedAt} ?? 0
        guard reduceMotion || elapsed>=revealAt else{return}
        let item:ReefDiscovery = gift == .refill ? .life : gift == .stored ? .storedBoost : .instantBoost
        let center=CGPoint(x:size.width*0.56,y:size.height*0.30)
        ReefTreasureArt.draw([.init(item:item)],in:c,at:center,chestSize:110,elapsed:reduceMotion ? nil:elapsed-revealAt)
        c.draw(Text(gift == .refill ? "Life refill" : gift == .stored ? "Saved boost" : "15 min")
            .font(.custom("ChalkboardSE-Bold",size:13)).foregroundColor(ReefTheme.ink),
            at:.init(x:center.x,y:center.y+6))
    }
    private func drawFish(in c:GraphicsContext,pose:CoveFishPose,size:CGSize) {
        var fish=c;fish.translateBy(x:pose.point.x,y:pose.point.y);fish.scaleBy(x:pose.facing,y:1)
        fish.translateBy(x:-pose.size*173/320,y:-pose.size*144/320)
        PipRenderer.drawPose(in:fish,size:.init(width:pose.size,height:pose.size*270/320),time:time,inflation:pose.inflation,joy:1,chew:pose.chew)
        if pose.chew>0,let action {
            let t=elapsed-CoveActionTiming(action).eatAt
            for i in 0..<6 {
                let q=max(0,t-Double(i)*0.08),alpha=max(0,1-q/0.9)
                let x=pose.point.x+pose.facing*(19+q*Double(12+i*4)),y=pose.point.y+9-q*Double(22+i*5)+q*q*26
                c.fill(Path(ellipseIn:.init(x:x,y:y,width:2.5,height:2.5)),with:.color(ReefTheme.coral.opacity(alpha)))
            }
        }
    }
    private func fishPose(size:CGSize,now:Date)->CoveFishPose {
        var p=freeSpot(at:now),inflation=0.0,chew=0.0,fishSize=88.0,heading=facing
        if let action,!reduceMotion {
            let timing=CoveActionTiming(action)
            // A chest reveals its prize beside the fish. No second swim or victory hop.
            // Only the distinct enemy-clearance action needs a choreographed approach.
            if timing.scares {
                let target=normalized(standPoint(action,in:size),in:size),t=smooth(elapsed/0.6)
                p = .init(x:actionFrom.x+(target.x-actionFrom.x)*t,y:actionFrom.y+(target.y-actionFrom.y)*t)
            }
            if timing.scares {inflation=smooth((elapsed-0.45)/0.4)*(1-smooth((elapsed-1.5)/0.45));fishSize += inflation*18}
            if timing.eats,elapsed>timing.eatAt,elapsed<timing.eatAt+1.05 {chew=0.5+0.5*sin((elapsed-timing.eatAt) * .pi * 9)}
        } else if let movement=travel(in:size),let departure {
            p = .init(x:movement.fish.x/size.width,y:movement.fish.y/size.height)
            heading=progress.position.x>=departure.position.x ? 1:-1
        }
        return .init(point:.init(x:p.x*size.width,y:p.y*size.height),size:fishSize,inflation:inflation,chew:chew,facing:heading)
    }
    private func freeSpot(at now:Date)->CGPoint {
        guard swimming,!reduceMotion else{return rest}
        let t=smooth(now.timeIntervalSince(swimBegan)/swimDuration)
        return .init(x:swimFrom.x+(rest.x-swimFrom.x)*t,y:swimFrom.y+(rest.y-swimFrom.y)*t-sin(t * .pi)*0.025)
    }
    private func swim(to p:CGPoint,in size:CGSize) {
        // A paused TimelineView's date is the last frame, not the tap time.
        // Capture a fresh clock here so an idle tap cannot start at the end.
        let now=Date()
        let target=normalized(CGPoint(x:min(size.width-35,max(35,p.x)),y:min(size.height-35,max(35,p.y))),in:size)
        let from=freeSpot(at:now);facing=target.x>=from.x ? 1:-1;swimFrom=from;rest=target
        swimDuration=min(1.25,max(0.3,hypot((target.x-from.x)*size.width,(target.y-from.y)*size.height)/240))
        swimBegan=now;swimming = !reduceMotion;hasSwum=true
    }
    private func holdSwim() {
        rest=freeSpot(at:Date());swimFrom=rest;swimming=false
    }
    private func normalized(_ p:CGPoint,in s:CGSize)->CGPoint {.init(x:p.x/max(1,s.width),y:p.y/max(1,s.height))}
    private func smooth(_ v:Double)->Double {let t=min(1,max(0,v));return t*t*(3-2*t)}
    private func standPoint(_ object:ReefCove.Object,in s:CGSize)->CGPoint {
        let p=point(object.slot,in:s),side=object.slot%2==0 ? -1.0:1.0
        return .init(x:p.x-side*42,y:p.y)
    }
    private func point(_ slot:Int,in s:CGSize)->CGPoint {
        let p=ReefCove.objectPoint(slot,in:area,width:s.width,height:s.height)
        return .init(x:p.x,y:p.y)
    }

    private func exitPositions(in s:CGSize)->[String:ReefPoint] {
        ReefCove.exitLayout(from:area,exits:exits,width:s.width,height:s.height-bottomInset,contentHeight:s.height)
    }
    private func exitButton(_ destination:FirstReef.Destination)->some View {
        let known=progress.visited?.contains(destination.id)==true
        return Button {arrivalFrom=freeSpot(at:Date());selectedID=nil;onVisit(destination)} label:{
            VStack(spacing:2) {
                Image(systemName:"arrow.up").font(.system(size:18,weight:.bold))
                    .rotationEffect(.radians(ReefCove.exitBearing(to:destination,from:area)))
                    .frame(width:42,height:36).background(SeaGlassShape().fill(ReefTheme.glass.opacity(0.93)))
                Text(known ? ReefQuestView.areaName(destination.id):"Explore").reefFont(size:10,weight:.semibold).multilineTextAlignment(.center).lineLimit(2)
                    .padding(.horizontal,10).padding(.vertical,5).background(MembraneShape().fill(ReefTheme.glass.opacity(0.95)))
            }.frame(width:92,height:78)
        }.buttonStyle(ReefButtonStyle(kind:.navigation)).disabled(!enabled)
            .accessibilityLabel(known ? "Swim to \(ReefQuestView.areaName(destination.id))":"Explore a new area")
            .accessibilityHint("Swim \(ReefCove.exitDirectionName(to:destination,from:area)) on the map")
    }
}
private struct CoveCoralPlant {var x:Double;var y:Double;var size:Double;var species:Int;var opacity:Double;var seed:Double;var restored:Double}
private struct CoveFishPose {var point:CGPoint;var size:Double;var inflation:Double;var chew:Double;var facing:Double}


/// Presentation only: contents come from the same authored loot that the store grants.
/// No inventory mutation or randomness occurs while drawing a chest.
enum ReefTreasureArt {
    struct Prize {
        let item: ReefDiscovery
        var count = 1
        var label:String {
            let unit:String = switch item {
            case .glow:"Lumes"
            case .snack:count == 1 ? "coral garden":"coral gardens"
            case .hint:count == 1 ? "hint":"hints"
            case .futureTeller:count == 1 ? "Future Teller":"Future Tellers"
            case .life:count == 1 ? "life":"lives"
            case .lighter:count == 1 ? "lighter":"lighters"
            case .shot:count == 1 ? "shot":"shots"
            case .current:count == 1 ? "current changer":"current changers"
            case .bouncyBlock:count == 1 ? "bouncy block":"bouncy blocks"
            case .currentAdder:count == 1 ? "current adder":"current adders"
            case .instantBoost:"15-min boost"
            case .storedBoost:"saved 15-min boost"
            }
            return "\(count) \(unit)"
        }
    }

    static func rewards(for node: FirstReef.Destination) -> [Prize] {
        let loot=node.loot
        var result:[Prize]=[]
        if loot.hints>0 {result.append(.init(item:.hint,count:loot.hints))}
        if loot.lives>0 {result.append(.init(item:.life,count:loot.lives))}
        if loot.lighters>0 {result.append(.init(item:.lighter,count:loot.lighters))}
        if loot.instantBoost {result.append(.init(item:.instantBoost))}
        return result
    }

    static func rewards(for object: ReefCove.Object) -> [Prize] {
        switch object.find {
        case .treasure: rewards(for:FirstReef.node(object.area))
        case .hint: [.init(item:.hint)]
        case .lives: [.init(item:.life,count:2)]
        case .lighter: [.init(item:.lighter)]
        default: []
        }
    }

    // Legacy garden receipts retain their serialized discovery key.
    static func contents(for object:ReefCove.Object,in progress:FirstReefProgress?=nil)->[Prize] {
        if progress?.legacyGolfFinds?.contains(object.id) == true { return [] }
        if let item=progress?.clearingRewards?[object.id] {return item.isGolfSupply ? [] : [.init(item:item)]}
        return object.find == .food ? [.init(item:.snack)] : rewards(for:object)
    }

    static func clusterOffsets(count:Int)->[CGPoint] {
        switch min(5,max(0,count)) {
        case 0:[]
        case 1:[.zero]
        case 2:[.init(x:-0.24,y:0.10),.init(x:0.24,y:-0.10)]
        case 3:[.init(x:0,y:-0.26),.init(x:-0.28,y:0.20),.init(x:0.28,y:0.20)]
        case 4:[.init(x:-0.27,y:-0.25),.init(x:0.27,y:-0.25),.init(x:-0.27,y:0.25),.init(x:0.27,y:0.25)]
        default:[.init(x:0,y:-0.40),.init(x:-0.32,y:-0.04),.init(x:0.32,y:-0.04),.init(x:-0.23,y:0.36),.init(x:0.23,y:0.36)]
        }
    }

    static func cluster(_ prize:Prize,in context:GraphicsContext,at center:CGPoint,size:Double,elapsed:Double?=nil) {
        let offsets=clusterOffsets(count:prize.count)
        for (copy,offset) in offsets.enumerated() {
            let t=elapsed.map{max(0,min(1,($0-Double(copy)*0.045)/0.60))} ?? 1
            let settle=t*t*(3-2*t)
            let scale=offsets.count>1 ? 0.77:1.0
            let iconSize=size*scale*(0.85+0.15*settle)
            let point=CGPoint(x:center.x+offset.x*size*settle,y:center.y+offset.y*size*settle+(1-settle)*size*0.30)
            var c=context;c.opacity *= min(1,t*6)
            if prize.item == .snack {
                TrailArt.draw(.food,in:c,at:point,size:iconSize)
            } else {
                c.translateBy(x:point.x-iconSize/2,y:point.y-iconSize/2)
                c.scaleBy(x:iconSize/100,y:iconSize/100)
                for layer in ReefPowerupArt.layers(prize.item.icon) {
                    if let fill=layer.fill {c.fill(layer.path,with:.color(fill))}
                    if let stroke=layer.stroke {c.stroke(layer.path,with:.color(stroke),style:.init(lineWidth:layer.width,lineCap:.round,lineJoin:.round))}
                }
            }
        }
    }

    /// nil elapsed is the settled pose (also used on maps and with Reduce Motion).
    static func draw(_ prizes:[Prize],in context:GraphicsContext,at center:CGPoint,chestSize:Double,elapsed:Double?=nil) {
        guard !prizes.isEmpty else{return}
        if let elapsed, elapsed<0 {return}
        let iconSize=chestSize*(prizes.count>2 ? 0.28:0.37)
        for (i,prize) in prizes.enumerated() {
            let delay=Double(i)*0.10
            let t=elapsed.map{max(0,min(1,($0-delay)/0.75))} ?? 1
            let rise=t*t*(3-2*t)
            let spread=(Double(i)-Double(prizes.count-1)/2)*iconSize*1.48
            let x=center.x+spread*(0.55+0.45*rise)
            let y=center.y-chestSize*(0.06+0.40*rise)-sin(t * .pi)*chestSize*0.04
            cluster(prize,in:context,at:.init(x:x,y:y),size:iconSize*(0.6+0.4*rise),elapsed:elapsed.map{$0-delay})
        }
        if let elapsed { bubbles(in:context,at:center,chestSize:chestSize,elapsed:elapsed) }
    }

    static func bubbles(in context:GraphicsContext,at center:CGPoint,chestSize:Double,elapsed:Double) {
        guard elapsed>=0,elapsed<1.55 else{return}
        // Brief hollow bubbles escape from the opening; no coin-like filled discs.
        for i in 0..<9 {
            let t=(elapsed-Double(i)*0.055)/1.05
            guard t>0,t<1 else{continue}
            let spread=Double((i*7)%9-4)/4
            let x=center.x+spread*chestSize*(0.13+0.21*t)+sin(t*5+Double(i))*chestSize*0.025
            let y=center.y-chestSize*(0.02+t*(0.65+Double(i%3)*0.09))
            let radius=chestSize*(0.021+Double(i%3)*0.008)*(0.7+0.3*t)
            let rect=CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2)
            var bubble=context;bubble.opacity=min(1,t*8)*min(1,(1-t)*4)
            bubble.fill(Path(ellipseIn:rect),with:.color(ReefTheme.cyan.opacity(0.06)))
            bubble.stroke(Path(ellipseIn:rect),with:.color(ReefTheme.glint.opacity(0.86)),lineWidth:max(0.8,chestSize*0.009))
            var shine=Path();shine.addArc(center:.init(x:x,y:y),radius:radius*0.63,startAngle:.degrees(205),endAngle:.degrees(270),clockwise:false)
            bubble.stroke(shine,with:.color(ReefTheme.glint),style:.init(lineWidth:max(0.7,chestSize*0.008),lineCap:.round))
        }
    }
}

/// Shared clump for the read-only treasure receipt; the exact count is beside it.
struct ReefTreasureCluster:View {
    let prize:ReefTreasureArt.Prize
    var body:some View {
        Canvas {c,s in
            ReefTreasureArt.cluster(prize,in:c,at:.init(x:s.width/2,y:s.height/2),size:min(s.width,s.height)*0.72)
        }
    }
}
