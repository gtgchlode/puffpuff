#!/usr/bin/env python3
"""Shared vector curves for the new directional coral and its Affinity sheet.

Only writes the new SVGs and the marked native extension. Existing Coral Garden
and edited Affinity masters are never regenerated or overwritten.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Design/Corals"
SPECIES = [
    dict(key="tideSpires", name="Tide spires", color="#70C7B5", tip="#D8F3BC", direction="vertical",
         left="M 46 85 C 31 76 27 65 28 51 L 27 34 C 20 30 19 22 23 19 C 27 16 31 22 32 27 L 33 15 C 34 9 41 10 41 17 L 39 37 C 36 53 38 66 47 73 Z",
         right="M 52 85 C 65 76 70 63 70 48 L 72 32 C 79 28 81 20 77 18 C 73 16 70 23 68 26 L 67 15 C 66 9 59 12 60 18 L 61 38 C 63 51 60 66 52 74 Z",
         body="M 35 88 C 40 81 43 74 43 62 L 45 29 C 40 23 39 16 43 13 C 47 10 50 16 51 21 L 54 9 C 56 3 63 6 61 13 L 56 30 L 56 62 C 56 74 60 81 65 88 C 62 94 39 94 35 88 Z",
         veins="M 32 40 C 31 53 34 65 38 71 M 66 40 C 67 53 63 64 61 69 M 51 32 L 49 72 M 45 85 L 47 79",
         dots=[(36,20,1.4),(25,24,1.2),(65,22,1.3),(74,25,1.2),(56,13,1.4),(46,77,1.4),(55,86,1.1)]),
    dict(key="driftShelf", name="Drift shelf", color="#E9A279", tip="#FFE0AE", direction="horizontal",
         left="M 49 76 C 37 75 27 67 23 59 L 13 59 C 6 60 3 54 7 50 C 1 46 5 39 11 41 C 7 34 14 29 20 34 C 22 27 30 29 32 36 C 37 30 43 34 43 41 L 53 61 Z",
         right="M 51 76 C 64 75 74 66 78 58 L 89 58 C 97 59 99 52 94 49 C 100 44 95 38 89 40 C 93 33 85 28 80 33 C 76 27 69 30 68 36 C 62 30 56 34 57 41 L 47 61 Z",
         body="M 35 88 C 39 81 42 74 41 68 C 31 68 22 65 20 58 C 18 52 23 47 29 49 C 28 41 36 37 41 43 C 43 35 52 35 55 42 C 62 36 70 41 68 49 C 76 46 82 53 77 60 C 73 66 63 68 59 68 C 57 76 61 83 65 88 C 61 93 39 93 35 88 Z",
         veins="M 49 81 L 49 68 M 49 66 C 38 59 27 57 13 52 M 49 66 C 63 59 74 56 88 53 M 30 60 L 27 47 M 67 60 L 73 44",
         dots=[(16,39,1.4),(28,39,1.2),(72,39,1.3),(86,38,1.3),(35,54,1.2),(63,54,1.3),(55,85,1.1)]),
]


def coral(s, state="lit", prefix=""):
    fill = "#73978D" if state == "sleepy" else "#FFD6A0" if state == "bloom" else s["color"]
    tip = "#FFF0C9" if state == "bloom" else s["tip"]
    out = [f'<g id="{prefix}{s["key"]}-{state}">',
           '<ellipse cx="50" cy="89" rx="28" ry="5" fill="#06242B" opacity=".16"/>']
    for part in ["left", "right", "body"]:
        out.append(f'<path id="{prefix}{part}-sway-from-base" d="{s[part]}" fill="{fill}"/>')
    if state != "sleepy":
        out.append(f'<path id="{prefix}highlights" d="{s["veins"]}" fill="none" stroke="{tip}" stroke-width="2.8" stroke-linecap="round"/>')
        for i,(x,y,r) in enumerate(s["dots"]):
            out.append(f'<circle id="{prefix}polyp-{i}" cx="{x}" cy="{y}" r="{r}" fill="{tip}"/>')
    return "\n".join(out + ["</g>"])


def icon(s, prefix=""):
    # Two opposing arrows, centered exactly on the tile's center.
    path = "M 46 59 L 46 41 M 41 46 L 46 41 L 51 46 M 55 41 L 55 59 M 50 54 L 55 59 L 60 54"
    transform = ' transform="rotate(90 50 50)"' if s["direction"] == "horizontal" else ""
    return (f'<g id="{prefix}direction-icon"{transform}><ellipse cx="50" cy="50" rx="14" ry="15" fill="#244F50" opacity=".88"/>'
            f'<path d="{path}" fill="none" stroke="#FFF1C1" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/></g>')


def tile(s, state, prefix):
    background = "#345F5D" if state == "sleepy" else "#C6E3C7"
    rim = "#658E84" if state == "sleepy" else "#FFF5D1"
    return f'<circle cx="50" cy="50" r="48" fill="{background}" stroke="{rim}" stroke-width="1.5"/>' + coral(s,state,prefix) + icon(s,prefix)


def native_path(name, source):
    tokens = re.findall(r"[A-Za-z]|-?\d+(?:\.\d+)?",source)
    out=[f"    static let {name}: Path = {{", "        var p = Path()"]
    i=0
    point=lambda a,b:f"CGPoint(x: {a}, y: {b})"
    while i<len(tokens):
        command=tokens[i];i+=1
        if command=="Z":out.append("        p.closeSubpath()");continue
        count={"M":2,"L":2,"Q":4,"C":6}[command];v=tokens[i:i+count];i+=count
        line={"M":lambda:f"p.move(to: {point(*v)})", "L":lambda:f"p.addLine(to: {point(*v)})",
              "Q":lambda:f"p.addQuadCurve(to: {point(*v[2:])}, control: {point(*v[:2])})",
              "C":lambda:f"p.addCurve(to: {point(*v[4:])}, control1: {point(*v[:2])}, control2: {point(*v[2:4])})"}[command]()
        out.append("        "+line)
    return "\n".join(out+["        return p", "    }()"])


def main():
    for s in SPECIES:
        (ART/(s["key"]+".svg")).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 100 100">'+coral(s)+"</svg>\n")
    sheet=['<svg xmlns="http://www.w3.org/2000/svg" width="1120" height="800" viewBox="0 0 1120 800">',
           '<rect id="lagoon" width="1120" height="800" fill="#AADED0"/>',
           '<path id="sand" d="M 0 715 Q 300 675 560 715 Q 800 760 1120 700 L 1120 800 L 0 800 Z" fill="#EDDFB0"/>',
           '<text x="60" y="65" fill="#143F42" font-size="30" font-family="Chalkboard, sans-serif">Directional corals</text>']
    for col,s in enumerate(SPECIES):
        center=300+col*520
        sheet += [f'<g transform="translate({center-160},90) scale(3.2)">{coral(s,prefix="hero-")}</g>',
                  f'<text x="{center}" y="435" text-anchor="middle" fill="#143F42" font-size="25" font-family="Chalkboard, sans-serif">{s["name"]}</text>']
        for i,state in enumerate(["sleepy","lit","bloom"]):
            sheet += [f'<g transform="translate({center-210+i*145},490) scale(1.25)">{tile(s,state,s["key"]+state+"-")}</g>']
    sheet += ['</svg>']
    (ART/'Directional-Corals.svg').write_text("\n".join(sheet)+"\n")
    native=ROOT/'puffpuff/Art/CoralPaths.swift'
    marker="// Directional coral: generated by scripts/make-directional-corals.py."
    base=native.read_text().split(marker)[0].rstrip()
    extension="\n\n"+marker+"\nextension CoralPaths {\n"+"\n".join(native_path(s["key"]+part.title(),s[part]) for s in SPECIES for part in ["left","right","body","veins"])+"\n}\n"
    native.write_text(base+extension)


if __name__ == "__main__":
    main()
