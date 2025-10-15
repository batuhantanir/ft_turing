open Yojson.Basic.Util

type transition = {
  read: string;
  to_state: string;
  write: string;
  action: string;
}

type machine = {
  name: string;
  alphabet: string list;
  blank: string;
  states: string list;
  initial: string;
  finals: string list;
  transitions: (string * transition list) list;
}

let parse_file filename =
  try
    let json = Yojson.Basic.from_file filename in
    Ok json
  with
  | Sys_error msg -> Error ("File error: " ^ msg)
  | Yojson.Json_error msg -> Error ("JSON parse error: " ^ msg)
  | e -> Error ("Unknown error: " ^ Printexc.to_string e)

let parse_transition json =
  try
    let read = json |> member "read" |> to_string in
    let to_state = json |> member "to_state" |> to_string in
    let write = json |> member "write" |> to_string in
    let action = json |> member "action" |> to_string in
    Ok { read; to_state; write; action }
  with
  | Type_error (msg, _) -> Error ("Transition parse error: " ^ msg)
  | e -> Error ("Transition error: " ^ Printexc.to_string e)

let parse_transitions json =
  try
    let transitions_obj = json |> member "transitions" |> to_assoc in
    let result = List.map (fun (state, trans_list) ->
      let transitions = trans_list |> to_list |> List.map (fun t ->
        match parse_transition t with
        | Ok trans -> trans
        | Error msg -> failwith msg
      ) in
      (state, transitions)
    ) transitions_obj in
    Ok result
  with
  | Type_error (msg, _) -> Error ("Transitions parse error: " ^ msg)
  | Failure msg -> Error msg
  | e -> Error ("Transitions error: " ^ Printexc.to_string e)

let parse_machine json =
  try
    let name = json |> member "name" |> to_string in
    let alphabet = json |> member "alphabet" |> to_list |> List.map to_string in
    let blank = json |> member "blank" |> to_string in
    let states = json |> member "states" |> to_list |> List.map to_string in
    let initial = json |> member "initial" |> to_string in
    let finals = json |> member "finals" |> to_list |> List.map to_string in
    match parse_transitions json with
    | Error msg -> Error msg
    | Ok transitions ->
        Ok { name; alphabet; blank; states; initial; finals; transitions }
  with
  | Type_error (msg, _) -> Error ("Machine parse error: " ^ msg)
  | e -> Error ("Machine error: " ^ Printexc.to_string e)

let validate_machine json =
  try
    let required_fields = ["name"; "alphabet"; "blank"; "states"; "initial"; "finals"; "transitions"] in
    let obj = Yojson.Basic.Util.to_assoc json in
    let existing_fields = List.map fst obj in
    let missing = List.filter (fun f -> not (List.mem f existing_fields)) required_fields in
    if missing = [] then Ok ()
    else Error ("Missing required fields: " ^ String.concat ", " missing)
  with
  | Type_error (msg, _) -> Error ("Validation error: " ^ msg)
  | e -> Error ("Validation error: " ^ Printexc.to_string e)

let json_to_string json =
  Yojson.Basic.to_string json

let print_machine m =
  Printf.printf "Machine: %s\n" m.name;
  Printf.printf "Alphabet: [%s]\n" (String.concat ", " m.alphabet);
  Printf.printf "Blank: %s\n" m.blank;
  Printf.printf "States: [%s]\n" (String.concat ", " m.states);
  Printf.printf "Initial: %s\n" m.initial;
  Printf.printf "Finals: [%s]\n" (String.concat ", " m.finals);
  Printf.printf "Transitions: %d states\n" (List.length m.transitions)
