open Errors
open Types

let validate_machine m =
  let rec check_duplicates = function
    | [] -> ()
    | (c : string) :: rest ->
        if List.mem c rest then
          raise
            (Invalid_machine
               (Printf.sprintf "alphabet contains duplicate character: '%s'" c))
        else check_duplicates rest
  in

  let fail fmt = Printf.ksprintf (fun s -> raise (Invalid_machine s)) fmt in
  if m.alphabet = [] then fail "alphabet must not be empty";

  if not (List.for_all (fun s -> String.length s = 1) m.alphabet) then
    fail "all alphabet characters must have length exactly 1";

  if not (List.mem m.blank m.alphabet) then
    fail "blank character '%s' must be part of the alphabet" m.blank;

  check_duplicates m.alphabet;

  if m.states = [] then fail "states must not be empty";

  if not (List.mem m.initial m.states) then
    fail "initial state '%s' must be part of the states list" m.initial;

  List.iter
    (fun f ->
      if not (List.mem f m.states) then
        fail "final state '%s' must be part of the states list" f)
    m.finals;

  List.iter
    (fun (state, trs) ->
      if not (List.mem state m.states) then
        fail "transition declared for undeclared state '%s'" state;
      List.iter
        (fun t ->
          if not (List.mem t.read m.alphabet) then
            fail "transition read '%s' (state %s) not in alphabet" t.read state;

          if not (List.mem t.write m.alphabet) then
            fail "transition write '%s' (state %s) not in alphabet" t.write
              state;

          if not (List.mem t.to_state m.states) then
            fail "transition to_state '%s' (state %s) not declared" t.to_state
              state)
        trs)
    m.transitions
