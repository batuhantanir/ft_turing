open Errors
open Types
open Parse
open Validate
open Tape
open Cli
open Machine_loop

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  match args with
  | [] | [ "-h" ] | [ "--help" ] -> usage ()
  | [ jsonfile; input ] -> (
      try
        let json = Json.from_file jsonfile in
        let m = Parse.parse_machine json in

        Validate.validate_machine m;

        let tape = tape_of_input m input in
        print_header m;

        let ok = run m tape in
        exit (if ok then 0 else 1)
      with
      | Sys_error msg ->
          Printf.eprintf "Error: %s\n" msg;
          exit 1
      | Errors.Json_error msg ->
          Printf.eprintf "Error: invalid JSON: %s\n" msg;
          exit 1
      | Errors.Invalid_machine msg ->
          Printf.eprintf "Error: invalid machine description: %s\n" msg;
          exit 1
      | Errors.Invalid_input msg ->
          Printf.eprintf "Error: invalid input: %s\n" msg;
          exit 1
      | e ->
          Printf.eprintf "Error: unexpected failure: %s\n"
            (Printexc.to_string e);
          exit 1)
  | _ ->
      Printf.eprintf
        "Error: wrong number of arguments ./ft_turing --help for usage\n";
      exit 1
