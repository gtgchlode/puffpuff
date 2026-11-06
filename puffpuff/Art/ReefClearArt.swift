// Matches Design/Trail/Reef-All-Clear.svg. Preserve later Affinity edits.
import SwiftUI

enum ReefClearArt {
    private struct Layer {let path:Path;let fill:Color?;let stroke:Color?;let width:Double}
    private static let sign:[Layer] = [
        .init(path:{var p=Path();p.move(to:CGPoint(x:59,y:67));p.addQuadCurve(to:CGPoint(x:58,y:108),control:CGPoint(x:52,y:85));p.addQuadCurve(to:CGPoint(x:70,y:108),control:CGPoint(x:64,y:113));p.addLine(to:CGPoint(x:74,y:70));p.closeSubpath();return p}(),fill:Color(hex:0xD4A76C),stroke:Color(hex:0x285957),width:3),
        .init(path:{var p=Path();p.move(to:CGPoint(x:176,y:67));p.addLine(to:CGPoint(x:178,y:107));p.addQuadCurve(to:CGPoint(x:191,y:105),control:CGPoint(x:185,y:112));p.addLine(to:CGPoint(x:188,y:66));p.closeSubpath();return p}(),fill:Color(hex:0xD4A76C),stroke:Color(hex:0x285957),width:3),
        .init(path:{var p=Path();p.move(to:CGPoint(x:64,y:81));p.addLine(to:CGPoint(x:63,y:101));p.move(to:CGPoint(x:184,y:79));p.addLine(to:CGPoint(x:185,y:100));return p}(),fill:nil,stroke:Color(hex:0xFFF1CE),width:3),
        .init(path:{var p=Path();p.move(to:CGPoint(x:20,y:27));p.addQuadCurve(to:CGPoint(x:61,y:16),control:CGPoint(x:28,y:12));p.addQuadCurve(to:CGPoint(x:152,y:15),control:CGPoint(x:111,y:9));p.addQuadCurve(to:CGPoint(x:220,y:28),control:CGPoint(x:201,y:9));p.addQuadCurve(to:CGPoint(x:219,y:77),control:CGPoint(x:235,y:53));p.addQuadCurve(to:CGPoint(x:146,y:83),control:CGPoint(x:189,y:89));p.addQuadCurve(to:CGPoint(x:50,y:84),control:CGPoint(x:96,y:91));p.addQuadCurve(to:CGPoint(x:13,y:64),control:CGPoint(x:19,y:84));p.addQuadCurve(to:CGPoint(x:20,y:27),control:CGPoint(x:6,y:44));p.closeSubpath();return p}(),fill:Color(hex:0xF7E8C5),stroke:Color(hex:0x285957),width:3),
        .init(path:{var p=Path();p.move(to:CGPoint(x:27,y:31));p.addQuadCurve(to:CGPoint(x:80,y:24),control:CGPoint(x:49,y:22));p.addQuadCurve(to:CGPoint(x:176,y:23),control:CGPoint(x:129,y:18));p.addQuadCurve(to:CGPoint(x:218,y:41),control:CGPoint(x:213,y:18));p.addQuadCurve(to:CGPoint(x:208,y:73),control:CGPoint(x:226,y:65));p.addQuadCurve(to:CGPoint(x:144,y:75),control:CGPoint(x:176,y:80));p.addQuadCurve(to:CGPoint(x:47,y:75),control:CGPoint(x:95,y:84));p.addQuadCurve(to:CGPoint(x:22,y:58),control:CGPoint(x:23,y:76));p.addQuadCurve(to:CGPoint(x:27,y:31),control:CGPoint(x:17,y:42));p.closeSubpath();return p}(),fill:Color(hex:0xA9DACB),stroke:nil,width:0),
        .init(path:{var p=Path();p.move(to:CGPoint(x:32,y:34));p.addQuadCurve(to:CGPoint(x:100,y:30),control:CGPoint(x:69,y:26));p.move(to:CGPoint(x:119,y:28));p.addQuadCurve(to:CGPoint(x:200,y:29),control:CGPoint(x:165,y:24));return p}(),fill:nil,stroke:Color(hex:0xF5F9DF),width:4),
        .init(path:{var p=Path();p.move(to:CGPoint(x:66,y:73));p.addQuadCurve(to:CGPoint(x:154,y:71),control:CGPoint(x:119,y:78));p.move(to:CGPoint(x:165,y:73));p.addQuadCurve(to:CGPoint(x:210,y:64),control:CGPoint(x:196,y:77));return p}(),fill:nil,stroke:Color(hex:0x7CB9AA),width:3),
        .init(path:{var p=Path();p.move(to:CGPoint(x:213,y:76));p.addQuadCurve(to:CGPoint(x:224,y:52),control:CGPoint(x:225,y:64));p.move(to:CGPoint(x:223,y:64));p.addQuadCurve(to:CGPoint(x:236,y:56),control:CGPoint(x:233,y:63));p.move(to:CGPoint(x:219,y:69));p.addQuadCurve(to:CGPoint(x:214,y:57),control:CGPoint(x:212,y:63));return p}(),fill:nil,stroke:Color(hex:0xECA68A),width:6),
        .init(path:{var p=Path();p.move(to:CGPoint(x:29,y:66));p.addCurve(to:CGPoint(x:37,y:66),control1:CGPoint(x:29,y:61),control2:CGPoint(x:37,y:61));p.addCurve(to:CGPoint(x:29,y:66),control1:CGPoint(x:37,y:72),control2:CGPoint(x:29,y:72));p.closeSubpath();return p}(),fill:Color(hex:0xFFF1CE),stroke:Color(hex:0x285957),width:1.5),
    ]
    private static let check:[Layer] = [
        .init(path:{var p=Path();p.move(to:CGPoint(x:6,y:3));p.addQuadCurve(to:CGPoint(x:25,y:3),control:CGPoint(x:14,y:0));p.addQuadCurve(to:CGPoint(x:29,y:14),control:CGPoint(x:30,y:5));p.addQuadCurve(to:CGPoint(x:25,y:28),control:CGPoint(x:31,y:25));p.addQuadCurve(to:CGPoint(x:6,y:28),control:CGPoint(x:16,y:32));p.addQuadCurve(to:CGPoint(x:3,y:16),control:CGPoint(x:1,y:25));p.addQuadCurve(to:CGPoint(x:6,y:3),control:CGPoint(x:0,y:7));p.closeSubpath();return p}(),fill:Color(hex:0xB8E5D3),stroke:Color(hex:0x285957),width:2.5),
        .init(path:{var p=Path();p.move(to:CGPoint(x:7,y:8));p.addQuadCurve(to:CGPoint(x:19,y:5),control:CGPoint(x:11,y:4));return p}(),fill:nil,stroke:Color(hex:0xFFF8DC),width:2.5),
        .init(path:{var p=Path();p.move(to:CGPoint(x:8,y:15));p.addLine(to:CGPoint(x:14,y:22));p.addLine(to:CGPoint(x:25,y:9));return p}(),fill:nil,stroke:Color(hex:0x285957),width:5),
        .init(path:{var p=Path();p.move(to:CGPoint(x:8,y:14));p.addLine(to:CGPoint(x:14,y:20));p.addLine(to:CGPoint(x:24,y:8));return p}(),fill:nil,stroke:Color(hex:0xE7B956),width:3),
    ]
    private static func draw(_ layers:[Layer],in c:GraphicsContext) {
        for l in layers {
            if let f=l.fill {c.fill(l.path,with:.color(f))}
            if let s=l.stroke {c.stroke(l.path,with:.color(s),style:.init(lineWidth:l.width,lineCap:.round,lineJoin:.round))}
        }
    }
    static func checkbox(in context:GraphicsContext,at point:CGPoint,size:Double) {
        var c=context;c.translateBy(x:point.x-size/2,y:point.y-size/2);c.scaleBy(x:size/32,y:size/32)
        draw(check,in:c)
    }
    static func sign(in context:GraphicsContext,size:CGSize) {
        var c=context;c.scaleBy(x:size.width/240,y:size.height/120)
        draw(sign,in:c)
        checkbox(in:c,at:.init(x:58.4,y:52.4),size:36.8)
        c.draw(Text("All clear").font(.custom("ChalkboardSE-Bold",size:26)).foregroundStyle(Color(hex:0x285957)),at:.init(x:144,y:52))
    }
}
struct ReefClearSign:View {
    var body:some View {
        Canvas {c,s in ReefClearArt.sign(in:c,size:s)}
            .frame(width:128,height:64).accessibilityElement(children:.ignore).accessibilityLabel("All clear")
    }
}
