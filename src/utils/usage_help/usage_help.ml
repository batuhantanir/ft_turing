let usage_msg = "ft_turing [-h] jsonfile input"

let ft_turing_help () =
  print_endline (Printf.sprintf "\nusage: %s" usage_msg);
  print_endline "\npositional arguments:";
  print_endline "  jsonfile            json description of the machine";
  print_endline "  input               input of the machine";
  print_endline "\noptional arguments:";
  print_endline "  -h, --help          show this help message and exit";
  exit 0

let parse_args () =
  let args = Array.to_list Sys.argv in
  let args = List.tl args in
  
  let rec parse positional_args = function
    | [] -> List.rev positional_args
    | "-h" :: _ | "--help" :: _ -> 
        ft_turing_help ()
    | arg :: rest when String.length arg > 0 && arg.[0] = '-' ->
        Printf.eprintf "ft_turing: error: unrecognized arguments: %s\n" arg;
        exit 1
    | arg :: rest ->
        parse (arg :: positional_args) rest
  in
  
  let positional = parse [] args in
  
  match positional with
  | [jsonfile; input] -> (jsonfile, input)
  | [] | [_] ->
      Printf.eprintf "ft_turing: error: the following arguments are required: jsonfile, input\n";
      exit 1
  | first :: second :: third :: _ ->
      Printf.eprintf "ft_turing: error: too many positional arguments: %s\n" third;
      exit 1