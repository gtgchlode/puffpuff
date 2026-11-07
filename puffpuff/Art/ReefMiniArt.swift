import SwiftUI

/// Small native vector arenas using the official Affinity fish and kelp.
enum ReefMiniArt {
    static func draw(kind:ReefMiniKind,layout:Int=0,frame:ReefMiniFrame,in c:GraphicsContext,time:Double,shells:[ReefPoint],pull:ReefPoint?,won:Bool,releaseCharge:Double=0,currents:[PlacedReefCurrent]=[],blocks:[PlacedBouncyBlock]=[]) {
        let bounds=CGRect(x:0,y:0,width:340,height:500)
        let water=SeaGlassShape(seed:3,amplitude:0.006).path(in:bounds.insetBy(dx:-10,dy:-12))
        c.fill(water,with:.color(ReefTheme.deep.opacity(0.18)))
        if kind == .kelp {
            let route=ReefMiniChallenge.route(layout)
            var line=Path();line.move(to:point(route[0]))
            for p in route.dropFirst() {line.addLine(to:point(p))}
            let channel=line.strokedPath(.init(lineWidth:120,lineCap:.round,lineJoin:.round))
            var forest=Path(bounds);forest.addPath(channel)
            var plants=c;plants.clip(to:forest,style:.init(eoFill:true))
            plants.fill(Path(bounds),with:.color(Color(hex:0x306D5D).opacity(0.55)))
            for y in stride(from:35,through:500,by:85) {
                for x in stride(from:25,through:340,by:90) {
                    TrailArt.draw(.kelpForest,in:plants,at:.init(x:x,y:y),size:125,time:time)
                }
            }
            c.stroke(line,with:.color(ReefTheme.honey),style:.init(lineWidth:124,lineCap:.round,lineJoin:.round))
            c.stroke(line,with:.color(ReefTheme.glass),style:.init(lineWidth:120,lineCap:.round,lineJoin:.round))
            let home=point(route.last!)
            c.fill(Path(ellipseIn:.init(x:home.x-22,y:home.y-18,width:44,height:36)),with:.color(Color(hex:0x123C40)))
            c.stroke(Path(ellipseIn:.init(x:home.x-23,y:home.y-19,width:46,height:38)),with:.color(ReefTheme.honey),lineWidth:4)
            var flag=Path();flag.move(to:.init(x:home.x+13,y:home.y));flag.addLine(to:.init(x:home.x+13,y:home.y-39))
            c.stroke(flag,with:.color(ReefTheme.ink),style:.init(lineWidth:2,lineCap:.round))
            var cloth=Path();cloth.move(to:.init(x:home.x+13,y:home.y-39));cloth.addQuadCurve(to:.init(x:home.x+34,y:home.y-29),control:.init(x:home.x+27,y:home.y-43));cloth.addLine(to:.init(x:home.x+13,y:home.y-24));cloth.closeSubpath()
            c.fill(cloth,with:.color(ReefTheme.coral))
            aids(in:c,currents:currents,blocks:blocks)
        } else {
            let rim=Path(roundedRect:CGRect(x:18,y:20,width:304,height:462),cornerRadius:50)
            c.stroke(rim,with:.color(ReefTheme.honey.opacity(0.65)),lineWidth:7)
            goal(in:c,front:false)
            aids(in:c,currents:currents,blocks:blocks)
            for enemy in frame.enemies {
                let entering=frame.captureProgress[enemy.id] ?? (enemy.captured ? 1:0)
                let p=enemy.captured && enemy.position==ReefMiniChallenge.prison ? ReefMiniChallenge.goalSeat(enemy.id):enemy.position
                TrailArt.drawEnemy(in:c,at:point(p),size:40-12*entering,index:enemy.id,time:time)
            }
            goal(in:c,front:true)
        }
        for p in shells {shell(in:c,at:p)}
        if let pull {
            var aim=Path();aim.move(to:point(frame.position));aim.addLine(to:point(frame.position+pull*0.8))
            c.stroke(aim,with:.color(ReefTheme.gold),style:.init(lineWidth:2.5,lineCap:.round,dash:[4,5]))
            var tether=Path();tether.move(to:point(frame.position));tether.addLine(to:point(frame.position-pull))
            c.stroke(tether,with:.color(ReefTheme.coral),style:.init(lineWidth:2,lineCap:.round))
        }
        let charge=pull.map{min(1,$0.length/110)} ?? releaseCharge
        let size=won && kind == .kelp ? 22.0:46.0+charge*34
        var fish=c;fish.translateBy(x:frame.position.x-size*173/320,y:frame.position.y-size*0.85*144/270)
        PipRenderer.drawPose(in:fish,size:.init(width:size,height:size*0.85),time:time,inflation:0.05+charge*0.95,joy:won ? 1:0.3)
    }
    static func aids(in c:GraphicsContext,currents:[PlacedReefCurrent],blocks:[PlacedBouncyBlock]) {
        for current in currents {
            let center=current.position,d=BonusCourse.currentDirection(current.direction),side=ReefPoint(x:-d.y,y:d.x)
            c.fill(Path(ellipseIn:.init(x:center.x-25,y:center.y-25,width:50,height:50)),with:.color(ReefTheme.glint.opacity(0.25)))
            var arrow=Path();arrow.move(to:point(center-d*13));arrow.addLine(to:point(center+d*13))
            arrow.move(to:point(center+d*4+side*8));arrow.addLine(to:point(center+d*13));arrow.addLine(to:point(center+d*4-side*8))
            c.stroke(arrow,with:.color(ReefTheme.ink),style:.init(lineWidth:3,lineCap:.round,lineJoin:.round))
        }
        for block in blocks {ReefPowerupArt.drawBlock(in:c,at:block.position)}
    }
    static func point(_ p:ReefPoint)->CGPoint {.init(x:p.x,y:p.y)}
    // Exact paths from the editable Reef-Goal-v2 Affinity master.
    static func goal(in c:GraphicsContext,front:Bool) {
        for layer in goalLayers where layer.front == front {
            if let fill=layer.fill {c.fill(layer.path,with:.color(Color(hex:fill)))}
            if let stroke=layer.stroke {c.stroke(layer.path,with:.color(Color(hex:stroke)),style:.init(lineWidth:layer.width,lineCap:.round,lineJoin:.round))}
        }
    }
    static func shell(in c:GraphicsContext,at p:ReefPoint) {
        let shape=SeaGlassShape(seed:2,amplitude:0.015).path(in:.init(x:p.x-25,y:p.y-25,width:50,height:50))
        c.fill(shape,with:.color(Color(hex:0xF3B49B)));c.stroke(shape,with:.color(Color(hex:0x9D6D5D)),lineWidth:2)
        for dx in [-14.0,0,14] {
            var vein=Path();vein.move(to:.init(x:p.x,y:p.y+15));vein.addQuadCurve(to:.init(x:p.x+dx,y:p.y-16),control:.init(x:p.x+dx,y:p.y))
            c.stroke(vein,with:.color(Color(hex:0xFFE1B5)),style:.init(lineWidth:3,lineCap:.round))
        }
    }

    private struct GoalLayer {let path:Path;let fill:UInt32?;let stroke:UInt32?;let width:Double;let front:Bool}
    private static let goalLayers:[GoalLayer] = [
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:246,y:115)); p.addCurve(to:CGPoint(x:170,y:129),control1:CGPoint(x:246,y:122.731987),control2:CGPoint(x:211.973641,y:129)); p.addCurve(to:CGPoint(x:94,y:115),control1:CGPoint(x:128.026359,y:129),control2:CGPoint(x:94,y:122.731987)); p.addCurve(to:CGPoint(x:170,y:101),control1:CGPoint(x:94,y:107.268013),control2:CGPoint(x:128.026359,y:101)); p.addCurve(to:CGPoint(x:246,y:115),control1:CGPoint(x:211.973641,y:101),control2:CGPoint(x:246,y:107.268013)); p.closeSubpath() },fill:0x598C81,stroke:nil,width:0,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:111,y:110)); p.addCurve(to:CGPoint(x:102,y:49),control1:CGPoint(x:99,y:87),control2:CGPoint(x:98,y:68)); p.move(to:CGPoint(x:101,y:76)); p.addCurve(to:CGPoint(x:92,y:53),control1:CGPoint(x:91,y:69),control2:CGPoint(x:90,y:60)); p.move(to:CGPoint(x:102,y:64)); p.addCurve(to:CGPoint(x:109,y:43),control1:CGPoint(x:111,y:55),control2:CGPoint(x:111,y:49)) },fill:nil,stroke:0xEFA18D,width:9,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:102,y:101)); p.addCurve(to:CGPoint(x:102,y:51),control1:CGPoint(x:97,y:84),control2:CGPoint(x:98,y:65)) },fill:nil,stroke:0xF8CEAA,width:2.7,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:230,y:111)); p.addCurve(to:CGPoint(x:237,y:55),control1:CGPoint(x:238,y:91),control2:CGPoint(x:239,y:75)); p.move(to:CGPoint(x:238,y:84)); p.addCurve(to:CGPoint(x:247,y:61),control1:CGPoint(x:249,y:75),control2:CGPoint(x:248,y:66)); p.move(to:CGPoint(x:237,y:73)); p.addCurve(to:CGPoint(x:230,y:54),control1:CGPoint(x:230,y:68),control2:CGPoint(x:229,y:60)) },fill:nil,stroke:0x8FBEA6,width:8,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:232,y:104)); p.addCurve(to:CGPoint(x:237,y:58),control1:CGPoint(x:238,y:88),control2:CGPoint(x:237,y:70)) },fill:nil,stroke:0xDAE8C1,width:2.6,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:114,y:109)); p.addLine(to:CGPoint(x:114,y:50)); p.addLine(to:CGPoint(x:132,y:24)); p.addLine(to:CGPoint(x:208,y:24)); p.addLine(to:CGPoint(x:226,y:50)); p.addLine(to:CGPoint(x:226,y:109)); p.addCurve(to:CGPoint(x:114,y:109),control1:CGPoint(x:188.666667,y:117.666667),control2:CGPoint(x:151.333333,y:117.666667)); p.closeSubpath() },fill:0x123B42,stroke:0x42776E,width:3,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:124,y:99)); p.addLine(to:CGPoint(x:124,y:53)); p.addLine(to:CGPoint(x:137,y:34)); p.addLine(to:CGPoint(x:203,y:34)); p.addLine(to:CGPoint(x:216,y:53)); p.addLine(to:CGPoint(x:216,y:99)); p.addCurve(to:CGPoint(x:124,y:99),control1:CGPoint(x:185.333333,y:107.666667),control2:CGPoint(x:154.666667,y:107.666667)); p.closeSubpath() },fill:0x1B535A,stroke:nil,width:0,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:206,y:58)); p.addCurve(to:CGPoint(x:170,y:81),control1:CGPoint(x:206,y:70.7025493),control2:CGPoint(x:189.882251,y:81)); p.addCurve(to:CGPoint(x:134,y:58),control1:CGPoint(x:150.117749,y:81),control2:CGPoint(x:134,y:70.7025493)); p.addCurve(to:CGPoint(x:170,y:35),control1:CGPoint(x:134,y:45.2974507),control2:CGPoint(x:150.117749,y:35)); p.addCurve(to:CGPoint(x:206,y:58),control1:CGPoint(x:189.882251,y:35),control2:CGPoint(x:206,y:45.2974507)); p.closeSubpath() },fill:0x0C2D35,stroke:nil,width:0,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:139,y:116)); p.addCurve(to:CGPoint(x:201,y:116),control1:CGPoint(x:159.666667,y:108),control2:CGPoint(x:180.333333,y:108)); p.addLine(to:CGPoint(x:191,y:82)); p.addCurve(to:CGPoint(x:149,y:82),control1:CGPoint(x:177,y:76),control2:CGPoint(x:163,y:76)); p.closeSubpath() },fill:0x448C8A,stroke:nil,width:0,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:150,y:104)); p.addCurve(to:CGPoint(x:190,y:104),control1:CGPoint(x:163.333333,y:100),control2:CGPoint(x:176.666667,y:100)); p.move(to:CGPoint(x:155,y:93)); p.addCurve(to:CGPoint(x:185,y:93),control1:CGPoint(x:165,y:89),control2:CGPoint(x:175,y:89)) },fill:nil,stroke:0x9BCFC1,width:2,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:130,y:106)); p.addLine(to:CGPoint(x:114,y:106)); p.addLine(to:CGPoint(x:114,y:50)); p.addLine(to:CGPoint(x:132,y:24)); p.addLine(to:CGPoint(x:208,y:24)); p.addLine(to:CGPoint(x:226,y:50)); p.addLine(to:CGPoint(x:226,y:106)); p.addLine(to:CGPoint(x:210,y:106)) },fill:nil,stroke:0x42776E,width:15,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:130,y:106)); p.addLine(to:CGPoint(x:114,y:106)); p.addLine(to:CGPoint(x:114,y:50)); p.addLine(to:CGPoint(x:132,y:24)); p.addLine(to:CGPoint(x:208,y:24)); p.addLine(to:CGPoint(x:226,y:50)); p.addLine(to:CGPoint(x:226,y:106)); p.addLine(to:CGPoint(x:210,y:106)) },fill:nil,stroke:0xDF9D87,width:11,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:130,y:102)); p.addLine(to:CGPoint(x:118,y:102)); p.addLine(to:CGPoint(x:118,y:51)); p.addLine(to:CGPoint(x:135,y:28)); p.addLine(to:CGPoint(x:205,y:28)); p.addLine(to:CGPoint(x:222,y:51)); p.addLine(to:CGPoint(x:222,y:102)); p.addLine(to:CGPoint(x:211,y:102)) },fill:nil,stroke:0xFFE1AE,width:3,front:false),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:147,y:34)); p.addCurve(to:CGPoint(x:148,y:57),control1:CGPoint(x:145.666667,y:40.6666667),control2:CGPoint(x:146,y:48.3333333)) },fill:nil,stroke:0x96BBA7,width:4,front:true),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:169,y:34)); p.addCurve(to:CGPoint(x:170,y:58),control1:CGPoint(x:167.666667,y:41.3333333),control2:CGPoint(x:168,y:49.3333333)) },fill:nil,stroke:0x96BBA7,width:4,front:true),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:191,y:34)); p.addCurve(to:CGPoint(x:192,y:57),control1:CGPoint(x:189.666667,y:40.6666667),control2:CGPoint(x:190,y:48.3333333)) },fill:nil,stroke:0x96BBA7,width:4,front:true),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:159,y:22)); p.addCurve(to:CGPoint(x:156,y:8),control1:CGPoint(x:153.666667,y:14.6666667),control2:CGPoint(x:152.666667,y:10)); p.addCurve(to:CGPoint(x:170,y:14),control1:CGPoint(x:161.333333,y:6),control2:CGPoint(x:166,y:8)); p.addCurve(to:CGPoint(x:183,y:8),control1:CGPoint(x:174,y:8),control2:CGPoint(x:178.333333,y:6)); p.addCurve(to:CGPoint(x:179,y:22),control1:CGPoint(x:186.333333,y:11.3333333),control2:CGPoint(x:185,y:16)); p.closeSubpath() },fill:0xF1C879,stroke:0x8D865C,width:2,front:true),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:170,y:20)); p.addLine(to:CGPoint(x:170,y:13)); p.move(to:CGPoint(x:168,y:19)); p.addLine(to:CGPoint(x:160,y:12)); p.move(to:CGPoint(x:173,y:19)); p.addLine(to:CGPoint(x:180,y:12)) },fill:nil,stroke:0xFFE7B2,width:1.5,front:true),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:119,y:119)); p.addCurve(to:CGPoint(x:110,y:123),control1:CGPoint(x:119,y:121.209139),control2:CGPoint(x:114.970563,y:123)); p.addCurve(to:CGPoint(x:101,y:119),control1:CGPoint(x:105.029437,y:123),control2:CGPoint(x:101,y:121.209139)); p.addCurve(to:CGPoint(x:110,y:115),control1:CGPoint(x:101,y:116.790861),control2:CGPoint(x:105.029437,y:115)); p.addCurve(to:CGPoint(x:119,y:119),control1:CGPoint(x:114.970563,y:115),control2:CGPoint(x:119,y:116.790861)); p.closeSubpath() },fill:0xE9CB91,stroke:0x42776E,width:1.5,front:true),
        GoalLayer(path:Path { p in p.move(to:CGPoint(x:234,y:117)); p.addCurve(to:CGPoint(x:227,y:120),control1:CGPoint(x:234,y:118.656854),control2:CGPoint(x:230.865993,y:120)); p.addCurve(to:CGPoint(x:220,y:117),control1:CGPoint(x:223.134007,y:120),control2:CGPoint(x:220,y:118.656854)); p.addCurve(to:CGPoint(x:227,y:114),control1:CGPoint(x:220,y:115.343146),control2:CGPoint(x:223.134007,y:114)); p.addCurve(to:CGPoint(x:234,y:117),control1:CGPoint(x:230.865993,y:114),control2:CGPoint(x:234,y:115.343146)); p.closeSubpath() },fill:0xA9CBB0,stroke:0x42776E,width:1.5,front:true),
    ]
}
