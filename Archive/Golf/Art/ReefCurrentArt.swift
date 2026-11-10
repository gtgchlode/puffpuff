// Matches Design/Powerups/Current-Changer.svg.
import SwiftUI
extension ReefPowerupArt {
    // An extra-current bubble uses the established Affinity swirl with a coral plus.
    static let currentAdder:[Layer] = current + [
        Layer(path:Path(ellipseIn:CGRect(x:35,y:35,width:30,height:30)),fill:Color(hex:0xF3AB8D),stroke:Color(hex:0x285951),width:2.5),
        Layer(path:{var p=Path();p.move(to:.init(x:42,y:50));p.addLine(to:.init(x:58,y:50));p.move(to:.init(x:50,y:42));p.addLine(to:.init(x:50,y:58));return p}(),fill:nil,stroke:Color(hex:0xFFF1C9),width:4)
    ]
    static let current:[Layer] = [
        Layer(path:{var p=Path();p.move(to:CGPoint(x:49,y:10));p.addCurve(to:CGPoint(x:88,y:52),control1:CGPoint(x:72,y:7),control2:CGPoint(x:92,y:28));p.addCurve(to:CGPoint(x:39,y:87),control1:CGPoint(x:85,y:76),control2:CGPoint(x:62,y:94));p.addCurve(to:CGPoint(x:14,y:37),control1:CGPoint(x:14,y:81),control2:CGPoint(x:7,y:58));p.addCurve(to:CGPoint(x:49,y:10),control1:CGPoint(x:20,y:21),control2:CGPoint(x:34,y:12));p.closeSubpath();return p}(),fill:Color(red:0.50196,green:0.79216,blue:0.73333),stroke:Color(red:0.15686,green:0.34902,blue:0.34118),width:3),
        Layer(path:{var p=Path();p.move(to:CGPoint(x:21,y:41));p.addCurve(to:CGPoint(x:59,y:22),control1:CGPoint(x:26,y:23),control2:CGPoint(x:45,y:17));return p}(),fill:nil,stroke:Color(red:1.00000,green:0.94510,blue:0.78824),width:5),
        Layer(path:{var p=Path();p.move(to:CGPoint(x:69,y:73));p.addQuadCurve(to:CGPoint(x:37,y:78),control:CGPoint(x:56,y:87));return p}(),fill:nil,stroke:Color(red:0.35686,green:0.66275,blue:0.61176),width:4),
        Layer(path:{var p=Path();p.move(to:CGPoint(x:29,y:55));p.addCurve(to:CGPoint(x:60,y:33),control1:CGPoint(x:21,y:35),control2:CGPoint(x:43,y:25));p.addCurve(to:CGPoint(x:58,y:62),control1:CGPoint(x:73,y:40),control2:CGPoint(x:70,y:58));p.addCurve(to:CGPoint(x:44,y:47),control1:CGPoint(x:44,y:67),control2:CGPoint(x:35,y:54));p.addQuadCurve(to:CGPoint(x:56,y:48),control:CGPoint(x:51,y:41));return p}(),fill:nil,stroke:Color(red:0.15686,green:0.34902,blue:0.34118),width:10),
        Layer(path:{var p=Path();p.move(to:CGPoint(x:29,y:55));p.addCurve(to:CGPoint(x:60,y:33),control1:CGPoint(x:21,y:35),control2:CGPoint(x:43,y:25));p.addCurve(to:CGPoint(x:58,y:62),control1:CGPoint(x:73,y:40),control2:CGPoint(x:70,y:58));p.addCurve(to:CGPoint(x:44,y:47),control1:CGPoint(x:44,y:67),control2:CGPoint(x:35,y:54));p.addQuadCurve(to:CGPoint(x:56,y:48),control:CGPoint(x:51,y:41));return p}(),fill:nil,stroke:Color(red:1.00000,green:0.94510,blue:0.78824),width:5),
        Layer(path:{var p=Path();p.move(to:CGPoint(x:65,y:18));p.addLine(to:CGPoint(x:83,y:26));p.addLine(to:CGPoint(x:67,y:39));p.addLine(to:CGPoint(x:69,y:29));p.closeSubpath();return p}(),fill:Color(red:0.95686,green:0.77647,blue:0.41961),stroke:Color(red:0.15686,green:0.34902,blue:0.34118),width:2.5),
        Layer(path:{var p=Path();p.move(to:CGPoint(x:23,y:63));p.addLine(to:CGPoint(x:38,y:74));p.addLine(to:CGPoint(x:20,y:81));p.addLine(to:CGPoint(x:24,y:72));p.closeSubpath();return p}(),fill:Color(red:0.95686,green:0.77647,blue:0.41961),stroke:Color(red:0.15686,green:0.34902,blue:0.34118),width:2.5),
    ]
}


extension ReefPowerupArt {
    // Matches Design/Powerups/Bouncy-Block.svg. Soft coral cushion, never an SF Symbol.
    static let bouncyBlock:[Layer] = [
        Layer(path:Path(ellipseIn:CGRect(x:13,y:82,width:74,height:10)),fill:Color(hex:0x619F92).opacity(0.5),stroke:nil,width:0),
        Layer(path:{var p=Path();p.move(to:.init(x:50,y:13));p.addCurve(to:.init(x:87,y:50),control1:.init(x:76,y:12),control2:.init(x:88,y:27));p.addCurve(to:.init(x:50,y:87),control1:.init(x:88,y:75),control2:.init(x:73,y:88));p.addCurve(to:.init(x:13,y:50),control1:.init(x:25,y:88),control2:.init(x:12,y:74));p.addCurve(to:.init(x:50,y:13),control1:.init(x:12,y:26),control2:.init(x:27,y:12));p.closeSubpath();return p}(),fill:Color(hex:0xEFA18D),stroke:Color(hex:0x42776E),width:3),
        Layer(path:{var p=Path();p.move(to:.init(x:23,y:45));p.addCurve(to:.init(x:62,y:23),control1:.init(x:23,y:27),control2:.init(x:40,y:20));return p}(),fill:nil,stroke:Color(hex:0xFFE1B5),width:5),
        Layer(path:{var p=Path();p.move(to:.init(x:74,y:53));p.addCurve(to:.init(x:48,y:77),control1:.init(x:75,y:70),control2:.init(x:64,y:79));return p}(),fill:nil,stroke:Color(hex:0xCD7C77),width:4),
        Layer(path:{var p=Path();p.move(to:.init(x:29,y:61));p.addLine(to:.init(x:49,y:40));p.addLine(to:.init(x:69,y:61));p.move(to:.init(x:49,y:40));p.addLine(to:.init(x:49,y:58));return p}(),fill:nil,stroke:Color(hex:0xFFF1C9),width:6)
    ]
    static func drawBlock(in context:GraphicsContext,at point:ReefPoint,size:Double=50) {
        var c=context;c.translateBy(x:point.x-size/2,y:point.y-size/2);c.scaleBy(x:size/100,y:size/100)
        for layer in bouncyBlock {
            if let fill=layer.fill {c.fill(layer.path,with:.color(fill))}
            if let stroke=layer.stroke {c.stroke(layer.path,with:.color(stroke),style:.init(lineWidth:layer.width,lineCap:.round,lineJoin:.round))}
        }
    }
}
