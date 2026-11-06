#!/usr/bin/env python3
"""Create the current-changer vector master and matching native layers only."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
layers=[
('M 49 10 C 72 7 92 28 88 52 C 85 76 62 94 39 87 C 14 81 7 58 14 37 C 20 21 34 12 49 10 Z','#80CABB','#285957',3),
('M 21 41 C 26 23 45 17 59 22','none','#FFF1C9',5),
('M 69 73 Q 56 87 37 78','none','#5BA99C',4),
('M 29 55 C 21 35 43 25 60 33 C 73 40 70 58 58 62 C 44 67 35 54 44 47 Q 51 41 56 48','none','#285957',10),
('M 29 55 C 21 35 43 25 60 33 C 73 40 70 58 58 62 C 44 67 35 54 44 47 Q 51 41 56 48','none','#FFF1C9',5),
('M 65 18 L 83 26 L 67 39 L 69 29 Z','#F4C66B','#285957',2.5),
('M 23 63 L 38 74 L 20 81 L 24 72 Z','#F4C66B','#285957',2.5)]
body=''.join(f'<path id="current-layer-{i}" d="{d}" fill="{f}" stroke="{s}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>' for i,(d,f,s,w) in enumerate(layers))
(R/'Design/Powerups/Current-Changer.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewBox="0 0 100 100">{body}</svg>')
def path(d):
 t=re.findall(r'[A-Za-z]|-?\d+(?:\.\d+)?',d); out=['var p=Path()'];i=0
 point=lambda a,b:f'CGPoint(x:{a},y:{b})'
 while i<len(t):
  cmd=t[i];i+=1
  if cmd=='Z':out.append('p.closeSubpath()');continue
  n={'M':2,'L':2,'Q':4,'C':6}[cmd];v=t[i:i+n];i+=n
  if cmd=='M':out.append(f'p.move(to:{point(*v)})')
  elif cmd=='L':out.append(f'p.addLine(to:{point(*v)})')
  elif cmd=='Q':out.append(f'p.addQuadCurve(to:{point(*v[2:])},control:{point(*v[:2])})')
  else:out.append(f'p.addCurve(to:{point(*v[4:])},control1:{point(*v[:2])},control2:{point(*v[2:4])})')
 return ';'.join(out)+';return p'
def color(c):return 'nil' if c=='none' else f'Color(red:{int(c[1:3],16)/255:.5f},green:{int(c[3:5],16)/255:.5f},blue:{int(c[5:7],16)/255:.5f})'
s='// Matches Design/Powerups/Current-Changer.svg.\nimport SwiftUI\nextension ReefPowerupArt {\n    static let current:[Layer] = [\n'
for d,f,st,w in layers:s+=f'        Layer(path:{{{path(d)}}}(),fill:{color(f)},stroke:{color(st)},width:{w}),\n'
(R/'puffpuff/Art/ReefCurrentArt.swift').write_text(s+'    ]\n}\n')

# Keep the catalog registration when regenerating the older icon families.
p=R/'puffpuff/Art/ReefIcons.swift'
s=p.read_text()
if 'boostStored, current }' not in s:s=s.replace('boostStored }','boostStored, current }')
if 'case .current: return current' not in s:s=s.replace('case .boostStored: return boostStored','case .boostStored: return boostStored\n        case .current: return current')
p.write_text(s)
