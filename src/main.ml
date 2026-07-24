
module Json = struct
  exception Json_error of string

  let from_file filename =
    let ic = open_in filename in
    let length = in_channel_length ic in
    let contents = really_input_string ic length in
    close_in ic;
    if String.trim contents = "" then raise (Json_error "empty JSON file");
    contents

  let to_string json = json
end

exception Invalid_machine of string
exception Invalid_input of string

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
      Printf.printf "Machine description:\n%s\n" (Json.to_string json);
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