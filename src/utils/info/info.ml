let box_width = 80 

let horizontal_border () =
  Printf.printf "%s\n" (String.make box_width '*')

let print_transition (state, read, write, action, to_state) =
      Printf.printf "(%s, %s) -> (%s, %s, %s)\n"
      state
      read
      to_state
      write
      action

let print_header title =
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

    horizontal_border ();
    Printf.printf "*%s*\n" (String.make (box_width - 2) ' ');
    Printf.printf "%s\n" centered_title;
    Printf.printf "*%s*\n" (String.make (box_width - 2) ' ');
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
  
let print_all_transitions transitions =
  Printf.printf "\n";
  Printf.printf "========================================\n";
  Printf.printf "* TRANSITIONS\n";
  Printf.printf "========================================\n";
  
  List.iter (fun (state, trans_list) ->
    Printf.printf "\nState: %s\n" state;
    List.iter (fun (read, to_state, write, action) ->
      Printf.printf "(%s, %s) -> (%s, %s, %s)\n"
        state
        read
        write
        action
        to_state
    ) trans_list
  ) transitions;
  
  Printf.printf "========================================\n"