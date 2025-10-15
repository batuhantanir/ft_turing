let curr_index = ref 0

let find_transition (machine : Json_parser.machine) (state : string) (read_char : string)
  : Json_parser.transition option =
  match List.assoc_opt state machine.Json_parser.transitions with
  | None -> None
  | Some trans_list ->
      List.find_opt (fun (t : Json_parser.transition) -> t.read = read_char) trans_list

let turing_loop (machine : Json_parser.machine) (input : string) : unit =
  (* RIGHT/LEFT hareketini transition.action'a göre yap; yazmayı banda uygula *)
  let blank_char = if String.length machine.Json_parser.blank > 0 then machine.Json_parser.blank.[0] else '.' in
  let tape_len = max 30 (String.length input) in
  let tape = Array.init tape_len (fun i -> if i < String.length input then input.[i] else blank_char) in
  let state = ref machine.Json_parser.initial in
  let i = ref 0 in
  let steps_left = ref (Array.length tape + 10) in
  while !steps_left > 0 && !i >= 0 && !i < Array.length tape && (not (List.mem !state machine.Json_parser.finals)) do
    let read_char = String.make 1 tape.(!i) in
    let tr_opt = find_transition machine !state read_char in
    (match tr_opt with
    | Some t ->
        (* print step on pre-write tape to show the read symbol under head *)
        let tape_string_before = tape |> Array.to_seq |> String.of_seq in
        Info.print_action_info !i tape_string_before !state t.read t.write t.action t.to_state;
        (* Eğer hedef durum final ise, yazma/baş hareketi yapmadan dur *)
        if List.mem t.to_state machine.Json_parser.finals then (
          state := t.to_state;
          steps_left := 1
        ) else (
          (* apply write to the tape after printing *)
          let write_char = if String.length t.write > 0 then t.write.[0] else blank_char in
          tape.(!i) <- write_char;
          (* update state and move head *)
          state := t.to_state;
          curr_index := !i;
          (match t.action with
          | "RIGHT" -> incr i
          | "LEFT" -> decr i
          | _ -> ())
        )
    | None ->
        let tape_string = tape |> Array.to_seq |> String.of_seq in
        Info.print_action_info !i tape_string !state read_char read_char "STAY" !state;
        steps_left := 1);
    decr steps_left
  done