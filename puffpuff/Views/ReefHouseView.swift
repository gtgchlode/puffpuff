import SwiftUI

/// The room camera and swimming are presentation state; owned furniture arrangements save atomically.
struct ReefHouseView:View {
    @Environment(ReefStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inside=false
    @State private var entering=false
    @State private var approaching=false
    @State private var decorating=false
    @State private var showShop=false
    @State private var shopLockedNotice=false
    @State private var selected:ReefHomeItem?
    @State private var moving:ReefHomeItem?
    @State private var draft:ReefHomePlacement?
    @State private var notice:String?
    @State private var camera=HouseCamera(center:.init(x:0.5,y:0.56),zoom:1.45)
    @State private var cameraFrom=HouseCamera()
    @State private var cameraBegan=Date.distantPast
    @State private var cameraDuration=0.0
    @State private var panStart:HouseCamera?
    @State private var pinchStart:HouseCamera?
    @State private var swimFrom=ReefPoint(x:0.50,y:0.73)
    @State private var swimTo=ReefPoint(x:0.50,y:0.73)
    @State private var swimBegan=Date()
    @State private var swimDuration=0.0
    @State private var lastTouch=Date()
    @State private var facing=1.0
    @State private var activity:ReefHomeItem?
    @State private var idleStep=0
    private var owned:Set<String> {store.progress.firstReef.homeDecorations ?? []}
    private var room:ReefHomeRoom {store.progress.firstReef.furnishedRoom}

    var body:some View {
        GeometryReader { viewport in
            OceanScene {
                VStack(spacing:8) {
                    header
                    if inside {areas}
                    GeometryReader {g in
                        TimelineView(.animation(minimumInterval:1.0/30,paused:reduceMotion || scenePhase != .active)) { clock in
                            if inside {roomScene(size:g.size,now:clock.date)}
                            else {exterior(size:g.size,time:animationTime(clock.date))}
                        }
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                }
            }
            .overlay(alignment:.bottom) {
                if shopLockedNotice {
                    Text("Finish The Faded Garden to open the shop.").reefFont(size:15)
                        .multilineTextAlignment(.center).padding(18)
                        .background(ReefTheme.glass.opacity(0.96)).padding(16)
                        .onTapGesture {shopLockedNotice=false}
                }
            }
            .safeAreaInset(edge:.bottom,spacing:0) {
                if inside && (decorating || selected != nil || moving != nil) {
                    furnitureTray(maxHeight:min(300,max(150,viewport.size.height*0.37)))
                }
            }
        }
        #if os(macOS)
        .frame(minWidth:420,idealWidth:520,minHeight:650,idealHeight:760)
        #endif
        .foregroundStyle(ReefTheme.ink)
        .onChange(of:scenePhase) {_,phase in if phase != .active {settleSwim();lastTouch=Date()} }
        .onChange(of:reduceMotion) {_,_ in settleSwim()}
        .task(id:entering) {
            guard entering else{return}
            do {
                try await Task.sleep(for:.seconds(reduceMotion ? 0.01:0.85))
                guard !Task.isCancelled else{return}
                inside=true;entering=false;approaching=false
                swimFrom = .init(x:0.50,y:0.79);swimTo=swimFrom
                swim(to:.init(x:0.50,y:0.64))
            } catch {}
        }
        .task(id:shopLockedNotice) {
            guard shopLockedNotice else{return}
            do {try await Task.sleep(for:.seconds(5));guard !Task.isCancelled else{return};shopLockedNotice=false} catch {}
        }
        .task(id:inside) {
            guard inside else{return}
            while !Task.isCancelled {
                do {try await Task.sleep(for:.seconds(4))} catch {return}
                guard scenePhase == .active,!reduceMotion,!decorating,selected == nil,moving == nil,
                      activity != .shellSeat,Date().timeIntervalSince(lastTouch)>7 else {continue}
                let stops=[ReefPoint(x:-0.12,y:0.06),.init(x:0.11,y:-0.04),.init(x:0.07,y:0.10),.init(x:-0.08,y:-0.08)]
                let offset=stops[idleStep%stops.count];idleStep+=1
                swim(to:HouseCamera.swimPoint(camera.center+offset),touch:false)
            }
        }
    }

    private var header:some View {
        HStack(spacing:12) {
            Button(action:enterOrLeave) {HouseControlIcon(inside ? .leaveHome:.enterHome)}
                .accessibilityLabel(inside ? "Leave the house":"Enter the house").disabled(entering)
            Spacer(minLength:4)
            if inside {
                Button {toggleShelf(shop:false)} label: {HouseControlIcon(.homeFurniture)}
                    .accessibilityLabel("Your furniture").accessibilityAddTraits(decorating && !showShop ? .isSelected:[])
                Button {toggleShelf(shop:true)} label: {
                    HouseControlIcon(.homeShop).saturation(store.isHomeShopUnlocked ? 1:0)
                        .opacity(store.isHomeShopUnlocked ? 1:0.55)
                        .overlay(alignment:.bottomTrailing) {
                            if !store.isHomeShopUnlocked {Image(systemName:"lock.fill").font(.system(size:13,weight:.bold)).foregroundStyle(ReefTheme.ink)}
                        }
                }.accessibilityLabel(store.isHomeShopUnlocked ? "Furniture shop":"Furniture shop, locked until World 1 is complete")
            }
            ReefTrailReturnButton(progress:store.progress.firstReef) {dismiss()}
                .accessibilityHint("Return to your reef")
        }.buttonStyle(ReefButtonStyle(kind:.quiet)).padding(.horizontal,16).padding(.top,14)
            .accessibilityElement(children:.contain).accessibilityLabel("PuffPuff’s house")
    }
    private var areas:some View {
        HStack(spacing:5) {
            areaButton(.roomOverview,"Whole room",center:.init(x:0.5,y:0.5),zoom:1)
            areaButton(.roomWindow,"Window",center:.init(x:0.25,y:0.48),zoom:1.85)
            Button {focus(.init(x:0.51,y:0.64),zoom:1.85)} label: {RescueFriendView(asset:.shellSeat).frame(width:36,height:36)}
                .accessibilityLabel("View the nook")
            Button {focus(.init(x:0.78,y:0.56),zoom:1.85)} label: {CoralArt(species:.rosyFan,lit:true).frame(width:34,height:34)}
                .accessibilityLabel("View the coral corner")
            Spacer(minLength:0)
            Button {setZoom(camera.zoom/1.3)} label: {Image(systemName:"minus.magnifyingglass").frame(width:24,height:30)}
                .accessibilityLabel("Zoom out").disabled(camera.zoom<=1.01)
            Button {setZoom(camera.zoom*1.3)} label: {Image(systemName:"plus.magnifyingglass").frame(width:24,height:30)}
                .accessibilityLabel("Zoom in").disabled(camera.zoom>=2.39)
        }.buttonStyle(ReefButtonStyle(kind:.quiet)).padding(.horizontal,16)
    }
    private func areaButton(_ asset:RescueArt.Asset,_ title:String,center:ReefPoint,zoom:Double)->some View {
        Button {focus(center,zoom:zoom)} label: {HouseControlIcon(asset,size:34)}
            .accessibilityLabel("View \(title.lowercased())")
    }
    private func toggleShelf(shop:Bool) {
        lastTouch=Date();selected=nil;moving=nil;draft=nil;notice=nil
        if shop && !store.isHomeShopUnlocked {shopLockedNotice=true;return}
        decorating = !(decorating && showShop==shop)
        showShop=shop;shopLockedNotice=false
    }

    private func roomScene(size:CGSize,now:Date)->some View {
        let frame=visibleCamera(now).frame(size),fish=fishPosition(now),time=animationTime(now)
        return ZStack {
            Canvas {c,_ in
                var world=c;world.translateBy(x:frame.offset.x,y:frame.offset.y);world.scaleBy(x:frame.scale,y:frame.scale)
                HouseRoomArt.draw(in:world,time:time,lanternLit:room.lanternOn && room.placements[ReefHomeItem.pearlLantern.id] != nil)
                for item in ReefHomeItem.allCases {
                    if let placement=displayPlacement(item) {
                        let center=HouseCamera.world(placement.position)
                        if item == .pearlLantern && room.lanternOn {HouseRoomArt.lampGlow(in:world,at:center,flipped:placement.flipped)}
                        var furniture=world
                        if moving == item {furniture.opacity=room.canPlace(item,at:placement.position) ? 0.82:0.42}
                        draw(item,in:furniture,at:center,size:260,time:time,flipped:placement.flipped)
                        if item == .pearlLantern && !room.lanternOn {
                            let p=CGPoint(x:center.x+(placement.flipped ? -27:27),y:center.y-17)
                            world.fill(Path(ellipseIn:.init(x:p.x-16,y:p.y-20,width:32,height:40)),with:.color(ReefTheme.deep.opacity(0.6)))
                        }
                        if moving == item {
                            let color=room.canPlace(item,at:placement.position) ? ReefTheme.cyan:ReefTheme.coral
                            world.stroke(Path(ellipseIn:.init(x:center.x-100,y:center.y+65,width:200,height:32)),with:.color(color),style:.init(lineWidth:5,dash:[5,8]))
                        }
                        if activity == .coralPlanter && item == .coralPlanter {
                            let t=now.timeIntervalSince(swimBegan)-swimDuration
                            if (0...2).contains(t) {ReefTreasureArt.bubbles(in:world,at:center,chestSize:180,elapsed:t*0.7)}
                        }
                    }
                }
                if selected != nil,!owned.contains(selected!.id),let item=selected {
                    var ghost=world;ghost.opacity=0.65
                    draw(item,in:ghost,at:HouseCamera.world(item.homePosition),size:260,time:time)
                }
                let elapsed=now.timeIntervalSince(swimBegan)
                if elapsed<swimDuration && !reduceMotion {
                    let p=HouseCamera.world(fish)
                    for i in 0..<4 {
                        let r=Double(3+i),x=p.x-facing*Double(52+i*20),y=p.y+Double(i*5)
                        world.stroke(Path(ellipseIn:.init(x:x,y:y,width:r*2,height:r*2)),with:.color(ReefTheme.glint.opacity(0.65-Double(i)*0.1)),lineWidth:2)
                    }
                }
            }.allowsHitTesting(false).accessibilityHidden(true)
            Color.clear.contentShape(Rectangle())
                .onTapGesture {p in
                    lastTouch=Date();notice=nil;shopLockedNotice=false
                    let target=frame.normalized(p)
                    if moving != nil {draft?.position=ReefHomeRoom.clamped(target)}
                    else {selected=nil;swim(to:HouseCamera.swimPoint(target))}
                }
                .accessibilityLabel(moving == nil ? "Tap the room to swim. Drag to look around.":"Tap to place furniture.")
            ForEach(ReefHomeItem.allCases) {item in
                if let placement=displayPlacement(item),moving == nil {
                    Button {selected=item;notice=nil;lastTouch=Date()} label: {
                        Color.clear.frame(width:max(44,180*frame.scale),height:max(44,200*frame.scale)).contentShape(Ellipse())
                    }.buttonStyle(.plain).position(frame.screen(placement.position))
                        .accessibilityLabel(item.title).accessibilityHint("Show furniture actions")
                }
            }
            PipPoseArtwork(inflation:0,joy:1,time:time)
                .frame(width:190*frame.scale,height:160*frame.scale)
                .scaleEffect(x:facing,y:1)
                .position(frame.screen(fish))
                .allowsHitTesting(false).accessibilityLabel("PuffPuff swimming at home")
        }
        .clipped()
        .gesture(DragGesture(minimumDistance:8)
            .onChanged {value in
                lastTouch=Date()
                if moving != nil {draft?.position=ReefHomeRoom.clamped(frame.normalized(value.location));return}
                if panStart == nil {camera=visibleCamera(Date());cameraDuration=0;panStart=camera}
                if let origin=panStart {
                    let scale=origin.frame(size).scale
                    camera.center = .init(x:origin.center.x-value.translation.width/(1000*scale),y:origin.center.y-value.translation.height/(820*scale))
                    camera=camera.clamped(size)
                }
            }.onEnded {_ in panStart=nil})
        .simultaneousGesture(MagnifyGesture()
            .onChanged {value in
                guard moving == nil else{return};lastTouch=Date()
                if pinchStart == nil {camera=visibleCamera(Date());cameraDuration=0;pinchStart=camera}
                if let start=pinchStart {camera.zoom=min(2.4,max(1,start.zoom*value.magnification));camera=camera.clamped(size)}
            }.onEnded {_ in pinchStart=nil})
    }
    private func displayPlacement(_ item:ReefHomeItem)->ReefHomePlacement? {
        moving == item ? draft:room.placements[item.id]
    }
    private func furnitureTray(maxHeight:Double)->some View {
        ScrollView {
            VStack(spacing:12) {
                if let moving,let draft {
                    HStack {
                        Text(moving.title).reefFont(size:18,weight:.semibold)
                        Spacer()
                        Button {self.moving=nil;self.draft=nil;notice=nil} label: {Image(systemName:"xmark").frame(width:30,height:30)}.accessibilityLabel("Cancel placement")
                    }
                    Text("Tap or drag to place.").reefFont(size:14)
                    HStack(spacing:12) {
                        Button {self.draft?.flipped.toggle()} label: {Image(systemName:"arrow.left.arrow.right").frame(width:34,height:30)}.accessibilityLabel("Flip furniture")
                        Button {commitPlacement(moving,draft)} label: {Image(systemName:"checkmark").frame(width:40,height:30)}
                            .accessibilityLabel("Place furniture")
                            .buttonStyle(ReefButtonStyle(kind:.action))
                            .disabled(!room.canPlace(moving,at:draft.position))
                    }
                    if !room.canPlace(moving,at:draft.position) {Text("A little more room here.").reefFont(size:14)}
                } else if let item=selected {
                    itemActions(item)
                } else {
                    HStack {
                        if showShop {ReefIconLabel("\(store.progress.glow)",.glow,size:24).reefFont(size:17,weight:.semibold)}
                        Spacer()
                        Button {decorating=false;notice=nil} label: {Image(systemName:"xmark").frame(width:30,height:30)}
                            .accessibilityLabel("Close furniture")
                    }
                    let items=ReefHomeItem.allCases.filter {showShop ? !owned.contains($0.id):owned.contains($0.id)}
                    if items.isEmpty {
                        HouseControlIcon(showShop ? .homeShop:.homeFurniture,size:54).opacity(0.45)
                            .accessibilityLabel(showShop ? "You own everything in this shop":"No furniture yet")
                    } else {
                        LazyVGrid(columns:[GridItem(.adaptive(minimum:84))],spacing:12) {
                            ForEach(items) {item in
                                Button {selected=item;notice=nil;lastTouch=Date();focus((room.placements[item.id]?.position ?? item.homePosition),zoom:1.5)} label: {
                                    VStack(spacing:4) {
                                        decoration(item).frame(width:74,height:74)
                                        if showShop {ReefIconLabel("\(item.cost)",.glow,size:20)}
                                    }.frame(maxWidth:.infinity).padding(6)
                                }.buttonStyle(.plain).accessibilityLabel(owned.contains(item.id) ? item.title+", owned":item.title+", \(item.cost) Lumes")
                            }
                        }
                    }
                }
                if let notice {Text(notice).reefFont(size:14).multilineTextAlignment(.center)}
            }.padding(.horizontal,22).padding(.vertical,16).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.frame(maxHeight:maxHeight).fixedSize(horizontal:false,vertical:true)
            .background(ReefTheme.glass.opacity(0.97))
            .overlay(alignment:.top) {TideDivider(tint:ReefTheme.cyan).allowsHitTesting(false)}
            .buttonStyle(ReefButtonStyle(kind:.navigation))
    }
    private func itemActions(_ item:ReefHomeItem)->some View {
        VStack(spacing:12) {
            HStack {
                decoration(item).frame(width:48,height:48)
                Text(item.title).reefFont(size:19,weight:.semibold)
                Spacer()
                Button {selected=nil;notice=nil} label: {Image(systemName:"xmark").frame(width:30,height:30)}.accessibilityLabel("Close furniture actions")
            }
            if owned.contains(item.id) {
                if let placement=room.placements[item.id] {
                    HStack(spacing:12) {
                        Button {use(item,at:placement.position)} label: {
                            Image(systemName:item == .shellSeat ? "zzz":item == .pearlLantern ? "power":"hand.tap").frame(width:34,height:30)
                        }.buttonStyle(ReefButtonStyle(kind:.action))
                            .accessibilityLabel(item == .pearlLantern ? (room.lanternOn ? "Turn lantern off":"Turn lantern on"):item.useTitle)
                        Button {beginMove(item)} label: {Image(systemName:"arrow.up.and.down.and.arrow.left.and.right").frame(width:34,height:30)}.accessibilityLabel("Move furniture")
                        Button {
                            var changed=placement;changed.flipped.toggle()
                            if !store.arrangeHomeItem(item,placement:changed) {notice="Couldn't save. Try again."}
                        } label: {Image(systemName:"arrow.left.arrow.right").frame(width:34,height:30)}.accessibilityLabel("Flip furniture")
                    }
                    Button {
                        if store.arrangeHomeItem(item,placement:nil) {selected=nil;activity=nil}
                        else {notice="Couldn't save. Try again."}
                    } label: {HouseControlIcon(.homeFurniture,size:34)}
                        .buttonStyle(ReefButtonStyle(kind:.quiet)).accessibilityLabel("Put furniture away")
                } else {
                    Button {beginMove(item)} label: {Image(systemName:"arrow.down.to.line").frame(width:36,height:30)}
                        .buttonStyle(ReefButtonStyle(kind:.action)).accessibilityLabel("Place furniture")
                }
            } else {
                Button {
                    guard store.progress.glow>=item.cost else {notice="Play Glow for more Lumes.";return}
                    if store.buyHomeItem(item) {beginMove(item)}
                    else {notice="Couldn't save. Try again."}
                } label: {ReefIconLabel("\(item.cost)",.glow,size:25).frame(maxWidth:.infinity)}
                    .buttonStyle(ReefButtonStyle(kind:.action)).accessibilityLabel("Buy \(item.title) for \(item.cost) Lumes")
            }
        }
    }
    private func beginMove(_ item:ReefHomeItem) {
        guard owned.contains(item.id) else{return}
        moving=item;decorating=true;notice=nil;activity=nil
        draft=room.placements[item.id] ?? .init(position:room.firstSpace(for:item) ?? item.homePosition)
        focus(draft!.position,zoom:1.4)
    }
    private func commitPlacement(_ item:ReefHomeItem,_ placement:ReefHomePlacement) {
        if store.arrangeHomeItem(item,placement:placement) {moving=nil;draft=nil;selected=item;notice=nil}
        else {notice="Couldn't place it. Try again."}
    }
    private func use(_ item:ReefHomeItem,at point:ReefPoint) {
        lastTouch=Date();notice=nil
        if item == .pearlLantern && !store.setHomeLantern(!room.lanternOn) {notice="Couldn't save. Try again.";return}
        var target=point
        if item == .shellSeat {target.y+=0.025}
        else {target.x-=0.10;target.y+=0.035}
        swim(to:target);activity=item;selected=nil;decorating=false
    }
    private func draw(_ item:ReefHomeItem,in c:GraphicsContext,at p:CGPoint,size:Double,time:Double,flipped:Bool=false) {
        switch item {
        case .shellSeat:RescueArt.draw(.shellSeat,in:c,at:p,size:size,moving:false,facing:flipped ? -1:1)
        case .pearlLantern:RescueArt.draw(.pearlLantern,in:c,at:p,size:size,moving:false,facing:flipped ? -1:1)
        case .coralPlanter:
            var c=c;c.translateBy(x:p.x,y:p.y);c.scaleBy(x:flipped ? -1:1,y:1)
            ReefQuestArt.coral(.rosyFan,in:c,at:.init(x:0,y:0),size:size*0.64,time:time,seed:2,moving:!reduceMotion,light:1)
        }
    }
    @ViewBuilder private func decoration(_ item:ReefHomeItem)->some View {
        switch item {
        case .shellSeat:RescueFriendView(asset:.shellSeat)
        case .pearlLantern:RescueFriendView(asset:.pearlLantern)
        case .coralPlanter:CoralArt(species:.rosyFan,lit:true)
        }
    }
    private func fishPosition(_ now:Date)->ReefPoint {
        let t=swimDuration>0 ? min(1,max(0,now.timeIntervalSince(swimBegan)/swimDuration)):1
        let eased=t*t*(3-2*t)
        var p=swimFrom+(swimTo-swimFrom)*eased
        if !reduceMotion {p.y-=sin(t * .pi)*0.025}
        return p
    }
    private func swim(to target:ReefPoint,touch:Bool=true) {
        let now=Date(),from=fishPosition(now)
        swimFrom=from;swimTo=HouseCamera.swimPoint(target);swimBegan=now
        swimDuration=reduceMotion ? 0:max(0.65,min(2.8,(swimTo-from).length*5))
        if abs(swimTo.x-from.x)>0.01 {facing=swimTo.x>from.x ? 1:-1}
        activity=nil;if touch {lastTouch=now}
    }
    private func settleSwim() {let p=fishPosition(Date());swimFrom=p;swimTo=p;swimDuration=0;activity=nil}
    private func animationTime(_ now:Date)->Double {reduceMotion ? 0:now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy:48)*1000}
    private func focus(_ center:ReefPoint,zoom:Double) {
        lastTouch=Date()
        cameraFrom=visibleCamera(Date());cameraBegan=Date();cameraDuration=reduceMotion ? 0:0.45
        camera = .init(center:center,zoom:zoom)
    }
    private func visibleCamera(_ now:Date)->HouseCamera {
        if reduceMotion {return camera}
        let t=cameraDuration>0 ? min(1,max(0,now.timeIntervalSince(cameraBegan)/cameraDuration)):1
        let e=t*t*(3-2*t)
        return .init(center:cameraFrom.center+(camera.center-cameraFrom.center)*e,zoom:cameraFrom.zoom+(camera.zoom-cameraFrom.zoom)*e)
    }
    private func setZoom(_ zoom:Double) {focus(camera.center,zoom:min(2.4,max(1,zoom)))}
    private func enterOrLeave() {
        guard !entering else{return}
        selected=nil;moving=nil;draft=nil;decorating=false;notice=nil
        if inside {inside=false;approaching=false;settleSwim()}
        else {entering=true;withAnimation(reduceMotion ? nil:.easeInOut(duration:0.8)) {approaching=true}}
    }
    private func exterior(size:CGSize,time:Double)->some View {
        let width=min(size.width,480.0),height=size.height
        return ZStack {
            Canvas {c,_ in CoralHomeArt.draw(in:c,at:.init(x:size.width/2,y:height*0.70),scale:width/350,open:true)}
                .accessibilityHidden(true)
            PipPoseArtwork(inflation:0,joy:1,time:time).frame(width:96,height:81)
                .scaleEffect(approaching ? 0.32:1)
                .position(x:approaching ? size.width/2:size.width/2-width*0.28,y:height*(approaching ? 0.70:0.82))
                .accessibilityLabel("PuffPuff outside his coral house")
            Button(action:enterOrLeave) {Color.clear.frame(width:70,height:90).contentShape(Ellipse())}
                .buttonStyle(.plain).position(x:size.width/2,y:height*0.68).disabled(entering)
                .accessibilityLabel("Enter the house")
        }
    }
}

private struct HouseCamera {
    var center=ReefPoint(x:0.5,y:0.5)
    var zoom=1.0
    static func world(_ p:ReefPoint)->CGPoint {.init(x:p.x*1000,y:p.y*820)}
    static func swimPoint(_ p:ReefPoint)->ReefPoint {.init(x:min(0.90,max(0.10,p.x)),y:min(0.87,max(0.35,p.y)))}
    struct Frame {
        let scale:Double
        let offset:CGPoint
        func screen(_ p:ReefPoint)->CGPoint {.init(x:p.x*1000*scale+offset.x,y:p.y*820*scale+offset.y)}
        func normalized(_ p:CGPoint)->ReefPoint {.init(x:(p.x-offset.x)/(1000*scale),y:(p.y-offset.y)/(820*scale))}
    }
    func clamped(_ size:CGSize)->Self {
        let s=max(0.01,min(size.width/1000,size.height/820)*zoom)
        let hx=min(0.5,size.width/(2000*s)),hy=min(0.5,size.height/(1640*s))
        return .init(center:.init(x:min(1-hx,max(hx,center.x)),y:min(1-hy,max(hy,center.y))),zoom:zoom)
    }
    func frame(_ size:CGSize)->Frame {
        let bounded=clamped(size),s=max(0.01,min(size.width/1000,size.height/820)*zoom)
        return .init(scale:s,offset:.init(x:size.width/2-bounded.center.x*1000*s,y:size.height/2-bounded.center.y*820*s))
    }
}

private enum HouseRoomArt {
    static func draw(in c:GraphicsContext,time:Double,lanternLit:Bool) {
        var room=c;room.scaleBy(x:1,y:0.82)
        RescueArt.draw(.interior,in:room,at:.init(x:500,y:500),size:1000,moving:false)
        // Caustic ribbons and drifting light add life without adding objects to the room.
        for i in 0..<6 {
            let phase=time/14000 * .pi*2+Double(i),y=340+Double(i)*63
            var line=Path();line.move(to:.init(x:100,y:y))
            line.addCurve(to:.init(x:910,y:y+12),control1:.init(x:330,y:y-22+sin(phase)*10),control2:.init(x:670,y:y+30))
            c.stroke(line,with:.color(ReefTheme.glint.opacity(0.12)),style:.init(lineWidth:3,lineCap:.round))
        }
    }
    static func lampGlow(in c:GraphicsContext,at p:CGPoint,flipped:Bool) {
        let center=CGPoint(x:p.x+(flipped ? -25:25),y:p.y-20)
        c.fill(Path(ellipseIn:.init(x:center.x-150,y:center.y-160,width:300,height:320)),with:.radialGradient(Gradient(colors:[ReefTheme.gold.opacity(0.35),.clear]),center:center,startRadius:4,endRadius:160))
    }
}

private struct HouseControlIcon:View {
    let asset:RescueArt.Asset
    var size:Double=42
    init(_ asset:RescueArt.Asset,size:Double=42) {self.asset=asset;self.size=size}
    var body:some View {
        Canvas {c,s in RescueArt.draw(asset,in:c,at:.init(x:s.width/2,y:s.height/2),size:s.width,moving:false)}
            .frame(width:size,height:size).accessibilityHidden(true)
    }
}
