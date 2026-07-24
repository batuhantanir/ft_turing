type json =
  | JString of string
  | JList of json list
  | JObj of (string * json) list

exception Json_error of string

let parse (s : string) : json =
  let n = String.length s in
  let pos = ref 0 in
  let peek () = if !pos < n then Some s.[!pos] else None in
  let advance () = incr pos in
  let error msg = raise (Json_error (Printf.sprintf "%s at position %d" msg !pos)) in
  let rec skip_ws () =
    match peek () with
    | Some (' ' | '\t' | '\n' | '\r') -> advance (); skip_ws ()
    | _ -> ()
  in
  let expect c =
    match peek () with
    | Some c' when c' = c -> advance ()
    | _ -> error (Printf.sprintf "expected '%c'" c)
  in
  let parse_string () =
    expect '"';
    let buf = Buffer.create 16 in
    let rec loop () =
      match peek () with
      | None -> error "unterminated string"
      | Some '"' -> advance ()
      | Some '\\' ->
        advance ();
        (match peek () with
         | Some 'n' -> Buffer.add_char buf '\n'; advance ()
         | Some 't' -> Buffer.add_char buf '\t'; advance ()
         | Some 'r' -> Buffer.add_char buf '\r'; advance ()
         | Some '"' -> Buffer.add_char buf '"'; advance ()
         | Some '\\' -> Buffer.add_char buf '\\'; advance ()
         | Some '/' -> Buffer.add_char buf '/'; advance ()
         | Some 'b' -> Buffer.add_char buf '\b'; advance ()
         | Some 'f' -> Buffer.add_char buf '\012'; advance ()
         | Some c -> Buffer.add_char buf c; advance ()
         | None -> error "unterminated escape");
        loop ()
      | Some c -> Buffer.add_char buf c; advance (); loop ()
    in
    loop ();
    Buffer.contents buf
  in
  let rec parse_value () =
    skip_ws ();
    match peek () with
    | Some '"' -> JString (parse_string ())
    | Some '[' -> parse_array ()
    | Some '{' -> parse_object ()
    | Some c -> error (Printf.sprintf "unexpected char '%c'" c)
    | None -> error "unexpected end of input"
  and parse_array () =
    expect '[';
    skip_ws ();
    if peek () = Some ']' then (advance (); JList [])
    else
      let rec loop acc =
        let v = parse_value () in
        skip_ws ();
        match peek () with
        | Some ',' -> advance (); skip_ws (); loop (v :: acc)
        | Some ']' -> advance (); JList (List.rev (v :: acc))
        | _ -> error "expected ',' or ']'"
      in
      loop []
  and parse_object () =
    expect '{';
    skip_ws ();
    if peek () = Some '}' then (advance (); JObj [])
    else
      let rec loop acc =
        skip_ws ();
        let key = parse_string () in
        skip_ws ();
        expect ':';
        let v = parse_value () in
        skip_ws ();
        match peek () with
        | Some ',' -> advance (); skip_ws (); loop ((key, v) :: acc)
        | Some '}' -> advance (); JObj (List.rev ((key, v) :: acc))
        | _ -> error "expected ',' or '}'"
      in
      loop []
  in
  let v = parse_value () in
  skip_ws ();
  v

let from_file (path : string) : json =
  let ic = open_in path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  parse s

let member (key : string) (j : json) : json =
  match j with
  | JObj fields ->
    (try List.assoc key fields
     with Not_found -> raise (Json_error (Printf.sprintf "missing key '%s'" key)))
  | _ -> raise (Json_error (Printf.sprintf "expected object for key '%s'" key))

let to_string (j : json) : string =
  match j with
  | JString s -> s
  | _ -> raise (Json_error "expected string")

let to_list (j : json) : json list =
  match j with
  | JList l -> l
  | _ -> raise (Json_error "expected list")

let to_assoc (j : json) : (string * json) list =
  match j with
  | JObj fields -> fields
  | _ -> raise (Json_error "expected object")
