open Types
open Tape
open Utils

let run m tape =
  let rec loop state t =
    if List.mem state m.finals then begin
      Printf.printf "%s Machine halted in final state '%s'\n" (string_of_tape m t)
        state;
      true
    end
    else
      let symbol = t.head in

      match find_transition m state symbol with
      | None ->
          Printf.printf
            "%s Machine BLOCKED: no transition for (state=%s, read=%s)\n"
            (string_of_tape m t) state symbol;
          false
      | Some tr ->
          Printf.printf "%s (%s, %s) -> (%s, %s, %s)\n" (string_of_tape m t) state
            symbol tr.to_state tr.write
            (string_of_direction tr.action);
          let t' = write_head t tr.write in
          let t'' =
            match tr.action with
            | Left -> move_left m t'
            | Right -> move_right m t'
          in
          loop tr.to_state t''
  in

  loop m.initial tape
