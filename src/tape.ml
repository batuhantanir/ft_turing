open Errors
open Types

let tape_of_input m input =
  if String.length input = 0 then
    raise (Invalid_input "input must not be empty");
  let chars =
    List.init (String.length input) (fun i -> String.make 1 input.[i])
  in
  List.iter
    (fun c ->
      if not (List.mem c m.alphabet) then
        raise
          (Invalid_input (Printf.sprintf "character '%s' not in alphabet" c));
      if c = m.blank then
        raise (Invalid_input "blank character must not be part of the input"))
    chars;
  match chars with
  | [] -> raise (Invalid_input "empty input")
  | h :: t -> { left = []; head = h; right = t }

let move_left m t =
  match t.left with
  | [] -> { left = []; head = m.blank; right = t.head :: t.right }
  | h :: rest -> { left = rest; head = h; right = t.head :: t.right }

let move_right m t =
  match t.right with
  | [] -> { left = t.head :: t.left; head = m.blank; right = [] }
  | h :: rest -> { left = t.head :: t.left; head = h; right = rest }

let write_head t symbol = { t with head = symbol }

let string_of_tape t =
  let left_str = String.concat "" (List.rev t.left) in
  let right_str = String.concat "" t.right in

  let tape_content = left_str ^ "<" ^ t.head ^ ">" ^ right_str in

  let target_width = 20 in
  let current_len = String.length tape_content in

  let pad_len = max 0 (target_width - current_len) in

  let padding = String.make pad_len '.' in

  "[" ^ tape_content ^ padding ^ "]"
