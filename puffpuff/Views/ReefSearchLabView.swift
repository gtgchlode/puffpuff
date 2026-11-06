#if DEBUG
import SwiftUI

struct ReefSearchLabView:View {
    @Bindable var game:ReefSearchLab
    let onGolf:(Int)->Void
    @State private var sideArea:Int?=0
    @Environment(\.oceanTime) private var time
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View {
        VStack(spacing:12) {
            Text("\(game.kind.id+1). \(game.kind.name)").reefFont(size:23,weight:.semibold,display:true)
            Text(game.instruction).reefFont(size:13).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            HStack(spacing:16) {
                ReefIconLabel("\(game.glow)",.glow,size:21)
                Label("\(game.foods)/3",systemImage:"leaf.fill")
                Label("\(game.finds)/3",systemImage:"gift.fill")
                Spacer()
                Button("Reset") {game.reset();sideArea=0}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }.reefFont(size:13,weight:.semibold)
            if game.kind == .fog || game.kind == .garden || game.kind == .hunt {sprawlingReef}
            else if game.kind == .side {sideReef}
            else if game.kind == .dive {depthReef}
            else if game.kind == .hub && game.area == -1 {homeHub}
            else {room(max(0,game.area))}
            if !game.message.isEmpty {
                HStack(spacing:7) {
                    if let spot=game.lastSpot,game.cleared.contains(spot) {
                        if spot%4 == 1 {ReefIcon([.hint,.life,.lighter][spot/4],size:28)}
                        else {Image(systemName:spot%4 == 0 ? "leaf.fill":"sun.max.fill")}
                    }
                    Text(game.message)
                }.reefFont(size:14,weight:.semibold).foregroundStyle(ReefTheme.ink)
                    .id("\(game.lastSpot ?? -1)-\(game.message)")
                    .transition(.opacity.combined(with:.offset(y:10)))
            }
            if game.kind == .coves {
                HStack {
                    if game.area>0 {Button("Previous cove") {game.visit(game.area-1)}.buttonStyle(ReefButtonStyle(kind:.quiet))}
                    Spacer()
                    if game.area<2,game.opened.contains(game.area+1) {
                        Button("Swim onward") {game.visit(game.area+1)}.buttonStyle(ReefButtonStyle(kind:.action))
                    }
                }
            } else if game.kind == .hub,game.area>=0 {
                Button("Back to cottage") {game.visit(-1)}.buttonStyle(ReefButtonStyle(kind:.quiet))
            } else if game.kind == .current {
                Button("Ride the current") {game.flowOn()}.buttonStyle(ReefButtonStyle(kind:.action))
                    .disabled(!game.cleared.contains(game.area*4+3))
                Text("Pocket \(game.area+1) · loop \(game.loops+1)").reefFont(size:12).foregroundStyle(ReefTheme.muted)
            }
            HStack {
                Button("Bloom · +8 trial Glow") {game.refill()}.buttonStyle(ReefButtonStyle(kind:.quiet))
                if game.foods == 3,!game.won {
                    Button("Go home") {game.home()}.buttonStyle(ReefButtonStyle(kind:.action))
                }
            }
            if game.won {
                Text("\(game.finds)/3 golf advantages found").reefFont(size:14,weight:.semibold)
                Button("Try these finds in golf") {onGolf(game.finds)}.buttonStyle(ReefButtonStyle(kind:.action))
            }
        }.padding(.horizontal,6)
            .animation(reduceMotion ? nil:.easeInOut(duration:0.35),value:game.cleared)
    }
    private func room(_ area:Int)->some View {
        VStack(spacing:4) {
            Text(game.areaNames[area]).reefFont(size:17,weight:.semibold)
            GeometryReader {g in
                let scale=g.size.width/320
                ZStack(alignment:.topLeading) {
                    SearchReefBackdrop(area:area,light:Double(game.cleared.filter{$0/4 == area}.count)/4)
                    ForEach(0..<4) {slot in
                        let points=[CGPoint(x:80,y:95),CGPoint(x:236,y:155),CGPoint(x:85,y:275),CGPoint(x:238,y:340)]
                        spot(area*4+slot,width:132*scale)
                            .position(x:points[slot].x*scale,y:points[slot].y*scale)
                    }
                    fish(at:.init(x:155*scale,y:230*scale),size:70*scale)
                }
            }.aspectRatio(320.0/435,contentMode:.fit)
        }
    }
    private var sideReef:some View {
        VStack(spacing:10) {
          GeometryReader {g in
            ScrollView(.horizontal) {
                HStack(spacing:16) {
                    ForEach(0..<3) {area in
                        VStack(spacing:4) {
                            if game.opened.contains(area) {room(area)}
                            else {lockedArea(area).frame(height:g.size.width*1.36)}
                            Text("\(area+1) / 3").reefFont(size:12).foregroundStyle(ReefTheme.muted)
                        }.frame(width:g.size.width).id(area)
                    }
                }.scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned).scrollPosition(id:$sideArea).scrollIndicators(.visible)
          }.aspectRatio(320.0/475,contentMode:.fit)
          HStack {
              ForEach(0..<3) {area in
                  Button(["Kelp","Shells","Coral"][area]) {withAnimation {sideArea=area}}
                      .buttonStyle(ReefButtonStyle(kind:.quiet))
                      .disabled(!game.opened.contains(area))
              }
          }
        }
    }
    private var depthReef:some View {
        VStack(spacing:18) {
            ForEach(0..<3) {area in
                if game.opened.contains(area) {
                    HStack {
                        Text(["Sunlit shelf","Twilight shelf","Deep shelf"][area]).reefFont(size:17,weight:.semibold)
                        Spacer();Text("\((area+1)*10) m").reefFont(size:12)
                    }
                    room(area)
                } else {
                    lockedArea(area).frame(height:115)
                }
            }
        }
    }
    private var homeHub:some View {
        VStack(spacing:10) {
            Canvas {c,s in CoralHomeArt.draw(in:c,at:CGPoint(x:s.width/2,y:145),scale:0.65,open:true)}.frame(height:175)
            ForEach(0..<3) {area in
                Button {game.visit(area)} label: {
                    HStack(spacing:10) {
                        Canvas {c,s in TrailArt.draw([.kelpForest,.sandpit,.enemySchool][area],in:c,at:CGPoint(x:s.width/2,y:s.height/2),size:s.width,time:reduceMotion ? 0:time)}
                            .frame(width:105,height:90)
                        VStack(alignment:.leading,spacing:7) {
                            Text(game.areaNames[area]).reefFont(size:16,weight:.semibold)
                            Text("\(game.cleared.filter{$0/4 == area}.count)/4 uncovered").reefFont(size:12)
                        }
                        Spacer()
                    }.padding(.horizontal,10).background(SearchReefBackdrop(area:area,light:0.25))
                }.buttonStyle(ReefButtonStyle(kind:.navigation))
            }
        }
    }
    private var sprawlingReef:some View {
        GeometryReader {g in
            let scale=g.size.width/320
            let garden=game.kind == .garden,hunt=game.kind == .hunt
            ZStack(alignment:.topLeading) {
                SearchReefBackdrop(area:garden ? 0:2,light:Double(game.cleared.count)/12)
                Canvas {c,_ in
                    var world=c;world.scaleBy(x:scale,y:scale)
                    if !hunt {
                        for id in 1..<12 {
                            let previous=id%4 == 0 ? id-1:id/4*4
                            if game.cleared.contains(previous) {
                                LabSketch.line([mapPoint(previous),mapPoint(id)],in:world,color:ReefTheme.glint.opacity(0.45),dashed:true)
                            }
                        }
                    }
                    LabSketch.fish(in:world,at:.init(x:160,y:garden ? 35:25),charged:0,happy:false)
                }.allowsHitTesting(false)
                ForEach(0..<12) {id in
                    let p=mapPoint(id),available=game.available(id)
                    spot(id,width:(garden ? 100:120)*scale,small:garden)
                        .position(x:p.x*scale,y:p.y*scale)
                        .opacity(available || hunt ? 1:garden ? 0.55:0.18)
                }
            }
        }.aspectRatio(320.0/(game.kind == .garden ? 650:1000),contentMode:.fit)
    }
    private func mapPoint(_ id:Int)->ReefPoint {
        if game.kind == .garden {
            return .init(x:[65.0,160,255][id%3],y:105+Double(id/3)*155+Double(id%3 == 1 ? 20:0))
        }
        return .init(x:id%2 == 0 ? 85:235,y:95+Double(id/2)*160+Double(id%2)*28)
    }
    private func lockedArea(_ area:Int)->some View {
        ZStack {
            SearchReefBackdrop(area:area,light:0)
            VStack(spacing:5) {
                Image(systemName:"water.waves").font(.system(size:24))
                Text(game.kind == .side ? "Clear the previous passage":"Open the passage above").reefFont(size:13)
            }.foregroundStyle(ReefTheme.glint)
        }.clipShape(MembraneShape())
    }
    private func fish(at point:CGPoint,size:Double)->some View {
        Canvas {c,s in
            var world=c;world.scaleBy(x:size/42,y:size/42)
            LabSketch.fish(in:world,at:.init(x:21,y:18),charged:0,happy:game.won)
        }.frame(width:size,height:size).position(point).allowsHitTesting(false).accessibilityHidden(true)
    }
    private func spot(_ id:Int,width:Double,small:Bool=false)->some View {
        let node=SearchSpot(id:id),clear=game.cleared.contains(id)
        let hidden=game.kind == .hunt && !game.scanned.contains(id),ready=game.available(id)
        let title=clear ? (node.slot == 0 ? "Found":node.slot == 1 ? "Opened":node.slot == 2 ? "Lit":"Open"):
            hidden ? "Scan · 1":!ready ? "Unexplored":"\(node.action) · \(node.cost)"
        return Button {game.uncover(id)} label: {
            VStack(spacing:0) {
                ZStack {
                    if clear {
                        SeaGlassShape(seed:Double(id)).fill(ReefTheme.glint.opacity(0.2)).blur(radius:9)
                        if node.slot == 2 {CoralArt(species:CoralSpecies.allCases[node.area],lit:true)}
                        else {
                            Canvas {c,s in
                                if node.slot == 3 {
                                    if node.area == 2 {CoralHomeArt.draw(in:c,at:CGPoint(x:s.width/2,y:s.height*0.78),scale:s.width/310,open:true)}
                                    else {
                                        LabSketch.line([.init(x:s.width*0.2,y:s.height*0.65),.init(x:s.width*0.5,y:s.height*0.45),.init(x:s.width*0.8,y:s.height*0.55)],in:c,color:ReefTheme.glint,dashed:true)
                                        TrailArt.draw(.food,in:c,at:CGPoint(x:s.width*0.55,y:s.height*0.55),size:30)
                                    }
                                } else {
                                    let asset:TrailArt.Asset=node.slot == 0 ? .food:[.chestMintOpen,.chestCoralOpen,.chestGoldOpen][node.area]
                                    TrailArt.draw(asset,in:c,at:CGPoint(x:s.width/2,y:s.height/2),size:s.width*0.9)
                                }
                            }
                        }
                    } else {
                        Canvas {c,s in
                            var art=c
                            art.opacity=hidden ? 0.25:ready ? 1:0.45
                            TrailArt.draw([.kelpForest,.sandpit,.enemySchool][node.barrier],in:art,at:CGPoint(x:s.width/2,y:s.height/2),size:s.width,time:reduceMotion ? 0:time)
                            if hidden || !ready {
                                c.fill(SeaGlassShape(seed:Double(id)).path(in:CGRect(x:0,y:8,width:s.width,height:s.height-12)),with:.color(ReefTheme.abyss.opacity(hidden ? 0.62:0.25)))
                            }
                        }
                        if hidden {Image(systemName:"sparkle").foregroundStyle(ReefTheme.glint.opacity(0.6))}
                    }
                }.frame(width:width,height:width*(small ? 0.8:0.88))
                Text(title).reefFont(size:small ? 10:12,weight:.semibold)
                    .foregroundStyle(clear ? ReefTheme.ink:ReefTheme.glint)
                    .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                    .padding(.horizontal,10).padding(.vertical,6)
                    .background(SeaGlassShape(seed:Double(id)).fill(clear ? ReefTheme.glass.opacity(0.8):ReefTheme.abyss.opacity(0.85)))
            }.frame(width:width).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!ready).allowsHitTesting(!clear)
            .accessibilityLabel(clear ? "\(title), place \(id+1)":hidden ? "Scan hiding place \(id+1), 1 Glow":"\(node.action), \(node.cost) Glow, place \(id+1)")
    }
}

private struct SearchReefBackdrop:View {
    let area:Int
    let light:Double
    @Environment(\.oceanTime) private var time
    var body:some View {
        GeometryReader {g in
            ZStack {
                LinearGradient(colors:[Color(hex:[0x2B7169,0x397880,0x17454F][area]),ReefTheme.abyss],startPoint:.topLeading,endPoint:.bottomTrailing)
                Canvas {c,s in
                    let rect=CGRect(origin:.zero,size:s)
                    for i in 0..<5 {
                        var ray=Path();ray.move(to:.init(x:s.width*Double(i)/4,y:0))
                        ray.addLine(to:.init(x:s.width*(Double(i)-0.7)/4,y:s.height))
                        ray.addLine(to:.init(x:s.width*(Double(i)+0.4)/4,y:s.height));ray.closeSubpath()
                        c.fill(ray,with:.color(ReefTheme.glint.opacity(0.025+light*0.045)))
                    }
                    let sand=Path(ellipseIn:CGRect(x:-s.width*0.3,y:s.height*0.7,width:s.width*1.6,height:s.height*0.5))
                    c.fill(sand,with:.color(ReefTheme.sand.opacity(0.12+light*0.3)))
                    for i in 0..<14 {
                        let x=WaterDrawing.seed(i,salt:Double(area)+8)*s.width,y=WaterDrawing.seed(i,salt:3)*s.height
                        c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:2,height:2)),with:.color(ReefTheme.glint.opacity(0.35)))
                    }
                    c.stroke(MembraneShape().path(in:rect),with:.color(ReefTheme.glint.opacity(0.22)),lineWidth:1)
                }
                ForEach(0..<4) {i in
                    CoralArt(species:CoralSpecies.allCases[(i+area)%3],lit:light>0.1,seed:Double(i))
                        .frame(width:g.size.width*0.22,height:g.size.width*0.25)
                        .opacity(0.25+light*0.5)
                        .position(x:i%2 == 0 ? g.size.width*0.06:g.size.width*0.94,y:g.size.height*(0.17+Double(i)*0.23))
                }
            }.clipShape(MembraneShape())
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
#endif
