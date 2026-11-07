#!/usr/bin/env python3
"""Import the user's Affinity reef export; never regenerate or edit the master.

The five placeholder pearls in open chests are intentionally omitted. The game
draws the actual awarded supplies there. All other paths, transforms and paints
come directly from the export, including the edited wood grain and chest bands.
"""
from pathlib import Path
import copy
import importlib.util
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'Design/Trail'
spec = importlib.util.spec_from_file_location('vector_import', ROOT / 'scripts/import-puffpuff-art.py')
vector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vector)
ASSETS = 'kelpForest sandpit enemySchool food chestMint chestMintOpen chestCoral chestCoralOpen chestGold chestGoldOpen'.split()


def clean(node):
    for child in list(node):
        name = child.get(vector.AFFINITY) or child.get('id', '')
        tag = child.tag.rsplit('}', 1)[-1]
        if tag == 'text' or re.fullmatch(r'pearl-\d', name):
            node.remove(child)
        else:
            clean(child)


def swift_path(ops, coordinates):
    values = iter(coordinates)
    def point():
        return f'CGPoint(x:{vector.number(next(values))},y:{vector.number(next(values))})'
    commands = []
    for op in ops:
        if op == 'M': commands.append(f'p.move(to:{point()})')
        elif op == 'L': commands.append(f'p.addLine(to:{point()})')
        elif op == 'C':
            a, b, end = point(), point(), point()
            commands.append(f'p.addCurve(to:{end},control1:{a},control2:{b})')
        elif op == 'Z': commands.append('p.closeSubpath()')
        else: raise ValueError(f'Unsupported operation {op}')
    return '; '.join(commands)


def main():
    source = DESIGN / 'First-Reef-Affinity-Export.svg'
    root = ET.parse(source).getroot()
    groups = {group.get('id'): group for group in root if group.get('id') in ASSETS}
    assert set(groups) == set(ASSETS), 'Missing named assets in Affinity export'
    output = ROOT / 'puffpuff/Art/TrailArt.swift'
    # Retain the small hand-authored drawing/kelp-motion wrapper, replace data only.
    wrapper = output.read_text().split('    private static let layers:')[0].rstrip() + '\n'
    out = [wrapper, '    private static let layers: [Asset:[Layer]] = [']
    total = 0
    for name in ASSETS:
        group = copy.deepcopy(groups[name])
        clean(group)
        parts = vector.layers(group)
        assert parts, f'Empty asset: {name}'
        out.append(f'        .{name}: [')
        for label, ops, points, fill, stroke, width, alpha, transform in parts:
            assert alpha == 1, f'Unexpected alpha on {label}'
            match = re.search(r'(?:frond(?:-vein)?|leaf)-(\d+)', label)
            sway = int(match.group(1)) if name == 'kelpForest' and match else -1
            matrix = ','.join(f'{key}:{vector.number(v)}' for key, v in zip(('a','b','c','d','tx','ty'), transform))
            out.append(f'            // {label}\n            Layer(name:"{label}",path:Path {{ p in {swift_path(ops, points)} }},fill:{fill},stroke:{stroke},width:{vector.number(width)},swayGroup:{sway},transform:CGAffineTransform({matrix})),')
        out.append('        ],')
        total += len(parts)
        group.attrib.pop('transform', None)  # Remove sheet position, keep all inner edits.
        single = ET.Element('svg', xmlns='http://www.w3.org/2000/svg', width='600', height='600', viewBox='0 0 300 300')
        single.append(group)
        ET.ElementTree(single).write(DESIGN / f'{name}.svg', encoding='unicode')
    out.extend(['    ]', '}'])
    output.write_text('\n'.join(out) + '\n')
    # Matching portable sheet retains asset labels, excluding placeholder loot.
    for group in groups.values():
        for parent in group.iter():
            for child in list(parent):
                label = child.get(vector.AFFINITY) or child.get('id', '')
                if re.fullmatch(r'pearl-\d', label): parent.remove(child)
    ET.ElementTree(root).write(DESIGN / 'First-Reef-Art.svg', encoding='unicode')
    print(f'Imported {len(ASSETS)} assets / {total} layers; preserved Affinity transforms; omitted 15 placeholder pearls.')


if __name__ == '__main__':
    main()
