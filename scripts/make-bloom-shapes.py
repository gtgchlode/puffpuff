#!/usr/bin/env python3
"""Author the level-27+ reef footprints and reachable starting arrangements.

Only the authored pack changes. Player saves are never opened by this script.
Generation uses legal reverse taps and the same shortest-solution rules as Swift.
"""
import json
import random
from pathlib import Path

PACK = Path(__file__).resolve().parents[1] / "puffpuff/Resources/BloomLevels.json"
PLAYABLE_LIMIT = 100  # Match ReefStore.levelLimit; leave later drafts untouched.

SMALL = [
    ("Round reef", [".##.", "####", "####", ".##."]),
    ("Clipped shore", [".###", "####", "####", "###."]),
    ("Coral fan", [".##.", "####", "####", "####"]),
    ("Sloping shelf", ["###.", "####", "####", ".###"]),
    ("Little cove", ["####", "####", ".###", "..##"]),
    ("Soft steps", ["###.", "####", "####", "##.."]),
]
LARGE = [
    ("Round reef", [".###.", "#####", "#####", "#####", ".###."]),
    ("Sloping shelf", [".####", "#####", "#####", "####.", "###.."]),
    ("Coral fan", ["..#..", ".###.", "#####", "#####", ".###."]),
    ("Reef ribbon", ["###..", "####.", "#####", ".####", "..###"]),
    ("Little cove", ["#####", "####.", "###..", "####.", ".###."]),
    ("Diamond reef", ["..#..", ".###.", "#####", ".###.", "..#.."]),
    ("Coral arch", [".###.", "#####", "#####", "##.##", ".#.#."]),
]


# Deliberate local edits: preserve tile mixes, but make 28–35 all shaped.
CUSTOM_SHAPES = {
    28: ("Pebble lagoon", ["###.", "#.##", "####", ".###"]),
    31: ("Crescent cove", [".###", "####", "##..", ".###"]),
    34: ("Coral loop", [".##.", "####", "#..#", "####"]),
    35: ("Split lagoon", ["####", "##.#", "#.##", ".###"]),
    43: ("Diamond reef", ["..#..", ".###.", "#####", ".###.", "..#.."]),
}


def footprint(number, size):
    if number in CUSTOM_SHAPES:
        return CUSTOM_SHAPES[number]
    shapes = SMALL if size == 4 else LARGE
    offset = number - (27 if size == 4 else 41)
    name, pattern = shapes[offset % len(shapes)]
    if (number - 27) % 3 == 1:
        name, pattern = "Square reef", ["#" * size] * size
    if offset >= len(shapes) and (offset // len(shapes)) % 2:
        pattern = [row[::-1] for row in reversed(pattern)]
    return name, pattern


def connected(slots, size):
    if not slots:
        return False
    reached = {min(slots)}
    pending = list(reached)
    while pending:
        i = pending.pop()
        row, column = divmod(i, size)
        for dr, dc in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
            r, c = row + dr, column + dc
            j = r * size + c
            if 0 <= r < size and 0 <= c < size and j in slots and j not in reached:
                reached.add(j)
                pending.append(j)
    return reached == slots


def place_markers(level, slots):
    size = level["size"]
    occupied = set()
    for kind in ["stones", "currents", "stars", "verticals", "rowCorals", "columnCorals", "burstCorals"]:
        chosen = []
        for original in level.get(kind, []):
            r, c = divmod(original, size)
            candidates = sorted(slots - occupied, key=lambda i: (abs(i//size-r)+abs(i%size-c), i))
            for candidate in candidates:
                if kind == "verticals" and not all(
                        adjacent in slots - set(level["stones"])
                        for adjacent in [candidate-size, candidate+size]):
                    continue
                if kind != "stones" or connected(slots - occupied - {candidate}, size):
                    chosen.append(candidate)
                    occupied.add(candidate)
                    break
            else:
                raise ValueError(f"No safe {kind} position at level {level['level']}")
        level[kind] = chosen


def affected(level, index):
    size = level["size"]
    available = set(range(size*size)) - set(level["stones"]) - set(level["gaps"])
    if index not in available:
        return []
    r, c = divmod(index, size)
    if index in level.get("burstCorals", []):
        return sorted(i for i in available if abs(i//size-r)<=1 and abs(i%size-c)<=1)
    if index in level.get("rowCorals", []):
        return sorted(i for i in available if i // size == r)
    if index in level.get("columnCorals", []):
        return sorted(i for i in available if i % size == c)
    if index in level.get("verticals", []):
        offsets = [(0, 0), (-1, 0), (1, 0)]
    elif index in level["currents"]:
        offsets = [(0, 0), (0, -1), (0, 1)]
    elif index in level["stars"]:
        offsets = [(0, 0), (-1, -1), (-1, 1), (1, -1), (1, 1)]
    else:
        offsets = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]
    return [(r+dr)*size+c+dc for dr, dc in offsets
            if 0 <= r+dr < size and 0 <= c+dc < size and (r+dr)*size+c+dc in available]


def shortest_solution(level):
    active = [i for i in range(level["size"]**2) if affected(level, i)]
    lookup = {index: row for row, index in enumerate(active)}
    count = len(active)
    rhs = 1 << count
    rows = [0 if level["cells"][i] else rhs for i in active]
    for move, index in enumerate(active):
        for cell in affected(level, index):
            rows[lookup[cell]] |= 1 << move
    pivots = []
    for column in range(count):
        rank = len(pivots)
        pivot = next((r for r in range(rank, count) if rows[r] & (1 << column)), None)
        if pivot is None:
            continue
        rows[rank], rows[pivot] = rows[pivot], rows[rank]
        for r in range(count):
            if r != rank and rows[r] & (1 << column):
                rows[r] ^= rows[rank]
        pivots.append(column)
    if any(row == rhs for row in rows):
        raise ValueError("Reverse-tap construction produced an unreachable board")
    best = sum(1 << column for row, column in enumerate(pivots) if rows[row] & rhs)
    basis = []
    for column in set(range(count)) - set(pivots):
        basis.append((1 << column) | sum(1 << pivot for row, pivot in enumerate(pivots) if rows[row] & (1 << column)))
    def minimize(n, candidate):
        nonlocal best
        if n == len(basis):
            if candidate.bit_count() < best.bit_count():
                best = candidate
            return
        minimize(n+1, candidate)
        minimize(n+1, candidate ^ basis[n])
    minimize(0, best)
    return [index for column, index in enumerate(active) if best & (1 << column)]


def tile_mix(number):
    # New mechanics join a palette: ordinary reefs keep appearing, and each
    # new tile gets a brief solo introduction before selective combinations.
    if number in (36, 37):
        return ("vertical",)
    if number == 38:
        return ("vertical", "stone")
    if number <= 40:
        return [(), ("stone",), (), ("stone",), ()][(number - 27) % 5]
    if number <= 42:
        return ("current",)
    if number <= 60:
        return [(), ("stone",), ("vertical",), (), ("current", "stone"),
                ("current",), ("vertical", "stone"), ("current",)][(number - 43) % 8]
    if number <= 62:
        return ("star",)
    if number <= 80:
        return [(), ("current",), ("stone",), ("star",), ("vertical",),
                (), ("star", "current"), ("vertical", "star")][(number - 63) % 8]
    return [("stone", "current", "star"), (), ("vertical",), ("stone",),
            ("current", "stone"), (), ("current",), ("star", "current"),
            ("star", "vertical"), ()][(number - 81) % 10]


def author(level):
    number, size = level["level"], level["size"]
    if number < 27 or number > PLAYABLE_LIMIT:
        return None
    if number >= 71:
        return author_finale(level)
    if number >= 46:
        return author_extension(level)
    name, pattern = footprint(number, size)
    slots = {r*size+c for r, row in enumerate(pattern) for c, value in enumerate(row) if value == "#"}
    if not connected(slots, size):
        raise ValueError(f"Disconnected footprint: {name}")
    level["gaps"] = sorted(set(range(size*size)) - slots)
    # Shape and tile choices vary independently; not every new idea is present.
    mix = tile_mix(number)
    level["feature"] = ("mixed" if len(mix) > 1 else mix[0] if mix
                        else "pearl" if level.get("pearlTarget") is not None else "classic")
    # Authored marker anchors, independent of a previous generator run.
    level["stones"] = [0, size*size-1] if "stone" in mix else []
    level["currents"] = [6] if "current" in mix else []
    level["stars"] = [12] if "star" in mix else []
    if "vertical" in mix:
        level["verticals"] = [6, 9] if number == 38 else [6]
    else:
        level["verticals"] = []
    place_markers(level, slots)
    active = sorted(slots - set(level["stones"]))
    target = (3 if number <= 28 else 4 if number <= 30 else 4+(number-31)//4 if number <= 40
              else 4+(number-41)//7 if number <= 60 else 5+(number-61)//7 if number <= 80
              else 6+(number-81)//5)
    target = min(target, len(active)//2)
    rng = random.Random(270_000 + number*7919)
    for attempt in range(400):
        level["cells"] = [True] * (size*size)
        count = min(len(active), target + attempt % 3)
        for tap in rng.sample(active, count):
            for cell in affected(level, tap):
                level["cells"][cell] = not level["cells"][cell]
        solution = shortest_solution(level)
        uses_new_tile = number not in (36, 37, 38) or bool(set(solution) & set(level["verticals"]))
        if len(solution) == target and uses_new_tile:
            break
    else:
        raise ValueError(f"Couldn't author the intended difficulty for level {number}")
    if level.get("pearlTarget") is not None and len(solution) > level["pearlTarget"]:
        raise ValueError(f"Unreachable pearl target at level {number}")
    if len(solution) > level["tapLimit"]:
        raise ValueError(f"Tap budget too small at level {number}")
    level["contentRevision"] = 8 if number in CUSTOM_SHAPES else 7
    if not level["verticals"]:
        del level["verticals"]
    for key in ("rowCorals", "columnCorals"):
        level.pop(key, None)
    return (number, name, len(active), len(solution))


def author_extension(level):
    """A gentle introduction, practice, then selective combinations—not a stack."""
    n = level["level"]
    # name, footprint, ingredients, shortest solution length
    plans = {
        46: ("Square reef", ["#####"]*5, ("vertical", "current"), 4),
        47: ("Round reef", LARGE[0][1], ("vertical", "current", "stone"), 5),
        48: ("Reef ribbon", LARGE[3][1], ("vertical", "current"), 5),
        49: ("Square reef", ["#####"]*5, (), 5),
        50: ("Sloping shelf", LARGE[1][1], ("vertical", "current", "stone"), 6),
        51: ("Coral arch", LARGE[6][1], ("vertical", "current"), 6),
        52: ("Square reef", ["####"]*4, ("star",), 3),
        53: ("Square reef", ["####"]*4, ("star", "stone"), 4),
        54: ("Square reef", ["####"]*4, ("star", "stone"), 4),
        55: ("Round reef", LARGE[0][1], ("star", "vertical"), 5),
        56: ("Square reef", ["#####"]*5, ("star", "current"), 5),
        57: ("Little cove", LARGE[4][1], (), 5),
        58: ("Square reef", ["#####"]*5, ("star", "vertical", "current", "stone"), 6),
        59: ("Coral arch", LARGE[6][1], ("star", "stone"), 6),
        60: ("Square reef", ["#####"]*5, ("line",), 3),
        61: ("Round reef", LARGE[0][1], ("row", "vertical", "stone"), 4),
        62: ("Sloping shelf", LARGE[1][1], ("column", "current", "star"), 5),
        63: ("Small square", ["####"]*4, ("star", "stone"), 4),
        64: ("Coral loop", [".###.", "#####", "##.##", "#####", ".###."], ("line", "vertical"), 5),
        65: ("Square reef", ["#####"]*5, ("row", "current", "star", "stone"), 5),
        66: ("Crescent cove", [".####", "#####", "###..", "#####", ".####"], ("column", "vertical", "star"), 6),
        67: ("Diamond reef", LARGE[5][1], ("star",), 4),
        68: ("Square reef", ["#####"]*5, ("line", "star", "stone"), 6),
        69: ("Reef ribbon", LARGE[3][1], ("row", "vertical", "current"), 6),
        70: ("Round reef", LARGE[0][1], ("line", "vertical", "current", "star"), 7),
    }
    name, pattern, mix, target = plans[n]
    size = len(pattern)
    slots = {r*size+c for r, row in enumerate(pattern) for c, v in enumerate(row) if v == "#"}
    assert connected(slots, size)
    level.update(size=size, gaps=sorted(set(range(size*size))-slots),
                 stones=[0, size*size-1] if "stone" in mix else [],
                 verticals=[6] if "vertical" in mix else [],
                 currents=[18] if "current" in mix else [],
                 stars=([5, 10] if n in (54,63) else [7,17] if n==67 else [5] if size == 4 else [12]) if "star" in mix else [],
                 rowCorals=[11] if "line" in mix or "row" in mix else [],
                 columnCorals=[8] if "line" in mix or "column" in mix else [],
                 feature="mixed" if len(mix)>1 else mix[0] if mix else "classic",
                 contentRevision=10 if n>60 else 9, tapLimit=38 if n>60 else 34)
    place_markers(level, slots)
    active = sorted(slots-set(level["stones"]))
    required = (["verticals", "currents"] if n in (46,47,48) else
                ["stars"] if 52<=n<=56 else ["rowCorals", "columnCorals"] if n==60 else [])
    if n > 60:
        required = [k for k in ("verticals", "currents", "stars", "rowCorals", "columnCorals") if level[k]]
    rng = random.Random(460_000+n*7919)
    for attempt in range(4000):
        level["cells"] = [True]*(size*size)
        for tap in rng.sample(active, target+attempt%2):
            for cell in affected(level,tap): level["cells"][cell] ^= True
        solution = shortest_solution(level)
        if len(solution)==target and all(set(solution)&set(level[k]) for k in required): break
    else: raise ValueError(f"Couldn't author level {n}")
    assert len(solution)<=level["tapLimit"]
    assert level.get("pearlTarget") is None or len(solution)<=level["pearlTarget"]
    for key in ("verticals", "rowCorals", "columnCorals"):
        if not level[key]: level.pop(key)
    return (n, name, len(active), len(solution))



# User-approved 71–100: familiar squares, shaped reefs and breathers.
# Counts: row, column, up/down, left/right, diagonal, burst, pebbles.
FINAL_PLANS = {
    71:("Small square",["####"]*4,(0,0,0,0,0,0,0),3),
    72:("Crescent cove",[".####","#####","###..","#####",".####"],(1,0,0,0,1,0,2),4),
    73:("Square reef",["#####"]*5,(0,1,0,2,0,0,0),5),
    74:("Diamond reef",LARGE[5][1],(0,0,1,0,2,0,0),4),
    75:("Sloping shelf",LARGE[1][1],(2,0,0,0,0,0,0),5),
    76:("Coral fan",LARGE[2][1],(0,0,0,0,0,0,2),3),
    77:("Square reef",["#####"]*5,(0,2,0,1,0,0,0),5),
    78:("Coral loop",[".###.","#####","##.##","#####",".###."],(1,0,0,0,1,0,0),5),
    79:("Reef ribbon",LARGE[3][1],(0,0,2,2,0,0,2),6),
    80:("Round reef",LARGE[0][1],(1,1,0,0,2,0,0),6),
    81:("Small square",["####"]*4,(0,0,0,0,1,0,0),4),
    82:("Split lagoon",[".###.","#####","##.##","#.###",".###."],(1,1,0,0,0,0,2),5),
    83:("Square reef",["#####"]*5,(2,0,1,0,0,0,0),6),
    84:("Crescent cove",[".####","#####","###..","#####",".####"],(0,0,0,1,2,0,2),6),
    85:("Small square",["####"]*4,(0,0,0,0,0,1,0),2),
    86:("Clipped shore",[".###","####","####","###."],(0,0,0,0,0,1,0),3),
    87:("Small square",["####"]*4,(0,0,0,0,0,2,0),4),
    88:("Round reef",LARGE[0][1],(0,0,0,0,0,1,2),4),
    89:("Coral fan",LARGE[2][1],(0,0,0,0,0,0,0),3),
    90:("Round reef",LARGE[0][1],(1,0,0,0,0,1,0),5),
    91:("Small square",["####"]*4,(0,0,0,0,0,0,2),3),
    92:("Reef ribbon",LARGE[3][1],(1,0,1,1,0,1,0),6),
    93:("Square reef",["#####"]*5,(0,2,0,0,2,0,0),7),
    94:("Diamond reef",LARGE[5][1],(0,0,2,2,1,0,2),6),
    95:("Coral loop",[".###.","#####","##.##","#####",".###."],(2,1,0,0,0,1,0),7),
    96:("Little cove",LARGE[4][1],(0,0,0,1,1,0,0),4),
    97:("Square reef",["#####"]*5,(1,1,0,0,2,0,2),7),
    98:("Split lagoon",[".###.","#####","##.##","#.###",".###."],(2,0,1,1,0,1,0),7),
    99:("Small coral fan",[".##.","####","####","####"],(0,0,0,0,0,0,0),3),
    100:("Round reef",LARGE[0][1],(1,1,1,1,1,1,2),8),
}

def author_finale(level):
    n=level["level"]
    name,pattern,counts,target=FINAL_PLANS[n]
    size=len(pattern)
    slots={r*size+c for r,row in enumerate(pattern) for c,v in enumerate(row) if v=="#"}
    assert connected(slots,size)
    keys=["rowCorals","columnCorals","verticals","currents","stars","burstCorals","stones"]
    desired=dict(zip(keys,counts))
    anchors={"stones":[0,size*size-1], "rowCorals":[11,16],"columnCorals":[8,6],
             "verticals":[6,18],"currents":[18,8],"stars":[7,17],
             "burstCorals":[5,10] if size==4 else [12,13]}
    if n==86:anchors["burstCorals"]=[6]
    if n==88:anchors["stones"]=[6,18]
    rng=random.Random(710_000+n*7919)
    # Place the teaching pieces where their effect is legible. Only different
    # rows/columns receive repeated whole-line tiles; every chosen tile matters.
    for layout_try in range(120):
        occupied=set();chosen={k:[] for k in keys}
        for kind in ["stones","burstCorals","verticals","currents","stars","rowCorals","columnCorals"]:
            for ordinal in range(desired[kind]):
                anchor=anchors[kind][ordinal]
                candidates=sorted(slots-occupied,key=lambda i:(abs(i//size-anchor//size)+abs(i%size-anchor%size),i))
                if layout_try: rng.shuffle(candidates)
                valid=[]
                for i in candidates:
                    r,c=divmod(i,size);available=slots-set(chosen["stones"])
                    if kind=="stones" and not connected(slots-occupied-{i},size):continue
                    if kind=="verticals" and not {i-size,i+size}<=available:continue
                    if kind=="currents" and not (c>0 and c<size-1 and {i-1,i+1}<=available):continue
                    if kind=="rowCorals" and (any(x//size==r for x in chosen[kind]) or sum(x//size==r for x in available)<3):continue
                    if kind=="columnCorals" and (any(x%size==c for x in chosen[kind]) or sum(x%size==c for x in available)<3):continue
                    if kind=="burstCorals":
                        reach={x for x in available if abs(x//size-r)<=1 and abs(x%size-c)<=1}
                        if len(reach)<(9 if n in (85,86,87) else 6):continue
                    if kind=="stars" and sum(abs(x//size-r)==1 and abs(x%size-c)==1 for x in available)<2:continue
                    valid.append(i)
                if not valid:break
                chosen[kind].append(valid[0]);occupied.add(valid[0])
        if any(len(chosen[k])!=desired[k] for k in keys):continue
        level.update(size=size,gaps=sorted(set(range(size*size))-slots),**chosen,
                     contentRevision=11,tapLimit=38 if n<=80 else 42)
        types=[k for k in keys if chosen[k]]
        features={"burstCorals":"burst","rowCorals":"line","columnCorals":"line","stars":"star",
                  "verticals":"vertical","currents":"current","stones":"stone"}
        level["feature"]="mixed" if len(types)>1 else features[types[0]] if types else "classic"
        active=sorted(slots-set(chosen["stones"]))
        required=set(x for k in keys if k!="stones" for x in chosen[k])
        for attempt in range(600):
            taps=sorted(required)+rng.sample(sorted(set(active)-required),target-len(required))
            level["cells"]=[True]*(size*size)
            for tap in taps:
                for cell in affected(level,tap):level["cells"][cell]^=True
            solution=shortest_solution(level)
            if len(solution)==target and required<=set(solution):break
        else:continue
        break
    else:raise ValueError(f"Couldn't author level {n}")
    # Occasional optional pearl goals, verified against the real shortest solution.
    level["pearlTarget"]=target+2 if n in (75,80,90,95,100) else None
    for key in ("verticals","rowCorals","columnCorals","burstCorals"):
        if not level[key]:level.pop(key)
    return (n,name,len(active),len(solution))


def main():
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument("--from-level",type=int,default=27)
    args=parser.parse_args()
    levels = json.loads(PACK.read_text())
    summary = [result for level in levels if level["level"]>=args.from_level and (result := author(level))]
    PACK.write_text(json.dumps(levels, indent=2) + "\n")
    squares = sum("square" in row[1].lower() for row in summary)
    print(f"Authored levels {args.from_level}–{PLAYABLE_LIMIT}: {squares} square and {len(summary)-squares} shaped; earlier levels and later drafts are unchanged.")
    print("Up/down coral:", [(p["level"], p["verticals"]) for p in levels if p.get("verticals")])
    print("First layouts:", summary[:8])
    print("Coral counts:", min(row[2] for row in summary), "to", max(row[2] for row in summary))
    print("Shortest solutions:", min(row[3] for row in summary), "to", max(row[3] for row in summary))


if __name__ == "__main__":
    main()
