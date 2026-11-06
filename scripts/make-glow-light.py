#!/usr/bin/env python3
"""Round sea-glass Glow bulb and matching key, without changing older masters."""
from pathlib import Path
import ast,re
R=Path(__file__).resolve().parents[1];D=R/'Design/Powerups'
module=ast.parse((R/'scripts/make-powerup-icons.py').read_text())
helpers=ast.Module(body=[n for n in module.body if isinstance(n,ast.FunctionDef) and n.name in ['layer','svgbody','swiftpath']],type_ignores=[])
ns={'re':re,'ink':'#285957'};exec(compile(helpers,'icon-helpers','exec'),ns)
layer,svgbody,swiftpath=[ns[n] for n in ['layer','svgbody','swiftpath']]
# Broad round glass dome, a coral-like glowing filament, and a ribbed shell socket.
glass=[
layer('M 37 65 C 37 56 20 53 20 32 C 20 0 80 0 80 32 C 80 53 63 56 63 65 Z','#A4DCD1'),
layer('M 41 61 C 40 51 27 48 27 32 C 27 9 73 9 73 32 C 73 48 60 52 59 61 Z','#FFF0B8','none',0),
layer('M 30 30 C 30 19 40 15 46 16','none','#FFFFFF',4),
layer('M 51 61 L 51 35 M 51 49 C 40 49 37 42 37 38 M 51 45 C 62 44 64 38 64 34','none','#D49A43',3.5),
layer('M 51 36 L 51 28 M 37 38 L 35 33 M 64 34 L 65 29','none','#F4C66B',4),
layer('M 35 62 Q 50 58 65 62 L 64 77 Q 50 83 36 77 Z','#76B6A5'),
layer('M 37 65 Q 50 68 63 64 M 37 72 Q 50 75 63 71','none','#D7EACB',2.8)]
def keyhead(d):
 coords=iter(range(1000))
 def coordinate(m):
  n=next(coords);v=float(m.group())
  return str(round(50+(v-50)*0.85 if n%2==0 else v*0.73+3,3))
 return re.sub(r'-?\d+(?:\.\d+)?',coordinate,d)
keyglass=[(keyhead(d),f,st,w) for d,f,st,w in glass]
icons={'glowLight':glass+[layer('M 41 79 Q 50 93 59 79','#F4C66B')],
       'glowKey':[layer('M 44 56 L 57 56 L 57 77 L 72 77 L 72 85 L 57 85 L 57 90 L 66 90 L 66 98 L 44 98 Z','#F4C66B'),layer('M 49 64 L 49 92','none','#FFF1C9',3)]+keyglass}
for name,layers in icons.items():
 (D/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewBox="0 0 100 110">{svgbody(layers)}</svg>')
sheet=['<svg xmlns="http://www.w3.org/2000/svg" width="800" height="480" viewBox="0 0 800 480">','<rect id="preview-water" width="800" height="480" fill="#BBDDD0"/>']
for i,(name,layers) in enumerate(icons.items()):
 x=75+i*390
 sheet.append(f'<g id="{name}" transform="translate({x},38) scale(2.6)">{svgbody(layers)}</g><text x="{x+130}" y="386" fill="#285957" text-anchor="middle" font-family="Avenir Next" font-size="25">'+('Glow' if i==0 else 'Glow key')+'</text>')
sheet.append('</svg>');(D/'Glow-Light-and-Key.svg').write_text(''.join(sheet))
color=lambda c:'nil' if c=='none' else f'Color(red:{int(c[1:3],16)/255:.5f},green:{int(c[3:5],16)/255:.5f},blue:{int(c[5:7],16)/255:.5f})'
s='// Matches the editable Glow-Light-and-Key Affinity/SVG master.\nimport SwiftUI\nextension ReefPowerupArt {\n'
for name,layers in icons.items():
 s+=f'    static let {name}:[Layer] = [\n'
 for d,f,st,w in layers:s+=f'        Layer(path:{{{swiftpath(d)}}}(),fill:{color(f)},stroke:{color(st)},width:{w}),\n'
 s+='    ]\n'
s+='}\n';(R/'puffpuff/Art/GlowLightArt.swift').write_text(s)
p=R/'puffpuff/Art/ReefIcons.swift';s=p.read_text()
if 'current, glowKey }' not in s:s=s.replace('current }','current, glowKey }')
s=s.replace('case .glow: return glow','case .glow: return glowLight') if 'case .glow: return glowLight' not in s else s
if 'case .glowKey:' not in s:s=s.replace('case .current: return current','case .current: return current\n        case .glowKey: return glowKey')
if 'var sparkleSeed' not in s:
 s=s.replace('    var size: CGFloat = 30','    var size: CGFloat = 30\n    var sparkleSeed = 0\n    @Environment(\\.oceanTime) private var time\n    @Environment(\\.accessibilityReduceMotion) private var reduceMotion',1)
 s=s.replace('init(_ kind: ReefIconKind, size: CGFloat = 30) { self.kind = kind; self.size = size }','init(_ kind: ReefIconKind, size: CGFloat = 30, sparkleSeed: Int = 0) { self.kind = kind; self.size = size; self.sparkleSeed = sparkleSeed }')
 s=s.replace('            }\n        }.frame(width: size, height: size)','            }\n            if kind == .glow || kind == .glowKey { GlowTwinkles.draw(in:c,time:time,seed:sparkleSeed,still:reduceMotion) }\n        }.frame(width: size, height: size)',1)
p.write_text(s)
