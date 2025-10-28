let box_width = 80 

let horizontal_border () =
  Printf.printf "%s\n" (String.make box_width '*')

let vertical_border () =
  Printf.printf "*%s*\n" (String.make (box_width - 2) ' ')

let vertical_border_with_title title = 
  let title_length = String.length title in
  
  if title_length >= box_width - 4 then
    Printf.printf "%s\n%s\n%s\n\n" "*" title "*"
  else
    let padding = (box_width - title_length - 2) / 2 in
    let remaining = box_width - title_length - 2 - padding in
    let centered_title = 
      Printf.sprintf "*%s%s%s*" 
        (String.make padding ' ') 
        title 
        (String.make remaining ' ') in
    Printf.printf "%s\n" centered_title

let print_transition (state, read, write, action, to_state) =
  Printf.printf "(%s, %s) -> (%s, %s, %s)\n"
  state
  read
  to_state
  write
  action

let print_header title =
    horizontal_border ();
    vertical_border ();
    vertical_border_with_title title;
    vertical_border ();
    horizontal_border ()

let print_machine_info alphabet states initial finals transitions =
  Printf.printf "Alphabet: [ %s ]\n" (String.concat ", " alphabet);
  Printf.printf "States: [ %s ]\n" (String.concat ", " states);
  Printf.printf "Initial: %s\n" initial;
  Printf.printf "Finals: [ %s ]\n" (String.concat ", " finals);
  List.iter (fun (state, trans_list) ->
    List.iter (fun (read, to_state, write, action) ->
      print_transition (state, read, write, action, to_state)
      ) trans_list
      ) transitions;
  horizontal_border ()

let create_tape_array input =
  Array.init 30 (fun i ->
    if i < String.length input then input.[i] else '.'
  )

let print_action_info step tape_string_raw state read write action to_state =
  let fixed_tape_length = 30 in
  
  let tape_string = 
    if String.length tape_string_raw < fixed_tape_length then
      tape_string_raw ^ String.make (fixed_tape_length - String.length tape_string_raw) '.'
    else
      String.sub tape_string_raw 0 fixed_tape_length
  in

  let len = String.length tape_string in
  let pos = if len = 0 then 0 else max 0 (min step (len - 1)) in

  let prefix = String.sub tape_string 0 pos in
  let current_char = String.make 1 tape_string.[pos] in
  let suffix = if pos + 1 <= len - 1 then String.sub tape_string (pos + 1) (len - pos - 1) else "" in
  let formatted_tape = prefix ^ "<" ^ current_char ^ ">" ^ suffix in
  Printf.printf "[%s] " formatted_tape;
  print_transition (state, read, write, action, to_state)
  
