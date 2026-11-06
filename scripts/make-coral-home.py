#!/usr/bin/env python3
"""Create an editable coral-house SVG and matching native Swift vector layers."""
from pathlib import Path
import re, html
ROOT=Path(__file__).resolve().parents[1]
parts=[]
def path(name,d,fill,stroke=None,width=2.2):
    parts.append((name,d,fill,stroke,width))
def ellipse(name,x,y,rx,ry,fill,stroke=None,width=2.2):
    k=.55228475
    path(name,f'M {x+rx} {y} C {x+rx} {y+ry*k} {x+rx*k} {y+ry} {x} {y+ry} C {x-rx*k} {y+ry} {x-rx} {y+ry*k} {x-rx} {y} C {x-rx} {y-ry*k} {x-rx*k} {y-ry} {x} {y-ry} C {x+rx*k} {y-ry} {x+rx} {y-ry*k} {x+rx} {y} Z',fill,stroke,width)
outline='#925948'; cream='#FFE2B8'; peach='#F4AB8D'; coral='#E98279'; rose='#D96B72'; gold='#E9B869'; teal='#397C76'
ellipse('water-shadow',155,263,109,15,'#6EAAA0')
# Branching coral chimney, behind the cottage.
path('chimney-outline','M 205 126 C 210 100 212 78 207 56 C 205 45 210 40 215 46 L 224 69 C 229 61 231 48 229 38 C 227 29 233 25 238 32 C 246 45 240 66 233 80 C 244 77 251 71 254 61 C 258 52 265 55 264 63 C 261 82 246 93 230 98 L 228 130 Z',coral,outline,2.8)
path('chimney-light','M 215 58 C 221 82 221 105 217 119 M 233 43 C 235 60 230 74 225 85 M 255 65 C 250 78 238 85 227 88',None,cream,2)
# Living foundation.
path('foundation','M 48 246 C 63 231 91 228 112 232 C 137 223 161 226 186 232 C 209 224 249 232 263 248 C 276 260 250 267 228 268 L 84 269 C 56 268 34 260 48 246 Z','#F0CE9B',outline,2.5)
# Rounded, asymmetrical coral walls.
path('cottage-body','M 83 142 C 80 123 106 109 153 111 C 198 109 224 123 225 150 L 234 229 C 236 249 219 258 157 260 C 102 262 77 250 79 233 Z',peach,outline,3.2)
path('cottage-shadow','M 198 132 C 213 147 214 195 215 222 C 218 238 207 250 188 258 C 219 257 237 249 234 229 L 225 150 C 223 140 213 134 198 132 Z',coral)
path('cottage-light','M 95 161 C 88 184 91 218 93 233 M 105 243 C 112 247 122 248 130 248',None,cream,4)
# Porous details are clustered, never face-like.
for i,(x,y,r) in enumerate([(95,192,2),(105,206,3),(101,221,1.5),(199,185,2.5),(206,198,1.5),(199,214,3),(207,226,1.8),(121,180,2),(117,190,1.4)]):
    ellipse(f'coral-pore-{i}',x,y,r,r*.78,'#D27E68')
# Plate-coral roof: three overlapping scalloped shelves.
path('lower-roof','M 63 143 C 67 127 93 122 113 126 C 136 113 167 115 184 123 C 208 117 238 127 245 142 C 255 156 241 165 226 161 C 213 176 194 170 186 165 C 171 178 154 171 146 166 C 129 179 113 169 106 162 C 87 172 76 159 75 155 C 59 160 53 151 63 143 Z',rose,outline,3)
path('lower-roof-rim','M 65 148 C 73 149 78 145 82 143 C 87 157 102 160 112 151 C 122 165 138 164 147 154 C 158 165 176 168 187 154 C 201 165 217 163 223 150 C 229 153 237 152 242 147',None,'#FFC0A0',3.5)
path('middle-roof','M 78 119 C 82 101 103 92 122 94 C 137 80 160 80 178 90 C 201 84 222 99 229 115 C 238 127 228 140 215 136 C 203 148 184 142 179 135 C 166 148 151 142 144 136 C 131 148 114 141 110 133 C 95 143 81 136 82 130 C 71 130 70 123 78 119 Z',coral,outline,2.8)
path('middle-roof-rim','M 81 121 C 86 130 100 133 110 123 C 119 136 135 135 144 126 C 154 137 170 137 180 126 C 191 136 207 135 215 125 C 218 129 225 125 227 121',None,'#FFD1AA',4)
path('crown-roof','M 98 96 C 96 80 114 67 129 68 C 139 48 160 47 174 62 C 191 60 212 78 211 95 C 213 108 199 114 190 107 C 181 121 162 115 156 108 C 145 121 130 114 126 107 C 112 114 98 108 98 96 Z','#F7B19A',outline,2.8)
path('crown-highlight','M 109 91 C 108 81 120 76 131 78 C 139 59 157 58 166 70 C 184 66 198 78 200 89',None,cream,4)
# Coral ridges and stippled roof texture.
for i,(x,y) in enumerate([(116,94),(142,83),(169,87),(186,96),(101,117),(130,112),(159,119),(199,116),(93,145),(131,149),(169,149),(207,148)]):
    path(f'roof-ridge-{i}',f'M {x-3} {y+2} C {x-4} {y-3} {x+2} {y-5} {x+4} {y-1}',None,'#C87065',1.6)
# One round glowing window, separated from the doorway.
ellipse('window-frame',183,165,16,16,gold,outline,2.5)
ellipse('window-glass',183,165,11.8,11.8,'#367E78','#855E42',1.5)
path('window-glow','M 174 162 C 176 154 185 152 191 158 C 186 160 180 164 175 171 C 172 168 172 165 174 162 Z','#B5E9C7')
path('window-cross','M 183 154 L 183 176 M 172 165 L 194 165',None,'#D8AD70',2)
ellipse('window-rivet-a',183,151,1,1,cream)
ellipse('window-rivet-b',197,165,1,1,cream)
# The narrow entrance is real and remains legible at game scale.
path('door-rim','M 135 249 L 135 218 C 135 196 143 188 154 188 C 166 188 176 198 176 217 L 176 249 C 162 254 148 253 135 249 Z',gold,outline,2.8)
path('door-opening','M 142 247 L 142 218 C 142 201 147 196 154 196 C 163 196 169 203 169 218 L 169 247 C 160 250 150 250 142 247 Z','#183E42','#A97350',1.8)
path('door-inner-light','M 148 239 L 148 216 C 148 209 150 205 153 204',None,'#3F7772',2)
path('shell-awning','M 132 198 C 135 186 142 184 146 184 C 149 176 161 176 166 184 C 172 185 178 189 179 198 C 172 202 165 199 163 197 C 158 204 150 201 148 197 C 142 201 136 202 132 198 Z',cream,outline,2)
# A pearl lamp and looping stem.
path('lamp-stem','M 113 188 C 111 177 121 174 123 180',None,outline,2)
ellipse('pearl-lamp',121,186,5,6.2,'#FFF0BA','#BD8E59',1.2)
# Low coral gardens, no faces.
path('garden-left','M 55 254 C 42 249 39 240 48 233 C 38 224 45 217 55 221 C 52 208 62 204 67 215 C 75 206 84 215 78 225 C 88 224 92 235 82 240 C 90 248 79 256 71 252 C 66 259 59 259 55 254 Z','#DB7D86',outline,2)
path('garden-left-ridges','M 61 250 C 54 239 56 225 62 218 M 65 249 C 66 236 73 230 79 232 M 58 247 C 50 240 48 234 50 230',None,'#FFC4B0',2)
path('garden-right','M 216 250 C 205 246 207 238 217 235 C 208 226 218 219 225 226 C 228 214 237 215 239 226 C 248 219 257 226 250 235 C 261 235 264 245 253 249 C 247 258 235 254 230 252 C 225 256 219 255 216 250 Z','#78AFA0',teal,2)
path('garden-right-ridges','M 229 249 C 222 240 220 234 221 229 M 234 249 C 236 238 236 233 233 226 M 239 248 C 243 241 247 239 252 240',None,'#C3E4BA',2)
# Shell doorstep on top of the planted foundation.
path('doorstep','M 133 251 C 142 245 168 246 180 252 C 187 257 174 262 156 262 C 138 263 125 258 133 251 Z','#F9D9A8',outline,1.8)
path('doorstep-highlight','M 138 254 C 148 251 166 252 175 255',None,cream,2)

svg=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:serif="https://www.affinity.studio/" width="900" height="900" viewBox="0 0 300 300">']
for name,d,fill,stroke,w in parts:
    svg.append(f'<path id="{name}" serif:id="{name}" d="{d}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
svg.append('</svg>')
(ROOT/'Design/CoralHome/Coral-Cottage.svg').write_text('\n'.join(svg))
# Native paths use the same geometry; no raster scaling artifacts.
out=['import SwiftUI\n\n// Generated by scripts/make-coral-home.py. Editable vector source: Design/CoralHome.\nenum CoralHomeArt {', '    static func draw(in context: GraphicsContext, at entrance: CGPoint, scale: Double, open: Bool) {', '        var c = context', '        c.translateBy(x: entrance.x - 155 * scale, y: entrance.y - 227 * scale)', '        c.scaleBy(x: scale, y: scale)', '        for part in layers {', '            if let fill = part.fill { c.fill(part.path, with: .color(Color(hex: fill))) }', '            if let stroke = part.stroke { c.stroke(part.path, with: .color(Color(hex: stroke)), style: .init(lineWidth: part.width, lineCap: .round, lineJoin: .round)) }', '        }', '        if open {', '            c.stroke(Path(ellipseIn: CGRect(x: 166, y: 148, width: 34, height: 34)), with: .color(ReefTheme.glint.opacity(0.7)), lineWidth: 2)', '        }', '    }', '    private struct Layer { let path: Path; let fill: UInt32?; let stroke: UInt32?; let width: Double }', '    private static let layers: [Layer] = [']
for name,d,fill,stroke,w in parts:
    ts=re.findall(r'[MCLZ]|[-+]?(?:\d*\.\d+|\d+\.?\d*)',d); i=0; cmds=[]
    while i<len(ts):
        op=ts[i];i+=1
        def pt():
            global i
            x,y=ts[i:i+2];i+=2;return f'CGPoint(x: {x}, y: {y})'
        if op=='M':cmds.append(f'p.move(to: {pt()})')
        elif op=='L':cmds.append(f'p.addLine(to: {pt()})')
        elif op=='C':
            a,b,e=pt(),pt(),pt();cmds.append(f'p.addCurve(to: {e}, control1: {a}, control2: {b})')
        else:cmds.append('p.closeSubpath()')
    col=lambda s:'0x'+s[1:] if s else 'nil'
    out.append(f'        // {name}\n        Layer(path: Path {{ p in '+ '; '.join(cmds)+f' }}, fill: {col(fill)}, stroke: {col(stroke)}, width: {w}),')
out+=['    ]','}']
(ROOT/'puffpuff/Art/CoralHomeArt.swift').write_text('\n'.join(out)+'\n')
print(f'Created {len(parts)} editable layers.')
