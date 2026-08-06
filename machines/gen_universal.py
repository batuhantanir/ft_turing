import json
import sys

STATE_LETTERS = "abcdefghijkmnopqstuvwxyz"

def build_utm(target_states, target_finals, target_alphabet, target_blank, rules,
              max_right_pad=6):
    if len(target_states) > len(STATE_LETTERS):
        raise ValueError("too many simulated states for reserved code space")
    code = {s: STATE_LETTERS[i] for i, s in enumerate(target_states)}
    marker = {s: code[s].upper() for s in target_states}
    non_final = [s for s in target_states if s not in target_finals]
    SYMS = list(target_alphabet)

    CONTROL = {'#', '$', ':', ';', '_', '~', 'R', 'L'}
    for c in list(code.values()) + list(marker.values()) + SYMS:
        if c in CONTROL:
            raise ValueError(
                f"symbol/state code '{c}' collides with a reserved control character")

    states = {}

    ACTION_WORD = {"R": "RIGHT", "L": "LEFT"}

    def add(name, read, to_state, write, action):
        states.setdefault(name, []).append(
            {"read": read, "to_state": to_state, "write": write, "action": ACTION_WORD[action]})

    skip_syms_seek0 = {'#', '$', ':', ';', 'R',
                       'L', '~'} | set(code.values()) | set(SYMS)
    for c in skip_syms_seek0:
        add("seek0", c, "seek0", c, "R")
    for s in target_states:
        add("seek0", marker[s], f"read_{code[s]}", marker[s], "R")

    for s in non_final:
        t = code[s]
        for sym in SYMS:
            add(f"read_{t}", sym, f"travelBack_{t}_{sym}", sym, "L")

    pass_left_data = {'~'} | set(SYMS) | set(marker.values())
    pass_left_rules = {':', ';', 'R', 'L'} | set(code.values()) | set(SYMS)
    for s in non_final:
        t = code[s]
        for sym in SYMS:
            combo = f"{t}_{sym}"
            for c in pass_left_data:
                add(f"travelBack_{combo}", c, f"travelBack_{combo}", c, "L")
            add(f"travelBack_{combo}", "$", f"travelBack2_{combo}", "$", "L")
            for c in pass_left_rules:
                add(f"travelBack2_{combo}", c, f"travelBack2_{combo}", c, "L")
            add(f"travelBack2_{combo}", "#", f"cmp1_{combo}", "#", "R")

            for c in code.values():
                if c == t:
                    add(f"cmp1_{combo}", c, f"toRead_{combo}", c, "R")
                else:
                    add(f"cmp1_{combo}", c, f"skip_{combo}", c, "R")
            add(f"toRead_{combo}", ":", f"cmp2_{combo}", ":", "R")

            for c in SYMS:
                if c == sym:
                    add(f"cmp2_{combo}", c, "toTostate", c, "R")
                else:
                    add(f"cmp2_{combo}", c, f"skip_{combo}", c, "R")

            skip_chars = {':'} | set(code.values()) | set(SYMS) | {'R', 'L'}
            for c in skip_chars:
                add(f"skip_{combo}", c, f"skip_{combo}", c, "R")
            add(f"skip_{combo}", ";", f"cmp1_{combo}", ";", "R")

    add("toTostate", ":", "readTostate", ":", "R")
    for s2 in target_states:
        t2 = code[s2]
        add("readTostate", t2, f"toWrite_{t2}", t2, "R")
        add(f"toWrite_{t2}", ":", f"readWrite_{t2}", ":", "R")
        for w in SYMS:
            add(f"readWrite_{t2}", w, f"toAction_{t2}_{w}", w, "R")
            add(f"toAction_{t2}_{w}", ":", f"readAction_{t2}_{w}", ":", "R")
            for d in ("R", "L"):
                add(f"readAction_{t2}_{w}", d,
                    f"toDollar_{t2}_{w}_{d}", d, "R")
                dollar_pass = {':', ';'} | set(
                    code.values()) | set(SYMS) | {'R', 'L'}
                for c in dollar_pass:
                    add(f"toDollar_{t2}_{w}_{d}", c,
                        f"toDollar_{t2}_{w}_{d}", c, "R")
                add(f"toDollar_{t2}_{w}_{d}", "$",
                    f"atGap_{t2}_{w}_{d}", "$", "R")

                gap_pass = {'~'} | set(SYMS)
                for c in gap_pass:
                    add(f"atGap_{t2}_{w}_{d}", c,
                        f"atGap_{t2}_{w}_{d}", c, "R")
                for s3 in target_states:
                    add(f"atGap_{t2}_{w}_{d}",
                        marker[s3], f"atData_{t2}_{w}_{d}", "~", "R")

                for c in SYMS:
                    if d == "R":
                        add(f"atData_{t2}_{w}_{d}", c,
                            f"placeMarkerR_{t2}", w, "R")
                    else:
                        add(f"atData_{t2}_{w}_{d}", c,
                            f"placeMarkerL1_{t2}", w, "L")

    for s2 in target_states:
        t2 = code[s2]
        add(f"placeMarkerR_{t2}", "~", f"read_{t2}", marker[s2], "R")

        for c in {'~'}:
            add(f"placeMarkerL1_{t2}", c, f"placeMarkerL2_{t2}", c, "L")
        for c in SYMS:
            add(f"placeMarkerL2_{t2}", c, f"placeMarkerL3_{t2}", c, "L")
        add(f"placeMarkerL3_{t2}", "~", f"read_{t2}", marker[s2], "R")

    alphabet = sorted(CONTROL | set(code.values()) |
                      set(marker.values()) | set(SYMS))
    finals = [f"read_{code[s]}" for s in target_finals]
    all_states = sorted(set(states.keys()) | set(finals) | {"seek0"})

    m = {
        "name": "universal",
        "alphabet": alphabet,
        "blank": "_",
        "states": all_states,
        "initial": "seek0",
        "finals": finals,
        "transitions": states,
    }
    return m, code, marker


def encode_tape(rules, code, target_states, initial_state, input_syms, blank,
                right_pad=6):
    """Build the initial UTM tape string: '#' RULES '$' GAPDATA '#'."""
    rule_text = "".join(
        f"{code[s]}:{r}:{code[t]}:{w}:{a};" for (s, r, t, w, a) in rules)
    data_syms = list(input_syms) + [blank] * right_pad
    marker = code[initial_state].upper()
    data = marker + data_syms[0]
    for sym in data_syms[1:]:
        data += "~" + sym
    data += "~"
    return "#" + rule_text + "$" + data + "#"


if __name__ == "__main__":
    target_states = ["scanright", "scanend", "erase", "HALT"]
    target_finals = ["HALT"]
    target_alphabet = ["1", ".", "+"]
    target_blank = "."
    rules = [
        ("scanright", "1", "scanright", "1", "R"),
        ("scanright", "+", "scanend", "1", "R"),
        ("scanend", "1", "scanend", "1", "R"),
        ("scanend", ".", "erase", ".", "L"),
        ("erase", "1", "HALT", ".", "L"),
    ]
    m, code, marker = build_utm(
        target_states, target_finals, target_alphabet, target_blank, rules)
    outpath = sys.argv[1] if len(
        sys.argv) > 1 else "./machines/universal.json"
    with open(outpath, "w") as f:
        json.dump(m, f, indent=2)
    print(f"wrote {outpath}: {len(m['states'])} states, {len(m['alphabet'])} alphabet symbols",
          file=sys.stderr)

    tape = encode_tape(rules, code, target_states, "scanright", [
                       "1", "+", "1", "1"], ".", right_pad=6)
    print(tape)
