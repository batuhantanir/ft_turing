open Types
open Tape
open Utils

let run m tape =
  let max_steps = 2_000_000 in

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
