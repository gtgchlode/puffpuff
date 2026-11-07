import Foundation
import Observation

enum SlingTrial:Int,CaseIterable,Identifiable {
    case drift,relay,fork,dial,pocket,pulse,landing,live
    var id:Int {rawValue}
    var name:String {["Soft streams","Jet relay","Two ways home","One tide dial","Pocket current","Pulse tide","Soft landing","Live currents"][id]}
    var instruction:String {[
        "Turn the arrows. Pull Puff Puff back and release; streams bend his shot.",
        "Turn each jet, then sling into the first. Jets catch and send him onward.",
        "Pick the left or right stream, then sling into the fork.",
        "One dial turns all three currents. Set it, then sling.",
        "Place your current, turn its arrow, then sling through it.",
        "Turn the arrows, then time your sling. Jets work only while glowing.",
        "Turn the two jets and sling. The swirl near home softens the landing.",
        "Sling, then turn the currents while he swims. Watch the next arrow."
    ][id]}
    var advantage:String {[
        "Finds clear bumpers and widen the streams, making them easier to catch.",
        "Each find clears a bumper and sets one jet toward home.",
        "Finds clear the short right-hand route. Left stays open from the start.",
        "Finds reveal one route segment each and widen the currents.",
        "Finds clear bumpers and enlarge the current you can place.",
        "Finds keep the jets glowing longer and clear bumpers.",
        "Finds clear bumpers, widen home and enlarge the slowing swirl.",
        "Finds clear bumpers and slow the ride, giving you more time to turn."
    ][id]}
}

// Trial-only state. No real progress, inventory or reward transactions.
@Observable final class SlingLab {
    let kind:SlingTrial
    var finds=0
    var ball=ReefPoint(x:75,y:350)
    var velocity=ReefPoint(x:0,y:0)
    var arrows=[0,0,0]
    var dial=0
    var rightFork=false
    var pocket=ReefPoint(x:150,y:215)
    var clock=0.0
    var elapsed=0.0
    var shots=0
    var best:Int?
    var won=false
    var moving=false
    var collected=false
    var message=""
    var trail:[ReefPoint]=[]
    var fired:Set<Int>=[]
    var carrying:Int?
    var braked=false
    init(_ kind:SlingTrial) {self.kind=kind;reset(keepingBest:false)}
    var tee:ReefPoint {kind == .fork ? .init(x:150,y:350):.init(x:75,y:350)}
    var home:ReefPoint {kind == .fork ? .init(x:150,y:55):.init(x:225,y:60)}
    var ended:Bool {won || shots>=4 || collected}
    var holeRadius:Double {14+Double(finds)*(kind == .landing ? 3:1.5)}
    var radius:Double {kind == .pocket ? 27+Double(finds)*6:25+Double(finds)*3}
    var brakeRadius:Double {23+Double(finds)*9}
    var brakePoint:ReefPoint {.init(x:225,y:108)}
    var jets:[ReefPoint] {
        switch kind {
        case .drift:return [.init(x:100,y:275),.init(x:170,y:200),.init(x:225,y:130)]
        case .fork:return [.init(x:150,y:275),.init(x:65,y:190),.init(x:235,y:190)]
        case .pocket:return [pocket]
        case .landing:return [.init(x:75,y:265),.init(x:225,y:265)]
        default:return [.init(x:75,y:265),.init(x:225,y:265),.init(x:225,y:140)]
        }
    }
    var correct:[Int] {kind == .drift ? [0,2,0]:[2,0,0]}
    var blockers:[ReefPoint] {
        let points:[ReefPoint]
        if kind == .fork {points=[.init(x:193,y:232),.init(x:217,y:145),.init(x:183,y:108)]}
        else if kind == .drift || kind == .pocket {points=[.init(x:135,y:265),.init(x:185,y:180),.init(x:258,y:90)]}
        else {points=[.init(x:145,y:195),.init(x:150,y:315),.init(x:258,y:90)]}
        return Array(points.dropFirst(finds))
    }
    var pulseFraction:Double {0.44+Double(finds)*0.16}
    func active(_ index:Int)->Bool {
        kind != .pulse || ((clock/2.8+Double(index)*0.16).truncatingRemainder(dividingBy:1))<pulseFraction
    }
    func direction(_ index:Int)->ReefPoint {
        if kind == .fork {
            let destination=index == 0 ? jets[rightFork ? 2:1]:home
            let d=destination-jets[index];return d*(1/d.length)
        }
        let step:Int
        if kind == .dial {step=(correct[index]+dial*2)%8}
        else if kind == .live {step=([0,2,2][index]+dial*2)%8}
        else {step=arrows[index]}
        let a = -Double.pi/2+Double(step)*Double.pi/4
        return .init(x:cos(a),y:sin(a))
    }
    func turn(_ index:Int) {
        guard !moving,!ended,jets.indices.contains(index),kind != .fork,kind != .dial,kind != .live else{return}
        if kind == .relay && index<finds {return}
        arrows[index]=(arrows[index]+(kind == .pocket ? 1:2))%8
    }
    func turnDial() {
        guard !collected,!won,(!moving && shots<4) || kind == .live && moving else{return}
        dial=(dial+1)%4
    }
    func chooseFork() {guard !moving,!ended else{return};rightFork.toggle()}
    func place(_ point:ReefPoint) {
        guard kind == .pocket,!moving,!ended,point.x>=45,point.x<=255,point.y>=95,point.y<=305,
              (point-home).length>50,(point-ball).length>50,!blockers.contains(where:{($0-point).length<42}) else {message="Choose open water";return}
        pocket=point;message=""
    }
    func reset(keepingBest:Bool=true) {
        ball=tee;velocity = .init(x:0,y:0);shots=0;won=false;moving=false;collected=false
        fired=[];carrying=nil;braked=false;trail=[];elapsed=0;message="";clock=0
        arrows=kind == .relay ? [4,6,2]:correct
        dial=kind == .live || kind == .dial ? 1:0;rightFork=false;pocket = .init(x:150,y:215)
        if kind == .relay {for i in 0..<finds {arrows[i]=correct[i]}}
        if !keepingBest {best=nil}
    }
    func explore(_ amount:Int) {finds=max(0,min(3,amount));reset(keepingBest:false)}
    func launch(_ vector:ReefPoint) {
        guard !moving,!ended,vector.length>=5 else{return}
        velocity=vector*(1/vector.length)*(85+min(115,vector.length)*2.8)
        shots += 1;moving=true;elapsed=0;fired=[];carrying=nil;braked=false;trail=[ball];message=""
    }
    func finish(_ holed:Bool) {
        moving=false;carrying=nil;velocity = .init(x:0,y:0);won=holed
        if holed {ball=home;best=min(best ?? 99,shots);message="Home!"}
        else {message=shots>=4 ? "No bonus · try again":"Pull back for another shot"}
    }
    var reward:String {
        guard won else{return "No bonus · try again"}
        switch best ?? shots {
        case 1:return "12 Glow + hint + lighter"
        case 2:return "8 Glow + hint"
        case 3:return "5 Glow"
        default:return "2 Glow"
        }
    }
    func collect() {guard won,!moving,!collected,shots<=4 else{return};collected=true}
    func tick(_ dt:Double) {
        clock += dt
        guard moving else{return}
        // Every mode uses the same pull-and-release shot. Only the water differs.
        let timeScale=kind == .live ? 0.9-Double(finds)*0.14:1
        for _ in 0..<3 {
            let step=min(dt,1.0/20)/3*timeScale,previous=ball
            elapsed += step
            if let index=carrying {
                let delta=jets[index]-ball,distance=230*step
                if delta.length<=distance {
                    ball=jets[index];carrying=nil
                    velocity=direction(index)*(kind == .landing ? 180:200)
                } else {ball=ball+delta*(distance/delta.length)}
            } else {
                if kind == .drift {
                    for i in jets.indices where (ball-jets[i]).length<radius {
                        fired.insert(i)
                        let desired=direction(i)*200
                        velocity=velocity+(desired-velocity)*min(1,step*3.5)
                    }
                }
                ball=ball+velocity*step
                if ball.x<27 {ball.x=27;velocity.x=abs(velocity.x)*0.88}
                if ball.x>273 {ball.x=273;velocity.x = -abs(velocity.x)*0.88}
                if ball.y<27 {ball.y=27;velocity.y=abs(velocity.y)*0.88}
                if ball.y>373 {ball.y=373;velocity.y = -abs(velocity.y)*0.88}
                for obstacle in blockers {
                    let delta=ball-obstacle
                    if delta.length<24 {
                        let normal=delta*(1/max(0.01,delta.length));ball=obstacle+normal*24
                        if velocity.dot(normal)<0 {velocity=(velocity-normal*(2*velocity.dot(normal)))*0.83}
                    }
                }
                if kind != .drift {
                    for i in jets.indices where !fired.contains(i) && active(i) && (ball-jets[i]).length<radius {
                        fired.insert(i);carrying=i;break
                    }
                }
                if kind == .landing,!braked,(ball-brakePoint).length<brakeRadius {
                    let speed=velocity.length
                    let approach=sqrt(130*max(0,(ball-home).length-10))+8
                    velocity=velocity*(min(speed,max(speed*0.66,approach))/max(0.01,speed));braked=true
                }
                let speed=velocity.length
                velocity=velocity*(max(0,speed-65*step)/max(0.01,speed))
            }
            let delta=ball-previous
            let t=min(1,max(0,(home-previous).dot(delta)/max(0.001,delta.dot(delta))))
            if (home-(previous+delta*t)).length<holeRadius && velocity.length<300 {finish(true);return}
            if trail.isEmpty || (ball-trail.last!).length>4 {trail.append(ball)}
            if trail.count>240 {trail.removeFirst()}
            if carrying == nil && velocity.length<4 || elapsed>14 {finish(false);return}
        }
    }
}
