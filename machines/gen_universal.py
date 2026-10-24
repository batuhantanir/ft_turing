import argparse
import json

STATE_LETTERS = "abcdefghijkmnopqstuvwxyz"
FINAL_CODE = "z"
SYMBOL_CODES = "0123"


def build_utm():
    # This machine is independent of the description placed on its tape.
    target_states = list(STATE_LETTERS)
    target_finals = {FINAL_CODE}
    code = {s: s for s in target_states}
    marker = {s: s.upper() for s in target_states}
    non_final = [s for s in target_states if s not in target_finals]
    SYMS = list(SYMBOL_CODES)

    CONTROL = {'#', '$', ':', ';', '!', '@', '_', '~', 'R', 'L'}
    for c in list(code.values()) + list(marker.values()) + SYMS:
        if c in CONTROL:
            raise ValueError(
                f"symbol/state code '{c}' collides with a reserved control character")

    states = {}

    ACTION_WORD = {"R": "RIGHT", "L": "LEFT"}

    def add(name, read, to_state, write, action):
        states.setdefault(name, []).append(
            {"read": read, "to_state": to_state, "write": write, "action": ACTION_WORD[action]})

    add("seek0", "#", "metadata_alphabet", "#", "R")
    for c in SYMS:
        add("metadata_alphabet", c, "metadata_alphabet", c, "R")
    add("metadata_alphabet", "!", "metadata_states", "!", "R")
    for c in target_states:
        add("metadata_states", c, "metadata_states", c, "R")
    add("metadata_states", "!", "metadata_finals", "!", "R")
    for c in target_states:
        add("metadata_finals", c, "metadata_finals", c, "R")
    add("metadata_finals", "!", "metadata_initial", "!", "R")
    for c in target_states:
        add("metadata_initial", c, f"metadata_initial_end_{c}", c, "R")
        add(f"metadata_initial_end_{c}", "!", f"seek_marker_{c}", "!", "R")
        seek_chars = {'@', '$', ':', ';', 'R', 'L', '~'} | set(code.values()) | set(SYMS)
        for item in sorted(seek_chars):
            add(f"seek_marker_{c}", item, f"seek_marker_{c}", item, "R")
        add(f"seek_marker_{c}", marker[c], f"read_{c}", marker[c], "R")

    for s in non_final:
        t = code[s]
        for sym in SYMS:
            add(f"read_{t}", sym, f"travelBack_{t}_{sym}", sym, "L")

    for sym in SYMS:
        add("read_z", sym, "final_back", sym, "L")
    final_back_chars = (CONTROL - {'#'}) | set(code.values()) | set(marker.values()) | set(SYMS)
    for c in sorted(final_back_chars):
        add("final_back", c, "final_back", c, "L")
    add("final_back", "#", "final_skip_alphabet", "#", "R")
    for c in SYMS:
        add("final_skip_alphabet", c, "final_skip_alphabet", c, "R")
    add("final_skip_alphabet", "!", "final_skip_states", "!", "R")
    for c in target_states:
        add("final_skip_states", c, "final_skip_states", c, "R")
        add("final_check", c, "final_found" if c == FINAL_CODE else "final_check", c, "R")
        add("final_found", c, "final_found", c, "R")
    add("final_skip_states", "!", "final_check", "!", "R")
    add("final_found", "!", "final_return", "!", "R")
    for c in sorted(final_back_chars - {marker[FINAL_CODE]}):
        add("final_return", c, "final_return", c, "R")
    add("final_return", marker[FINAL_CODE], "halt", marker[FINAL_CODE], "R")

    pass_left_data = {'~'} | set(SYMS) | set(marker.values())
    pass_left_rules = {':', ';', 'R', 'L'} | set(code.values()) | set(SYMS)
    for s in non_final:
        t = code[s]
        for sym in SYMS:
            combo = f"{t}_{sym}"
            for c in sorted(pass_left_data):
                add(f"travelBack_{combo}", c, f"travelBack_{combo}", c, "L")
            add(f"travelBack_{combo}", "$", f"travelBack2_{combo}", "$", "L")
            for c in sorted(pass_left_rules):
                add(f"travelBack2_{combo}", c, f"travelBack2_{combo}", c, "L")
            add(f"travelBack2_{combo}", "@", f"metadata_back_{combo}", "@", "L")

            metadata_chars = set(SYMS) | set(code.values()) | {'!'}
            for c in sorted(metadata_chars):
                add(f"metadata_back_{combo}", c, f"metadata_back_{combo}", c, "L")
            add(f"metadata_back_{combo}", "#", f"check_symbol_{combo}", "#", "R")
            for c in SYMS:
                next_state = (f"symbol_found_{combo}" if c == sym
                              else f"check_symbol_{combo}")
                add(f"check_symbol_{combo}", c, next_state, c, "R")
                add(f"symbol_found_{combo}", c, f"symbol_found_{combo}", c, "R")
            add(f"symbol_found_{combo}", "!", f"check_state_{combo}", "!", "R")
            for c in target_states:
                next_state = (f"state_found_{combo}" if c == t
                              else f"check_state_{combo}")
                add(f"check_state_{combo}", c, next_state, c, "R")
                add(f"state_found_{combo}", c, f"state_found_{combo}", c, "R")
                add(f"skip_finals_{combo}", c, f"skip_finals_{combo}", c, "R")
                add(f"skip_initial_{combo}", c, f"skip_initial_{combo}", c, "R")
            add(f"state_found_{combo}", "!", f"skip_finals_{combo}", "!", "R")
            add(f"skip_finals_{combo}", "!", f"skip_initial_{combo}", "!", "R")
            add(f"skip_initial_{combo}", "!", f"at_rules_{combo}", "!", "R")
            add(f"at_rules_{combo}", "@", f"cmp1_{combo}", "@", "R")

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
            for c in sorted(skip_chars):
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
                for c in sorted(dollar_pass):
                    add(f"toDollar_{t2}_{w}_{d}", c,
                        f"toDollar_{t2}_{w}_{d}", c, "R")
                add(f"toDollar_{t2}_{w}_{d}", "$",
                    f"atGap_{t2}_{w}_{d}", "$", "R")

                gap_pass = {'~'} | set(SYMS)
                for c in sorted(gap_pass):
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
    finals = ["halt"]
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
    return m


def encode_tape(rules, alphabet_codes, state_codes, final_codes, initial_code,
                input_syms, left_pad=3, right_pad=6):
    rule_text = "".join(
        f"{s}:{r}:{t}:{w}:{a};" for (s, r, t, w, a) in rules)

    data_syms = [SYMBOL_CODES[0]] * left_pad + list(input_syms) + [SYMBOL_CODES[0]] * right_pad
    marker = initial_code.upper()

    data = ""
    for i, sym in enumerate(data_syms):
        if i == left_pad:
            data += marker + sym
        else:
            if i == 0:
                data += sym
            else:
                data += "~" + sym
    data += "~"
    metadata = "!".join((
        "".join(alphabet_codes),
        "".join(state_codes),
        "".join(final_codes),
        initial_code,
    ))
    return "#" + metadata + "!@" + rule_text + "$" + data + "#"


def encode_machine(machine, input_text, left_pad=3, right_pad=6):
    states = machine["states"]
    finals = machine["finals"]
    alphabet = machine["alphabet"]
    blank = machine["blank"]

    if not states or len(states) != len(set(states)):
        raise ValueError("states must be nonempty and unique")
    if not alphabet or len(alphabet) != len(set(alphabet)):
        raise ValueError("alphabet must be nonempty and unique")
    if any(not isinstance(symbol, str) or len(symbol) != 1 for symbol in alphabet):
        raise ValueError("alphabet symbols must be one character")
    if blank not in alphabet:
        raise ValueError("blank must be in the alphabet")
    if machine["initial"] not in states or any(state not in states for state in finals):
        raise ValueError("initial and final states must be declared")
    if left_pad < 1 or right_pad < 1:
        raise ValueError("both tape padding values must be positive")

    non_final = [state for state in states if state not in finals]
    if len(non_final) > len(STATE_LETTERS) - 1:
        raise ValueError("machine exceeds the 23 non-final-state code capacity")
    if len(alphabet) > len(SYMBOL_CODES):
        raise ValueError("machine exceeds the four-symbol code capacity")

    state_codes = {state: STATE_LETTERS[i] for i, state in enumerate(non_final)}
    state_codes.update({state: FINAL_CODE for state in finals})
    symbol_codes = {blank: SYMBOL_CODES[0]}
    symbol_codes.update({
        symbol: SYMBOL_CODES[i + 1]
        for i, symbol in enumerate(s for s in alphabet if s != blank)
    })

    if any(symbol not in symbol_codes or symbol == blank for symbol in input_text):
        raise ValueError("input contains an undeclared or blank symbol")

    rules = []
    for state, transitions in machine["transitions"].items():
        if state not in state_codes:
            raise ValueError(f"undeclared transition state: {state}")
        reads = set()
        for transition in transitions:
            read = transition["read"]
            write = transition["write"]
            to_state = transition["to_state"]
            action = transition["action"]
            if read not in symbol_codes or write not in symbol_codes:
                raise ValueError("transition uses an undeclared symbol")
            if to_state not in state_codes or action not in ("LEFT", "RIGHT"):
                raise ValueError("transition has an undeclared state or action")
            if read in reads:
                raise ValueError(f"duplicate transition for ({state}, {read})")
            reads.add(read)
            rules.append((state_codes[state], symbol_codes[read],
                          state_codes[to_state], symbol_codes[write], action[0]))

    encoded_input = [symbol_codes[symbol] for symbol in input_text]
    return encode_tape(
        rules,
        [symbol_codes[symbol] for symbol in alphabet],
        list(dict.fromkeys(state_codes[state] for state in states)),
        list(dict.fromkeys(state_codes[state] for state in finals)),
        state_codes[machine["initial"]],
        encoded_input,
        left_pad=left_pad,
        right_pad=right_pad,
    )


def main():
    parser = argparse.ArgumentParser(description="Encode a machine and its input for the fixed tape interpreter")
    parser.add_argument("--machine", default="machines/unary_add.json")
    parser.add_argument("--input", default="11+1=")
    parser.add_argument("--output", default="machines/universal.json")
    parser.add_argument("--left-pad", type=int, default=3)
    parser.add_argument("--right-pad", type=int, default=6)
    parser.add_argument("--tape-only", action="store_true")
    args = parser.parse_args()

    try:
        with open(args.machine, encoding="utf-8") as source:
            target = json.load(source)
        tape = encode_machine(target, args.input, args.left_pad, args.right_pad)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))

    if args.tape_only:
        print(tape)
        return

    with open(args.output, "w", encoding="utf-8") as target_file:
        json.dump(build_utm(), target_file, separators=(",", ":"))
        target_file.write("\n")
    print(f"Generated fixed machine: {args.output}")
    print("Run it with this encoded tape:")
    print(f"./ft_turing {args.output} '{tape}'")


if __name__ == "__main__":
    main()
