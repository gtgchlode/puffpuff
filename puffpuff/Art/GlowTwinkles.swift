import SwiftUI

/// One shared ocean clock, twelve rim positions; the bulb never has a fixed center star.
enum GlowTwinkles {
    static let positions:[CGPoint] = [.init(x:18,y:20),.init(x:80,y:14),.init(x:83,y:42),.init(x:18,y:49),.init(x:64,y:8),.init(x:30,y:10),.init(x:77,y:58),.init(x:23,y:61),.init(x:84,y:28),.init(x:16,y:35),.init(x:42,y:7),.init(x:71,y:14)]
    static func draw(in c:GraphicsContext,time:Double,seed:Int=0,still:Bool=false) {
        for lane in 0..<(still ? 1:2) {
            let clock=(time+Double((seed*337+lane*1900)%48000)).truncatingRemainder(dividingBy:48000)
            let beat=Int(clock/4000),phase=(clock.truncatingRemainder(dividingBy:4000))/1700
            let alpha=still ? 0.7:phase<1 ? pow(sin(phase * .pi),2):0
            guard alpha>0.01 else{continue}
            let p=positions[(beat*5+seed+lane*7)%positions.count],r=(lane==0 ? 5.4:3.4)*(0.7+0.3*alpha)
            var star=Path();star.move(to:.init(x:p.x,y:p.y-r))
            star.addQuadCurve(to:.init(x:p.x+r,y:p.y),control:.init(x:p.x+1,y:p.y-1))
            star.addQuadCurve(to:.init(x:p.x,y:p.y+r),control:.init(x:p.x+1,y:p.y+1))
            star.addQuadCurve(to:.init(x:p.x-r,y:p.y),control:.init(x:p.x-1,y:p.y+1))
            star.addQuadCurve(to:.init(x:p.x,y:p.y-r),control:.init(x:p.x-1,y:p.y-1));star.closeSubpath()
            var glow=c;glow.addFilter(.blur(radius:2));glow.fill(star,with:.color(Color(hex:0xFFF2B2).opacity(alpha*0.7)))
            c.fill(star,with:.color(Color(hex:0xFFFADE).opacity(alpha)))
        }
    }
}
