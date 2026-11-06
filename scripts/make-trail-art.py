#!/usr/bin/env python3
"""Editable trail sprites, one Affinity sheet, and identical native Swift paths."""
from pathlib import Path
import math,re,html
R=Path(__file__).resolve().parents[1];D=R/'Design/Trail';D.mkdir(exist_ok=True)
assets={};parts=[]
ink='#42776E';cream='#FFE8B8';gold='#EABB75';shadow='#6CA397'
def path(name,d,fill=None,stroke=None,w=2.4): parts.append((name,d,fill,stroke,w))
def ellipse(n,x,y,rx,ry,c,s=None,w=2.4):
 k=.55228475
 path(n,f'M {x+rx} {y} C {x+rx} {y+k*ry} {x+k*rx} {y+ry} {x} {y+ry} C {x-k*rx} {y+ry} {x-rx} {y+k*ry} {x-rx} {y} C {x-rx} {y-k*ry} {x-k*rx} {y-ry} {x} {y-ry} C {x+k*rx} {y-ry} {x+rx} {y-k*ry} {x+rx} {y} Z',c,s,w)
def transform(data,scale,dx,dy):
 out=[]
 for n,d,f,s,w in data:
  t=re.findall(r'[MLCQZ]|[-+]?(?:\d*\.\d+|\d+\.?\d*)',d);r=[];axis=0
  for token in t:
   if token in 'MLCQZ':r.append(token);axis=0
   else:r.append(f'{float(token)*scale+(dx if axis%2==0 else dy):.3f}');axis+=1
  out.append((n,' '.join(r),f,s,w*scale))
 return out
# Ribbon kelp forest, broad fronds and individual paired leaves.
ellipse('lagoon-shadow',150,257,111,16,shadow)
path('root-mound','M 43 244 C 54 225 78 223 105 229 C 130 220 154 218 179 228 C 204 218 245 230 256 246 C 258 259 224 265 155 267 C 93 270 39 260 43 244 Z','#CCCEA0',ink)
for i,(x,top,width) in enumerate([(72,104,11),(111,60,15),(151,37,15),(195,76,15),(230,124,11)]):
 path(f'frond-{i}',f'M {x-3} 247 C {x+15} 203 {x-19} 185 {x-6} 151 C {x+13} 115 {x-10} {top+25} {x+7} {top} C {x+31} {top+19} {x+12} 118 {x+17} 152 C {x+28} 183 {x+8} 214 {x+8} 248 Z',['#579B82','#71B798','#84C7A2','#5EAA8C','#75AF91'][i],ink,2.8)
 path(f'frond-vein-{i}',f'M {x+2} 246 C {x+19} 208 {x-8} 180 {x+4} 151 C {x+19} 115 {x+2} {top+32} {x+9} {top+10}',None,'#C4DFC0',1.8)
 for j in range(3):
  y=top+45+j*(195-top)/3
  side=-1 if j%2==0 else 1
  path(f'leaf-{i}-{j}',f'M {x+5} {y+15} C {x+side*27} {y+6} {x+side*35} {y-13} {x+side*25} {y-25} C {x+side*3} {y-22} {x+side*1} {y} {x+5} {y+15} Z','#96CDA5',ink,1.9)
for i,(x,y) in enumerate([(64,249),(91,255),(137,254),(192,251),(222,249)]):ellipse(f'root-pebble-{i}',x,y,7,4,gold,ink,1.3)
assets['kelpForest']=parts;parts=[]
# Sand pit: sunlit shell rim, shadowed center and low rippling dunes.
ellipse('sand-shadow',150,244,115,21,shadow)
path('sand-rim','M 29 205 C 26 171 61 147 91 148 C 113 129 158 131 182 144 C 219 136 261 157 270 185 C 292 218 259 249 224 253 C 176 274 110 259 83 255 C 49 251 28 233 29 205 Z','#F1D9A4','#B68F58',3)
path('sand-bowl','M 53 202 C 68 178 101 171 124 177 C 147 161 195 171 218 180 C 249 177 266 206 245 222 C 214 244 177 235 145 241 C 104 242 61 232 53 202 Z','#D9AE6C','#C19457',2)
path('front-dune','M 39 218 C 79 197 106 219 139 211 C 176 202 211 216 258 214 C 248 248 211 253 167 253 C 105 257 57 246 39 218 Z','#EBC78B',None)
path('sand-rim-light','M 40 199 C 42 177 70 159 94 162 C 123 143 152 147 178 156 M 191 157 C 224 152 251 173 257 189 M 57 232 C 91 248 126 246 150 246',None,cream,4)
for i in range(20):
 x=70+(i*43)%160;y=190+(i*17)%47
 ellipse(f'sand-grain-{i}',x,y,1.5+(i%2),1,'#B98C54')
for i in range(3):path(f'dune-ripple-{i}',f'M {85+i*37} {217+i%2*10} C {97+i*37} {211+i%2*10} {106+i*37} {224+i%2*10} {119+i*37} {219+i%2*10}',None,'#F9DFAC',2)
path('tiny-shell','M 211 168 C 199 159 201 146 211 143 C 224 143 228 158 219 169 Z','#ECA391','#AC7561',1.5)
path('shell-lines','M 215 167 L 210 148 M 215 167 L 219 150',None,cream,1.2)
assets['sandpit']=parts;parts=[]
# A school of cheeky reef fish, separate tail/fin/eye layers.
def fish():
 global parts
 path('tail','M 86 147 C 68 129 52 122 47 129 C 55 145 55 160 46 174 C 59 181 75 167 88 159 Z','#E7A294',ink,3)
 path('dorsal-fin','M 116 121 C 133 101 149 99 157 118 L 179 126 Z','#B9D8BA',ink,2)
 path('body','M 75 152 C 101 118 165 105 204 132 C 229 143 226 164 207 175 C 157 201 101 181 75 152 Z','#79AA9E',ink,3)
 path('belly','M 90 157 C 133 166 182 168 216 151 C 226 173 177 186 144 180 C 119 179 102 168 90 157 Z','#C7DCC0')
 path('back-light','M 103 141 C 131 123 159 121 181 128',None,'#DBE7C2',4)
 path('side-fin','M 144 154 C 132 151 122 160 124 173 C 137 170 147 164 144 154 Z',gold,ink,1.8)
 path('gill','M 169 146 C 162 154 166 161 172 163',None,ink,2)
 ellipse('eye-white',193,143,11,12,'#FFF7D8',ink,2)
 ellipse('eye-pupil',197,146,4.5,6,'#28524F')
 ellipse('eye-shine',198,142,1.7,2,'#FFFFFF')
 path('cheeky-brow','M 180 130 L 202 137',None,ink,3.2)
 path('mouth','M 212 158 C 217 155 222 157 225 159',None,ink,2)
 path('tail-lines','M 58 134 L 80 148 M 57 163 L 79 155',None,cream,1.6)
 base=parts;parts=[];return base
base=fish()
for i,(sc,dx,dy) in enumerate([(.8,34,-38),(.66,-11,50),(.69,108,77)]):
 for n,d,f,s,w in transform(base,sc,dx,dy):parts.append((f'fish-{i}-{n}',d,f,s,w))
assets['enemySchool']=parts;parts=[]
# Food: little sea-grape sprig, no face.
ellipse('food-shadow',150,250,70,12,shadow)
path('stem','M 151 240 C 145 199 146 156 176 105',None,ink,7)
path('left-leaf','M 157 142 C 114 144 91 114 98 89 C 137 90 157 111 157 142 Z','#95C8A4',ink,3)
path('left-vein','M 105 99 C 124 112 137 125 153 139',None,'#D6E5B7',2)
path('right-leaf','M 166 123 C 169 87 195 67 222 75 C 217 106 193 123 166 123 Z','#6FAF93',ink,3)
path('right-vein','M 173 116 L 209 84',None,'#C8E0B2',2)
for i,(x,y,r) in enumerate([(127,145,22),(174,150,23),(106,183,23),(153,190,26),(195,184,22),(131,224,21),(173,228,22)]):
 ellipse(f'grape-{i}',x,y,r,r*1.05,['#E88F85','#F3AB8D','#DB8484'][i%3],'#A56361',2.7)
 ellipse(f'grape-glint-{i}',x-r*.3,y-r*.34,r*.28,r*.18,'#FFDEB6')
assets['food']=parts;parts=[]
# All chests share a shell-clasp silhouette. Accent colours signal their contents.
for accent,name in [('#8CC7B5','mint'),('#EFA091','coral'),('#EFC573','gold')]:
 for opened in [False,True]:
  parts=[]
  ellipse('chest-shadow',151,258,102,14,shadow)
  if opened:
   path('open-lid','M 64 144 L 67 76 C 91 51 202 46 234 79 L 232 147 Z',accent,'#826653',3)
   path('open-lid-inset','M 79 133 L 81 85 C 113 67 192 63 219 87 L 218 134 Z','#B58D67','#826653',2)
   path('lid-scallops','M 85 89 C 112 75 139 91 161 80 C 181 72 200 80 212 91',None,cream,3)
  else:
   path('rounded-lid','M 53 167 L 54 141 C 54 93 88 80 147 81 C 205 77 243 96 246 143 L 246 166 Z',accent,'#826653',3)
   path('lid-light','M 67 140 C 67 105 96 94 143 94 C 195 87 228 106 232 135',None,cream,4)
   for i,x in enumerate([90,122,177,210]):path(f'lid-plank-{i}',f'M {x} 102 C {x-4} 119 {x-3} 139 {x-2} 155',None,'#729D8A' if name=='mint' else '#BC876B',1.8)
  path('chest-body','M 54 153 C 114 143 191 144 244 153 L 238 234 C 230 255 84 261 61 235 Z','#DAB486','#826653',3)
  path('body-shadow','M 211 151 L 244 153 L 238 234 C 227 246 212 248 199 250 L 205 174 Z','#BC9069')
  for i,y in enumerate([177,203,228]):path(f'wood-grain-{i}',f'M 71 {y} C 105 {y-7} 130 {y+5} 158 {y} C 184 {y-6} 203 {y+3} 226 {y-2}',None,'#B98C64',1.7)
  path('left-band','M 77 150 L 96 148 L 96 249 L 78 245 Z',accent,'#826653',1.8)
  path('right-band','M 201 148 L 219 151 L 218 245 L 201 249 Z',accent,'#826653',1.8)
  path('rim','M 54 151 C 107 142 194 143 244 151 L 244 167 C 182 159 105 159 55 167 Z',gold,'#826653',2)
  if opened:
   path('treasure-dark','M 67 146 C 101 135 209 135 232 147 C 213 161 94 159 67 146 Z','#37766E','#826653',2)
   for i,(x,y) in enumerate([(104,139),(130,129),(156,141),(182,130),(209,142)]):ellipse(f'pearl-{i}',x,y,11,10,cream,'#CFA15C',1.4)
  # Pearl shell clasp in the middle, never a padlock box.
  path('shell-clasp','M 145 205 C 129 195 123 181 133 174 C 135 161 149 160 154 166 C 165 159 176 170 173 181 C 180 192 164 203 155 206 Z',cream,'#A77A4F',2)
  path('clasp-ridges','M 150 201 L 138 176 M 153 200 L 152 170 M 157 201 L 167 178',None,gold,1.6)
  for i,(x,y) in enumerate([(86,180),(87,229),(209,180),(209,230)]):ellipse(f'pearl-rivet-{i}',x,y,2.8,2.8,cream,'#9B7955',.7)
  assets['chest'+name.title()+('Open' if opened else '')]=parts

def svg_paths(items):
 return '\n'.join(f'<path id="{html.escape(n)}" serif:id="{html.escape(n)}" d="{d}" fill="{f or "none"}" stroke="{s or "none"}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>' for n,d,f,s,w in items)
head='<svg xmlns="http://www.w3.org/2000/svg" xmlns:serif="https://www.affinity.studio/"'
for name,items in assets.items():(D/(name+'.svg')).write_text(head+' width="600" height="600" viewBox="0 0 300 300">'+svg_paths(items)+'</svg>')
sheet=[head+' width="1800" height="1500" viewBox="0 0 1200 1000">','<rect width="1200" height="1000" fill="#C9E8D8"/>','<text x="40" y="48" font-family="Avenir Next" font-size="26" fill="#143F42">puffpuff · first reef</text>']
for i,(name,items) in enumerate(assets.items()):
 x=i%4*300;y=i//4*300+60
 sheet.append(f'<g id="{name}" serif:id="{name}" transform="translate({x} {y})">'+svg_paths(items)+f'<text x="150" y="292" text-anchor="middle" font-family="Avenir Next" font-size="14" fill="#376963">{name}</text></g>')
sheet.append('</svg>');(D/'First-Reef-Art.svg').write_text('\n'.join(sheet))
# Identical layers for SwiftUI Canvas; all edits can be traced to named source paths.
out=['import SwiftUI', 'enum TrailArt {', '    enum Asset: String { case kelpForest, sandpit, enemySchool, food, chestMint, chestMintOpen, chestCoral, chestCoralOpen, chestGold, chestGoldOpen }', '    private struct Layer { let path: Path; let fill: UInt32?; let stroke: UInt32?; let width: Double; let swayGroup: Int }', '    static func draw(_ asset: Asset, in context: GraphicsContext, at point: CGPoint, size: Double, time: Double = 0) {', '        var c=context; c.translateBy(x:point.x-size/2,y:point.y-size/2); c.scaleBy(x:size/300,y:size/300)', '        for p in layers[asset] ?? [] {', '            var layer = c', '            if asset == .kelpForest && p.swayGroup >= 0 {', '                let group = Double(p.swayGroup)', '                let phase = group * 0.34', '                let wave = sin(time / 8000 * .pi * 2 + phase) - sin(phase)', '                let ripple = sin(time / 12000 * .pi * 2 + phase) - sin(phase)', '                // Each frond, its leaves and veins share a planted root pivot.', '                layer.translateBy(x: 74 + group * 39, y: 247)', '                layer.rotate(by: .degrees(wave * 1.25))', '                layer.concatenate(CGAffineTransform(a: 1, b: 0, c: ripple * 0.007, d: 1, tx: 0, ty: 0))', '                layer.translateBy(x: -(74 + group * 39), y: -247)', '            }', '            if let f=p.fill { layer.fill(p.path,with:.color(Color(hex:f))) }', '            if let s=p.stroke { layer.stroke(p.path,with:.color(Color(hex:s)),style:.init(lineWidth:p.width,lineCap:.round,lineJoin:.round)) }', '        }', '    }', '    private static let layers: [Asset:[Layer]] = [']
for name,items in assets.items():
 out.append(f'        .{name}: [')
 for n,d,f,s,w in items:
  ts=re.findall(r'[MLCQZ]|[-+]?(?:\d*\.\d+|\d+\.?\d*)',d);i=0;cmd=[]
  def pt():
   global i
   x,y=ts[i:i+2];i+=2;return f'CGPoint(x:{x},y:{y})'
  while i<len(ts):
   op=ts[i];i+=1
   if op=='M':cmd.append(f'p.move(to:{pt()})')
   elif op=='L':cmd.append(f'p.addLine(to:{pt()})')
   elif op=='C':
    a,b,e=pt(),pt(),pt();cmd.append(f'p.addCurve(to:{e},control1:{a},control2:{b})')
   elif op=='Q':
    a,e=pt(),pt();cmd.append(f'p.addQuadCurve(to:{e},control:{a})')
   else:cmd.append('p.closeSubpath()')
  col=lambda x:'0x'+x[1:] if x else 'nil'
  m = re.search(r'(?:frond(?:-vein)?|leaf)-(\d+)',n)
  group = int(m.group(1)) if name == 'kelpForest' and m else -1
  out.append(f'            // {n}\n            Layer(path:Path {{ p in '+ '; '.join(cmd)+f' }},fill:{col(f)},stroke:{col(s)},width:{w},swayGroup:{group}),')
 out.append('        ],')
out+=['    ]','}'];(R/'puffpuff/Art/TrailArt.swift').write_text('\n'.join(out)+'\n')
print('Created',len(assets),'sprites, layered art sheet, and matching native paths.')
