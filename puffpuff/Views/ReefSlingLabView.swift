#if DEBUG
import SwiftUI

struct ReefSlingLabView:View {
    @Bindable var game:SlingLab
    @State private var pull:ReefPoint?
    @State private var placing=false
    @State private var showBonuses=false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View {
        VStack(spacing:12) {
            Text("\(game.kind.id+1). \(game.kind.name)").reefFont(size:23,weight:.semibold,display:true)
            Text(game.kind.instruction).reefFont(size:13).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            HStack {
                Text("Trail finds").reefFont(size:13)
                ForEach(0..<4) {amount in
                    Button {game.explore(amount);pull=nil;placing=false} label: {
                        Text("\(amount)/3").reefFont(size:12,weight:.semibold).frame(minWidth:36,minHeight:36)
                            .background(SeaGlassShape(seed:Double(amount)).fill(game.finds == amount ? ReefTheme.honey.opacity(0.6):ReefTheme.glass.opacity(0.4)))
                    }.buttonStyle(ReefButtonStyle(kind:.navigation)).disabled(game.moving)
                }
            }
            HStack {
                Text("\(game.shots)/4 shots").reefFont(size:13,weight:.semibold)
                Spacer()
                Button("Bonuses") {showBonuses.toggle()}.buttonStyle(ReefButtonStyle(kind:.quiet))
                Button("Retry") {game.reset();pull=nil;placing=false}.buttonStyle(ReefButtonStyle(kind:.quiet))
            }.frame(maxWidth:350)
            if showBonuses {
                Text("1: 12 Glow + hint + lighter\n2: 8 Glow + hint · 3: 5 Glow · 4: 2 Glow\nMiss home: no bonus. Collect one best set.")
                    .reefFont(size:12).multilineTextAlignment(.center)
            }
            board.aspectRatio(0.75,contentMode:.fit).frame(maxWidth:300)
            controls
            if game.won {
                Text(game.reward).reefFont(size:15,weight:.semibold).foregroundStyle(ReefTheme.gold)
                Button(game.collected ? "Collected in this trial":"Collect trial bonuses") {game.collect()}
                    .buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.collected)
            } else if !game.message.isEmpty {Text(game.message).reefFont(size:13)}
            Text(game.kind.advantage).reefFont(size:13).foregroundStyle(ReefTheme.muted)
                .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
        }.padding(.horizontal,6)
    }
    private var board:some View {
        GeometryReader {geometry in
            let scale=geometry.size.width/300
            ZStack(alignment:.topLeading) {
                Canvas {c,_ in
                    var world=c;world.scaleBy(x:scale,y:scale)
                    LabSketch.course(in:world)
                    if game.kind == .fork {
                        for side in 1...2 {
                            LabSketch.line([game.tee,game.jets[0],game.jets[side],game.home],in:world,
                                           color:ReefTheme.cyan.opacity((game.rightFork ? 2:1) == side ? 0.6:0.18),dashed:true)
                        }
                    }
                    if game.kind == .dial {
                        let route=game.jets+[game.home]
                        for i in 0..<game.finds {LabSketch.line([route[i],route[i+1]],in:world,color:ReefTheme.gold.opacity(0.6),dashed:true)}
                    }
                    if game.kind == .landing {
                        let p=game.brakePoint,r=game.brakeRadius
                        world.fill(LabSketch.circle(p,r),with:.color(ReefTheme.honey.opacity(0.24)))
                        var spiral=Path()
                        for n in 0...65 {
                            let a=Double(n)*0.19,rr=4+Double(n)/65*(r-5)
                            let point=CGPoint(x:p.x+cos(a)*rr,y:p.y+sin(a)*rr)
                            if n == 0 {spiral.move(to:point)}else{spiral.addLine(to:point)}
                        }
                        world.stroke(spiral,with:.color(ReefTheme.gold.opacity(0.7)),lineWidth:1.5)
                    }
                    for i in game.jets.indices {
                        let p=game.jets[i],dir=game.direction(i),on=game.active(i)
                        world.fill(LabSketch.circle(p,game.radius),with:.color(ReefTheme.cyan.opacity(on ? 0.24:0.06)))
                        world.stroke(LabSketch.circle(p,game.radius),with:.color(ReefTheme.glint.opacity(on ? 0.8:0.2)),style:.init(lineWidth:1,dash:[2,4]))
                        for n in 0..<3 {
                            let t=((reduceMotion ? 0:game.clock)*0.6+Double(n)/3).truncatingRemainder(dividingBy:1)
                            let q=p+dir*((t-0.5)*game.radius*2)
                            let side=ReefPoint(x:-dir.y,y:dir.x)
                            LabSketch.line([q-dir*4+side*4,q,q-dir*4-side*4],in:world,color:ReefTheme.glint.opacity(on ? 0.8:0.15),dashed:false)
                        }
                    }
                    for (i,p) in game.blockers.enumerated() {LabSketch.obstacle(i,in:world,at:p,size:42)}
                    LabSketch.line(game.trail,in:world,color:ReefTheme.gold.opacity(0.35),dashed:true)
                    LabSketch.home(in:world,at:game.home)
                    if let pull {
                        let vector=game.ball-pull
                        LabSketch.line([pull,game.ball],in:world,color:ReefTheme.coral,dashed:false)
                        LabSketch.line([game.ball,game.ball+vector],in:world,color:ReefTheme.gold,dashed:true)
                        world.stroke(LabSketch.circle(pull,5),with:.color(ReefTheme.coral),lineWidth:2)
                    }
                    LabSketch.fish(in:world,at:game.ball,charged:pull == nil ? 0.05:min(1,(game.ball-pull!).length/100),happy:game.won)
                }.allowsHitTesting(false)
                if placing {
                    Color.clear.contentShape(Rectangle()).gesture(SpatialTapGesture().onEnded {value in
                        game.place(.init(x:value.location.x/scale,y:value.location.y/scale))
                        if game.message.isEmpty {placing=false}
                    })
                }
                ForEach(game.jets.indices,id:\.self) {i in
                    let dir=game.direction(i)
                    let angle=atan2(dir.y,dir.x)*180/Double.pi+90
                    Button {game.turn(i)} label: {
                        Image(systemName:"arrow.up").font(.system(size:19,weight:.bold))
                            .rotationEffect(.degrees(angle)).frame(width:40,height:40)
                            .foregroundStyle(game.active(i) ? ReefTheme.ink:ReefTheme.muted)
                            .background(SeaGlassShape(seed:Double(i)).fill(game.kind == .relay && i<game.finds ? ReefTheme.honey:ReefTheme.glass))
                    }.buttonStyle(.plain).position(x:game.jets[i].x*scale,y:game.jets[i].y*scale)
                        .allowsHitTesting(!placing && !game.moving && !game.ended && ![.dial,.fork,.live].contains(game.kind) && !(game.kind == .relay && i<game.finds))
                        .accessibilityLabel("Turn current \(i+1)")
                }
                if !game.moving,!game.ended,!placing {
                    Color.clear.frame(width:60,height:60).contentShape(Rectangle())
                        .position(x:game.ball.x*scale,y:game.ball.y*scale)
                        .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("sling-trial-board"))
                            .onChanged {value in pull = .init(x:value.location.x/scale,y:value.location.y/scale)}
                            .onEnded {value in
                                let start=ReefPoint(x:value.startLocation.x/scale,y:value.startLocation.y/scale)
                                let end=ReefPoint(x:value.location.x/scale,y:value.location.y/scale)
                                game.launch(start-end);pull=nil
                            })
                }
            }
        }.coordinateSpace(name:"sling-trial-board")
    }
    @ViewBuilder private var controls:some View {
        switch game.kind {
        case .fork:
            Button(game.rightFork ? "Right stream ↔":"Left stream ↔") {game.chooseFork()}
                .buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.moving || game.ended)
        case .dial,.live:
            Button("Turn currents ↻") {game.turnDial()}.buttonStyle(ReefButtonStyle(kind:.action))
                .disabled(game.won || game.collected || game.ended && !game.moving || game.kind == .dial && game.moving)
        case .pocket:
            Button(placing ? "Cancel placement":"Move current") {placing.toggle()}
                .buttonStyle(ReefButtonStyle(kind:.action)).disabled(game.moving || game.ended)
            if placing {Text("Tap open water").reefFont(size:12)}
        case .pulse:
            HStack(spacing:12) {
                ForEach(0..<3) {i in
                    Label("\(i+1)",systemImage:game.active(i) ? "water.waves":"moon")
                        .foregroundStyle(game.active(i) ? ReefTheme.ink:ReefTheme.muted)
                }
            }.reefFont(size:12)
        default:EmptyView()
        }
    }
}
#endif
