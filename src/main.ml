(* Types definition *)

type direction = Left | Right

type transition = {
  read : string;
  to_state : string;
  write : string;
  action : direction;
}

type machine = {
  name : string;
  alphabet : string list;
  blank : string;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string * transition list) list;
}


exception Invalid_machine of string
exception Invalid_input of string

let direction_of_string = function
  | "LEFT" -> Left
  | "RIGHT" -> Right
  | s -> raise (Invalid_machine (Printf.sprintf "invalid action '%s' (expected LEFT or RIGHT)" s))

let parse_transition json =
  {
    read = Json.member "read" json |> Json.to_string;
    to_state = Json.member "to_state" json |> Json.to_string;
    write = Json.member "write" json |> Json.to_string;
    action = Json.member "action" json |> Json.to_string |> direction_of_string;
  }

let parse_machine json =
  let name = Json.member "name" json |> Json.to_string in
  let alphabet = Json.member "alphabet" json |> Json.to_list |> List.map Json.to_string in
  let blank = Json.member "blank" json |> Json.to_string in
  let states = Json.member "states" json |> Json.to_list |> List.map Json.to_string in
  let initial = Json.member "initial" json |> Json.to_string in
  let finals = Json.member "finals" json |> Json.to_list |> List.map Json.to_string in
  let transitions_json = Json.member "transitions" json |> Json.to_assoc in
  let transitions =
    List.map
      (fun (state, trans_list) ->
        (state, trans_list |> Json.to_list |> List.map parse_transition))
      transitions_json
  in
  { name; alphabet; blank; states; initial; finals; transitions }

let usage () =
  print_string
    "usage: ft_turing [-h] jsonfile input\n\n\
     positional arguments:\n\
    \  jsonfile              json description of the machine\n\
    \  input                 input of the machine\n\n\
     optional arguments:\n\
    \  -h, --help            show this help message and exit\n"

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  match args with
  | [] | [ "-h" ] | [ "--help" ] -> usage ()
  | [ jsonfile; input ] -> (
    try
      let json = Json.from_file jsonfile in
      let m = parse_machine json in
      Printf.eprintf "Machine '%s' loaded successfully.\n" m.name;
      Printf.eprintf "Input: %s\n" input;
      Printf.eprintf "machine.alphabet: %s\n" (String.concat ", " m.alphabet);
      exit (0)
      with
      | Sys_error msg ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
    | Json.Json_error msg ->
      Printf.eprintf "Error: invalid JSON: %s\n" msg;
      exit 1
    | Invalid_machine msg ->
      Printf.eprintf "Error: invalid machine description: %s\n" msg;
      exit 1
    | Invalid_input msg ->
      Printf.eprintf "Error: invalid input: %s\n" msg;
      exit 1
    | e ->
      Printf.eprintf "Error: unexpected failure: %s\n" (Printexc.to_string e);
      exit 1)
  | _ ->
    Printf.eprintf "Error: wrong number of arguments\n\n";
    usage ();
    exit 1