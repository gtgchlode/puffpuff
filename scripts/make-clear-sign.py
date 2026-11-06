#!/usr/bin/env python3
"""Matching editable SVG and native paths for the reef completion sign."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
folder=R/'Design/Trail';folder.mkdir(parents=True,exist_ok=True)
ink='#285957'
sign=[
('left-post','M 59 67 Q 52 85 58 108 Q 64 113 70 108 L 74 70 Z','#D4A76C',ink,3),
('right-post','M 176 67 L 178 107 Q 185 112 191 105 L 188 66 Z','#D4A76C',ink,3),
('post-grain','M 64 81 L 63 101 M 184 79 L 185 100','none','#FFF1CE',3),
('shell-frame','M 20 27 Q 28 12 61 16 Q 111 9 152 15 Q 201 9 220 28 Q 235 53 219 77 Q 189 89 146 83 Q 96 91 50 84 Q 19 84 13 64 Q 6 44 20 27 Z','#F7E8C5',ink,3),
('glass-face','M 27 31 Q 49 22 80 24 Q 129 18 176 23 Q 213 18 218 41 Q 226 65 208 73 Q 176 80 144 75 Q 95 84 47 75 Q 23 76 22 58 Q 17 42 27 31 Z','#A9DACB','none',0),
('glass-shimmer','M 32 34 Q 69 26 100 30 M 119 28 Q 165 24 200 29','none','#F5F9DF',4),
('bottom-refraction','M 66 73 Q 119 78 154 71 M 165 73 Q 196 77 210 64','none','#7CB9AA',3),
('coral-tuft','M 213 76 Q 225 64 224 52 M 223 64 Q 233 63 236 56 M 219 69 Q 212 63 214 57','none','#ECA68A',6),
('pearl','M 29 66 C 29 61 37 61 37 66 C 37 72 29 72 29 66 Z','#FFF1CE',ink,1.5),
]
check=[
('sea-glass-box','M 6 3 Q 14 0 25 3 Q 30 5 29 14 Q 31 25 25 28 Q 16 32 6 28 Q 1 25 3 16 Q 0 7 6 3 Z','#B8E5D3',ink,2.5),
('rim-glint','M 7 8 Q 11 4 19 5','none','#FFF8DC',2.5),
('check-shadow','M 8 15 L 14 22 L 25 9','none',ink,5),
('gold-check','M 8 14 L 14 20 L 24 8','none','#E7B956',3),
]
def svgparts(layers):
 return ''.join(f'<path id="{name}" d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>' for name,d,fill,stroke,width in layers)
signbody=svgparts(sign)+f'<g id="checked-shell" transform="translate(40 34) scale(1.15)">{svgparts(check)}</g>'+'<text id="all-clear-label" x="144" y="62" text-anchor="middle" font-family="Chalkboard SE" font-size="26" font-weight="bold" fill="#285957">All clear</text>'
(folder/'Reef-All-Clear.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="960" height="480" viewBox="0 0 480 240"><rect id="preview-water" width="480" height="240" fill="#B9DECF"/><g id="All-clear-sign" transform="translate(20 55) scale(1.3)">{signbody}</g><g id="Map-checkbox" transform="translate(365 90) scale(2.4)">{svgparts(check)}</g></svg>')
(folder/'Reef-All-Clear-Sign.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="240" height="120" viewBox="0 0 240 120">{signbody}</svg>')
(folder/'Reef-All-Clear-Check.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">{svgparts(check)}</svg>')
def path(d):
 t=re.findall(r'[A-Za-z]|-?\d+(?:\.\d+)?',d);o=['var p=Path()'];i=0
 def pt(a,b):return f'CGPoint(x:{a},y:{b})'
 while i<len(t):
  cmd=t[i];i+=1
  if cmd=='Z':o.append('p.closeSubpath()');continue
  n={'M':2,'L':2,'Q':4,'C':6}[cmd];v=t[i:i+n];i+=n
  if cmd=='M':o.append(f'p.move(to:{pt(*v)})')
  elif cmd=='L':o.append(f'p.addLine(to:{pt(*v)})')
  elif cmd=='Q':o.append(f'p.addQuadCurve(to:{pt(*v[2:])},control:{pt(*v[:2])})')
  else:o.append(f'p.addCurve(to:{pt(*v[4:])},control1:{pt(*v[:2])},control2:{pt(*v[2:4])})')
 return ';'.join(o)+';return p'
def color(c):return 'nil' if c=='none' else f'Color(hex:0x{c[1:]})'
s='''// Matches Design/Trail/Reef-All-Clear.svg. Preserve later Affinity edits.
import SwiftUI

enum ReefClearArt {
    private struct Layer {let path:Path;let fill:Color?;let stroke:Color?;let width:Double}
'''
for name,ls in [('sign',sign),('check',check)]:
 s+=f'    private static let {name}:[Layer] = [\n'
 for _,d,f,st,w in ls:s+=f'        .init(path:{{{path(d)}}}(),fill:{color(f)},stroke:{color(st)},width:{w}),\n'
 s+='    ]\n'
s+='''    private static func draw(_ layers:[Layer],in c:GraphicsContext) {
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
'''
(R/'puffpuff/Art/ReefClearArt.swift').write_text(s)
