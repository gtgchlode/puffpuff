#!/usr/bin/env python3
"""Mint instant boost and rare gold saved boost; preserve the original icon master."""
from pathlib import Path
import re, ast
R=Path(__file__).resolve().parents[1];D=R/'Design/Powerups';D.mkdir(parents=True,exist_ok=True)
# Reuse the exact path converter; execute only pure helper definitions.
module=ast.parse((R/'scripts/make-powerup-icons.py').read_text())
helpers=ast.Module(body=[n for n in module.body if isinstance(n,ast.FunctionDef) and n.name in ['layer','svgbody','swiftpath']],type_ignores=[])
ns={'re':re,'ink':'#A76C29'};exec(compile(helpers,'icon-helpers','exec'),ns)
layer=ns['layer'];svgbody=ns['svgbody'];swiftpath=ns['swiftpath']
heart='M 50 83 C 40 77 13 58 14 37 C 14 17 38 14 50 32 C 62 14 86 17 86 37 C 87 58 60 77 50 83 Z'
loop='M 50 55 C 36 35 18 42 19 55 C 20 72 40 68 50 55 C 62 40 80 41 81 55 C 81 70 62 73 50 55'
common=[layer(heart,'#F6C65D'),layer('M 22 38 C 23 27 36 25 42 33','none','#FFF1BA',5),layer('M 58 72 Q 75 59 78 41','none','#D69B34',4),layer(loop,'none','#BD8426',13),layer(loop,'none','#FFF0B1',8),layer('M 84 5 L 87 14 L 96 17 L 87 20 L 84 29 L 81 20 L 72 17 L 81 14 Z','#FFF1BA','#CA963D',1.5),layer('M 13 13 L 15 19 L 21 21 L 15 23 L 13 29 L 11 23 L 5 21 L 11 19 Z','#FFE39A','none',0)]
instant=[layer(heart,'#80CABB','#285957'),layer('M 24 39 C 24 27 36 26 42 33','none','#FFF1C9',4),layer(loop,'none','#285957',13),layer(loop,'none','#F4C66B',8)]
icons={'boostLive':instant,'boostStored':common+[layer('M 65 68 Q 73 65 82 68 L 83 94 L 74 88 L 65 94 Z','#E7AD44'),layer('M 72 72 L 72 81','none','#FFF1BA',3)]}
for key,ls in icons.items():(D/f'{key}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">{svgbody(ls)}</svg>')
sheet=['<svg xmlns="http://www.w3.org/2000/svg" width="500" height="260" viewBox="0 0 500 260">','<rect id="preview-water" width="500" height="260" fill="#D6E8DE"/>']
for i,(key,ls) in enumerate(icons.items()):
 x=35+240*i;sheet.append(f'<g id="{key}" transform="translate({x},20) scale(1.7)">{svgbody(ls)}</g><text x="{x+85}" y="225" text-anchor="middle" fill="#285957" font-family="Avenir Next" font-size="18">'+('15 min · now' if i==0 else 'Rare · saved')+'</text>')
(D/'Boost-Pickups.svg').write_text(''.join(sheet)+'</svg>')
p=R/'puffpuff/Art/ReefIcons.swift';s=p.read_text().split('// BEGIN GOLD BOOST PICKUPS')[0].rstrip()+'\n'
if 'case .boostLive: return boostLive' not in s:
 s=s.replace('case life, unlimited, hint, lighter, taps, glow, shot }','case life, unlimited, hint, lighter, taps, glow, shot, boostLive, boostStored }')
 s=s.replace('        case .shot: return shot','        case .shot: return shot\n        case .boostLive: return boostLive\n        case .boostStored: return boostStored')
color=lambda c:'nil' if c=='none' else f'Color(red: {int(c[1:3],16)/255:.5f}, green: {int(c[3:5],16)/255:.5f}, blue: {int(c[5:7],16)/255:.5f})'
s+='\n// BEGIN GOLD BOOST PICKUPS — matching Design/Powerups/Boost-Pickups.af.\nextension ReefPowerupArt {\n'
for key,ls in icons.items():
 s+=f'    static let {key}: [Layer] = [\n'
 for d,f,st,w in ls:s+=f'        Layer(path: {{ {swiftpath(d)} }}(), fill: {color(f)}, stroke: {color(st)}, width: {w}),\n'
 s+='    ]\n'
s+='}\n';p.write_text(s)
