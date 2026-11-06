#!/usr/bin/env python3
"""Import the approved Affinity SVG into native, morphable Swift vector layers.

Run after exporting PuffPuff-Official.svg from the official Affinity master.
This uses only Python's standard library and never writes to the art master.
Unsupported SVG constructs fail explicitly instead of dropping edited artwork.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Design/PuffPuff/PuffPuff-Official.svg'
OUTPUT = ROOT / 'puffpuff/Art/PipPaths.swift'
AFFINITY = '{https://www.affinity.studio/}id'
NUMBER = r'[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?'
IDENTITY = (1, 0, 0, 1, 0, 0)


def multiply(a, b):
    return (a[0]*b[0]+a[2]*b[1], a[1]*b[0]+a[3]*b[1],
            a[0]*b[2]+a[2]*b[3], a[1]*b[2]+a[3]*b[3],
            a[0]*b[4]+a[2]*b[5]+a[4], a[1]*b[4]+a[3]*b[5]+a[5])


def matrix(value):
    if not value:
        return IDENTITY
    if not re.fullmatch(r'matrix\([^()]+\)', value):
        raise ValueError(f'Unsupported SVG transform: {value}')
    values = tuple(map(float, re.findall(NUMBER, value)))
    if len(values) != 6:
        raise ValueError('Expected six matrix components')
    return values


def color(value):
    if value == 'none':
        return 'nil'
    if value == 'white':
        return '0xFFFFFF'
    if value == 'black':
        return '0x000000'
    match = re.fullmatch(r'rgb\((\d+),(\d+),(\d+)\)', value)
    if not match:
        raise ValueError(f'Unsupported paint: {value}')
    r, g, b = map(int, match.groups())
    return f'0x{r:02X}{g:02X}{b:02X}'


def number(value):
    return format(value, '.12g')


def contour(data):
    tokens = re.findall(r'[A-Za-z]|' + NUMBER, data)
    ops, points, i = [], [], 0
    count = {'M': 2, 'L': 2, 'C': 6, 'Z': 0}
    while i < len(tokens):
        op = tokens[i]
        if op not in count:
            raise ValueError(f'Unsupported SVG path command: {op}')
        i += 1
        while True:
            size = count[op]
            values = list(map(float, tokens[i:i+size]))
            if len(values) != size:
                raise ValueError('Incomplete SVG path')
            ops.append(op)
            points.extend(values)
            i += size
            if i == len(tokens) or tokens[i].isalpha():
                break
            if op == 'Z':
                raise ValueError('Unexpected coordinates after close')
            if op == 'M':
                op = 'L'
    return ''.join(ops), points


def layers(group):
    result = []

    def visit(node, transform=IDENTITY, style=None, name=None):
        tag = node.tag.rsplit('}', 1)[-1]
        if tag not in ('g', 'path'):
            raise ValueError(f'Unsupported SVG element: {tag}')
        transform = multiply(transform, matrix(node.get('transform')))
        style = dict(style or {'fill': 'black', 'stroke': 'none'})
        style.update(piece.split(':', 1) for piece in node.get('style', '').split(';') if piece)
        name = node.get(AFFINITY) or node.get('id') or name
        if tag == 'g':
            for child in node:
                visit(child, transform, style, name)
            return
        if not name:
            raise ValueError('Every drawable layer needs a name')
        allowed = {'fill', 'stroke', 'stroke-width', 'fill-opacity', 'stroke-opacity',
                   'opacity', 'fill-rule', 'stroke-linecap', 'stroke-linejoin', 'clip-rule'}
        if set(style) - allowed:
            raise ValueError(f'Unsupported style on {name}: {set(style) - allowed}')
        if style.get('fill-rule', 'nonzero') != 'nonzero':
            raise ValueError(f'Unexpected fill rule on {name}')
        fill, stroke = color(style['fill']), color(style['stroke'])
        alpha = float(style.get('opacity', 1))
        fill_alpha = float(style.get('fill-opacity', 1))
        stroke_alpha = float(style.get('stroke-opacity', 1))
        if fill != 'nil' and stroke != 'nil' and fill_alpha != stroke_alpha:
            raise ValueError(f'Separate fill and stroke alpha on {name}')
        alpha *= fill_alpha if fill != 'nil' else stroke_alpha
        ops, points = contour(node.attrib['d'])
        width = float(style.get('stroke-width', '0').removesuffix('px'))
        result.append((name, ops, points, fill, stroke, width, alpha, transform))

    for child in group:
        visit(child)
    names = [part[0] for part in result]
    if len(names) != len(set(names)):
        raise ValueError('Duplicate named paths within a pose')
    return result


def emit_parts(name, parts):
    out = [f'    private static let {name}: [PipContourPart] = [']
    for label, ops, points, fill, stroke, width, alpha, transform in parts:
        out.extend([
            f'        .init(name: "{label}", operations: "{ops}",',
            '              coordinates: [' + ', '.join(map(number, points)) + '],',
            f'              fill: {fill}, stroke: {stroke}, width: {number(width)}, opacity: {number(alpha)},',
            '              transform: CGAffineTransform(' + ', '.join(f'{key}: {number(v)}' for key, v in zip(('a','b','c','d','tx','ty'), transform)) + ')),',
        ])
    out.append('    ]')
    return '\n'.join(out)


SWIFT_HEAD = '''import SwiftUI

// GENERATED from Design/PuffPuff/PuffPuff-Official.svg, exported from the user's
// approved Affinity master. Edit that master, then run scripts/import-puffpuff-art.py.
// Never regenerate this artwork from an earlier procedural concept.
enum PipPaths {
    static func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
    }

    static func parts(inflation: Double) -> [PipVectorPart] {
        let amount = min(1, max(0, inflation))
        // Exact approved endpoint artwork. Between them every visible contour
        // moves; the smile curls into the pucker instead of ghosting over it.
        if amount == 0 { return happy.map { $0.vectorPart() } }
        if amount == 1 { return puffed.map { $0.vectorPart() } }
        let body = amount * amount * (3 - 2 * amount)
        return zip(morphHappy, morphPuffed).map { a, b in
            let t: Double
            if a.name.contains("mouth") || a.name.contains("lips") {
                t = min(1, amount * 1.55) // Pucker first, then fill the belly.
            } else if a.name.contains("fin") || a.name == "tail" {
                t = max(0, body - sin(body * .pi) * 0.055)
            } else { t = body }
            return a.vectorPart(interpolating: b, progress: t)
        }
    }

'''

SWIFT_TAIL = '''
}

private struct PipContourPart {
    let name: String
    let operations: String
    let coordinates: [Double]
    let fill: UInt32?
    let stroke: UInt32?
    let width: Double
    let opacity: Double
    let transform: CGAffineTransform

    func vectorPart(interpolating other: PipContourPart? = nil, progress: Double = 0) -> PipVectorPart {
        let b = other ?? self
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * progress }
        var offset = 0
        func point() -> CGPoint {
            defer { offset += 2 }
            return CGPoint(x: mix(coordinates[offset], b.coordinates[offset]),
                           y: mix(coordinates[offset + 1], b.coordinates[offset + 1]))
        }
        var path = Path()
        for command in operations.utf8 {
            switch command {
            case 77: path.move(to: point())
            case 76: path.addLine(to: point())
            case 67:
                let c1 = point(), c2 = point(), end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
            case 90: path.closeSubpath()
            default: preconditionFailure("Unsupported generated path command")
            }
        }
        let t = transform, u = b.transform
        let motion = CGAffineTransform(a: mix(t.a, u.a), b: mix(t.b, u.b),
                                      c: mix(t.c, u.c), d: mix(t.d, u.d),
                                      tx: mix(t.tx, u.tx), ty: mix(t.ty, u.ty))
        return PipVectorPart(name: name, path: path, fill: fill, stroke: stroke,
                             width: mix(width, b.width), opacity: mix(opacity, b.opacity),
                             transform: motion)
    }
}

struct PipVectorPart {
    let name: String
    let path: Path
    var fill: UInt32?
    var stroke: UInt32?
    var width = 4.2
    var opacity = 1.0
    var transform = CGAffineTransform.identity
}
'''


def transformed(points, matrix):
    a,b,c,d,tx,ty=matrix
    return [(a*points[i]+c*points[i+1]+tx,b*points[i]+d*points[i+1]+ty) for i in range(0,len(points),2)]


def collapse(part, mapped=False):
    name,ops,pts,fill,stroke,width,alpha,t=part
    center=(sum(pts[0::2])/len(pts[0::2]),sum(pts[1::2])/len(pts[1::2]))
    if mapped:
        center=(173+(center[0]-173)*1.02,151+(center[1]-144)*.47)
    return (name,ops,list(center)*(len(pts)//2),fill,stroke,0,alpha,t)


def smile_ribbon(smile, width):
    pts=transformed(smile[2],smile[7])
    mid=lambda a,b:((a[0]+b[0])/2,(a[1]+b[1])/2)
    p0,p1,p2,p3=pts
    a,b,c=mid(p0,p1),mid(p1,p2),mid(p2,p3)
    d,e=mid(a,b),mid(b,c); m=mid(d,e)
    # Four cubic spans, starting at the right corner like the puffed ellipse.
    lower=[p3,c,e,m,d,a,p0]
    upper=[a,d,m,e,c,p3]
    result=[p3]
    for i,q in enumerate(lower[1:]):
        result.append((q[0],q[1]+(0 if i==5 else width/2)))
    for i,q in enumerate(upper):
        result.append((q[0],q[1]-(0 if i==5 else width/2)))
    return [v for pt in result for v in pt]


def morph_layers(puffed,happy):
    ph={p[0]:p for p in puffed}; hh={p[0]:p for p in happy}
    smile=hh['happy-smile']
    result_h=[];result_p=[]
    for name in list(ph)+[n for n in hh if n not in ph and n!='happy-smile']:
        a=hh.get(name);b=ph.get(name)
        if name in ('puffed-lips','puffed-mouth'):
            # Both contours are continuous from the approved happy smile.
            # The outer lip begins with zero area/width; no transparency blend.
            thickness=0 if name=='puffed-lips' else smile[5]
            a=(name,'MCCCCZ',smile_ribbon(smile,thickness),b[3],b[4],0,b[6],IDENTITY)
        elif a is None:a=collapse(b,mapped=True)
        elif b is None:b=collapse(a)
        if a[1]!=b[1] or len(a[2])!=len(b[2]) or a[3:5]!=b[3:5]:
            raise ValueError(f'{name}: revised artwork needs a contour correspondence, never a crossfade')
        result_h.append(a);result_p.append(b)
    return result_h,result_p


def main():
    root = ET.parse(SOURCE).getroot()
    poses = {g.get('id'): g for g in root}
    expected = {'puffed-up': (2,0,0,2,0,0), 'happy-regular': (2,0,0,2,640,0)}
    if set(poses) != set(expected):
        raise ValueError('Expected exactly puffed-up and happy-regular pose groups')
    for name, layout in expected.items():
        if matrix(poses[name].get('transform')) != layout:
            raise ValueError(f'Pose layout changed for {name}; review the coordinate mapping')
    puffed, happy = layers(poses['puffed-up']), layers(poses['happy-regular'])
    mh,mp=morph_layers(puffed,happy)
    generated = SWIFT_HEAD + emit_parts('puffed', puffed) + '\n\n' + emit_parts('happy', happy) + '\n\n' + emit_parts('morphPuffed',mp) + '\n\n' + emit_parts('morphHappy',mh) + SWIFT_TAIL
    OUTPUT.write_text(generated)
    print(f'Imported {len(puffed)} puffed layers and {len(happy)} happy layers from the official SVG.')


if __name__ == '__main__':
    main()
