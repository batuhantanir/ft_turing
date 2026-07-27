open Types
open Errors

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
