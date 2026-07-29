open Types

let string_of_direction = function Left -> "LEFT" | Right -> "RIGHT"

let find_transition m state symbol =
  match List.assoc_opt state m.transitions with
  | None -> None
  | Some trs -> List.find_opt (fun t -> t.read = symbol) trs
