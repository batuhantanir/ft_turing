open Types
open Utils
open Tape

let usage () =
  print_string
    "usage: ft_turing [-h] jsonfile input\n\n\
     positional arguments:\n\
    \  jsonfile              json description of the machine\n\
    \  input                 input of the machine\n\n\
     optional arguments:\n\
    \  -h, --help            show this help message and exit\n"

let print_header m =
  let width = 80 in
  let bar = String.make width '*' in
  let center s =
    let pad = max 0 ((width - 2 - String.length s) / 2) in
    Printf.sprintf "*%s%s%s*" (String.make pad ' ') s
      (String.make (width - 2 - pad - String.length s) ' ')
  in
  Printf.printf "%s\n" bar;
  Printf.printf "*%s*\n" (String.make (width - 2) ' ');
  Printf.printf "%s\n" (center m.name);
  Printf.printf "*%s*\n" (String.make (width - 2) ' ');
  Printf.printf "%s\n" bar;
  Printf.printf "Alphabet: [ %s ]\n" (String.concat ", " m.alphabet);
  Printf.printf "States : [ %s ]\n" (String.concat ", " m.states);
  Printf.printf "Initial : %s\n" m.initial;
  Printf.printf "Finals : [ %s ]\n" (String.concat ", " m.finals);
  List.iter
    (fun (state, trs) ->
      List.iter
        (fun t ->
          Printf.printf "(%s, %s) -> (%s, %s, %s)\n" state t.read t.to_state
            t.write
            (string_of_direction t.action))
        trs)
    m.transitions;
  Printf.printf "%s\n" bar

let run m tape =
  let max_steps = 2000 in

  let rec loop state t steps =
    if List.mem state m.finals then begin
      Printf.printf "%s Machine halted in final state '%s'\n" (string_of_tape t)
        state;
      true
    end
    else if steps > max_steps then begin
      Printf.printf
        "\n%s Machine ABORTED: exceeded %d steps (possible infinite loop)\n"
        (string_of_tape t) max_steps;
      false
    end
    else
      let symbol = t.head in

      match find_transition m state symbol with
      | None ->
          Printf.printf
            "%s Machine BLOCKED: no transition for (state=%s, read=%s)\n"
            (string_of_tape t) state symbol;
          false
      | Some tr ->
          Printf.printf "%s (%s, %s) -> (%s, %s, %s)\n" (string_of_tape t) state
            symbol tr.to_state tr.write
            (string_of_direction tr.action);
          let t' = write_head t tr.write in
          let t'' =
            match tr.action with
            | Left -> move_left m t'
            | Right -> move_right m t'
          in
          loop tr.to_state t'' (steps + 1)
  in

  loop m.initial tape 0
