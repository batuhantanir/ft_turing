# ft_turing

This project simulates a single-head, single-tape Turing machine described by a JSON file. The simulator is written in OCaml.

## Build and run

`make` builds the native program with `ocamlopt`; `make byte` builds `ft_turing.byte` with `ocamlc`. The Makefile checks for these tools and uses OPAM to install the compiler if needed.

```sh
make
./ft_turing --help
./ft_turing machines/unary_add.json '111+11='
```

The program prints the machine description and the tape with its head position before every transition. It reports a missing transition as a blocked machine. Invalid descriptions and inputs produce an error.

## Required machines

1. **Unary addition:** `machines/unary_add.json` computes `111+11=` as five unary ones.
2. **Palindrome:** `machines/palindrome.json` accepts a binary palindrome and writes `y` at the right end; it writes `n` for a non-palindrome.
3. **Language 0^n1^n:** `machines/zero_n_one_n.json` writes `y` for words such as `000111` and `n` otherwise.
4. **Language 0^(2n):** `machines/zero_pow_2n.json` writes `y` for an even number of zeroes and `n` for an odd number.
5. **Encoded interpreter:** `machines/universal.json` runs the unary-addition machine from an encoded description and input on its tape.

The supplied subtraction example is in `machines/unary_sub.json`.

## Encoded interpreter

`machines/universal.json` is fixed: it does not contain the unary-addition machine's transition table. The encoder in `machines/gen_universal.py` assigns codes to every declared alphabet symbol and state, then creates this tape:

```text
#alphabet!states!finals!initial!@transitions$data#
```

Each section contains the codes for the corresponding part of the simulated machine. An uppercase state code marks the simulated head in the data section. The interpreter reads the initial state, checks alphabet and state membership while executing transitions, and checks the final-state list before halting.

The supplied interpreter has room for 23 non-final states and four alphabet symbols. Its encoded input includes blank cells on both sides; increase `--left-pad` or `--right-pad` when the simulated machine needs more room. The required unary-addition machine fits within these limits.

To regenerate the fixed interpreter and run a unary addition:

```sh
python3 machines/gen_universal.py
./ft_turing machines/universal.json "$(python3 machines/gen_universal.py --input '11+1=' --tape-only)" | tail -n 1
```

The same interpreter can run a different description without regenerating its JSON:

```sh
./ft_turing machines/universal.json "$(python3 machines/gen_universal.py --machine machines/zero_pow_2n.json --input '0000' --tape-only)" | tail -n 1
```
