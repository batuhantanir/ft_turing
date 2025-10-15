let () =
  let (jsonfile, input) = Usage_help.parse_args () in
  
  match Json_parser.parse_file jsonfile with
  | Error msg ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
  | Ok json ->
      (match Json_parser.validate_machine json with
      | Error msg ->
          Printf.eprintf "Validation error: %s\n" msg;
          exit 1
      | Ok () ->
          match Json_parser.parse_machine json with
          | Error msg ->
              Printf.eprintf "Machine parse error: %s\n" msg;
              exit 1
          | Ok machine ->
              Info.print_header machine.Json_parser.name;
              
              let transitions_tuples = List.map (fun (state, trans_list) ->
                let tuples = List.map (fun (t : Json_parser.transition) ->
                  (t.read, t.to_state, t.write, t.action)
                ) trans_list in
                (state, tuples)
              ) machine.Json_parser.transitions in
              
              Info.print_machine_info 
                machine.Json_parser.alphabet
                machine.Json_parser.states
                machine.Json_parser.initial
                machine.Json_parser.finals
                transitions_tuples;
      )