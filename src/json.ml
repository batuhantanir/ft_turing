open Types
open Errors

let parse (s : string) : json =
  let n = String.length s in
  let pos = ref 0 in
  let peek () = if !pos < n then Some s.[!pos] else None in
  let advance () = incr pos in
  let error msg =
    raise (Json_error (Printf.sprintf "%s at position %d" msg !pos))
  in

  let rec skip_ws () =
    match peek () with
    | Some (' ' | '\t' | '\n' | '\r') ->
        advance ();
        skip_ws ()
    | _ -> ()
  in

  let expect c =
    match peek () with
    | Some c' when c' = c -> advance ()
    | _ -> error (Printf.sprintf "expected '%c'" c)
  in

  let read_hex4 () =
    let digit = function
      | '0' .. '9' as c -> Char.code c - Char.code '0'
      | 'a' .. 'f' as c -> Char.code c - Char.code 'a' + 10
      | 'A' .. 'F' as c -> Char.code c - Char.code 'A' + 10
      | _ -> error "invalid Unicode escape"
    in
    let value = ref 0 in
    for _ = 1 to 4 do
      match peek () with
      | Some c ->
          value := (!value * 16) + digit c;
          advance ()
      | None -> error "incomplete Unicode escape"
    done;
    !value
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
          | Some 'n' ->
              Buffer.add_char buf '\n';
              advance ()
          | Some 't' ->
              Buffer.add_char buf '\t';
              advance ()
          | Some 'r' ->
              Buffer.add_char buf '\r';
              advance ()
          | Some '"' ->
              Buffer.add_char buf '"';
              advance ()
          | Some '\\' ->
              Buffer.add_char buf '\\';
              advance ()
          | Some '/' ->
              Buffer.add_char buf '/';
              advance ()
          | Some 'b' ->
              Buffer.add_char buf '\b';
              advance ()
          | Some 'f' ->
              Buffer.add_char buf '\012';
              advance ()
          | Some 'u' ->
              advance ();
              let first = read_hex4 () in
              let scalar =
                if first >= 0xD800 && first <= 0xDBFF then (
                  expect '\\';
                  expect 'u';
                  let second = read_hex4 () in
                  if second < 0xDC00 || second > 0xDFFF then
                    error "invalid Unicode surrogate pair";
                  0x10000 + ((first - 0xD800) * 0x400) + second - 0xDC00)
                else if first >= 0xDC00 && first <= 0xDFFF then
                  error "unpaired Unicode surrogate"
                else first
              in
              Buffer.add_utf_8_uchar buf (Uchar.of_int scalar)
          | Some _ -> error "invalid string escape"
          | None -> error "unterminated escape");
          loop ()
      | Some c ->
          if Char.code c < 0x20 then error "unescaped control character";
          Buffer.add_char buf c;
          advance ();
          loop ()
    in
    loop ();
    Buffer.contents buf
  in

  let parse_literal word value =
    String.iter (fun c -> expect c) word;
    value
  in

  let parse_number () =
    let start = !pos in
    let digit = function Some ('0' .. '9') -> true | _ -> false in
    let digits () =
      if not (digit (peek ())) then error "expected digit";
      while digit (peek ()) do advance () done
    in
    if peek () = Some '-' then advance ();
    (match peek () with
    | Some '0' -> advance ()
    | Some ('1' .. '9') -> digits ()
    | _ -> error "invalid number");
    if peek () = Some '.' then (
      advance ();
      digits ());
    (match peek () with
    | Some ('e' | 'E') ->
        advance ();
        (match peek () with Some ('+' | '-') -> advance () | _ -> ());
        digits ()
    | _ -> ());
    JNumber (String.sub s start (!pos - start))
  in

  let rec parse_value () =
    skip_ws ();
    match peek () with
    | Some '"' -> JString (parse_string ())
    | Some '[' -> parse_array ()
    | Some '{' -> parse_object ()
    | Some ('-' | '0' .. '9') -> parse_number ()
    | Some 't' -> parse_literal "true" (JBool true)
    | Some 'f' -> parse_literal "false" (JBool false)
    | Some 'n' -> parse_literal "null" JNull
    | Some c -> error (Printf.sprintf "unexpected char '%c'" c)
    | None -> error "unexpected end of input"
  and parse_array () =
    expect '[';
    skip_ws ();
    if peek () = Some ']' then (
      advance ();
      JList [])
    else
      let rec loop acc =
        let v = parse_value () in
        skip_ws ();
        match peek () with
        | Some ',' ->
            advance ();
            skip_ws ();
            loop (v :: acc)
        | Some ']' ->
            advance ();
            JList (List.rev (v :: acc))
        | _ -> error "expected ',' or ']'"
      in
      loop []
  and parse_object () =
    expect '{';
    skip_ws ();
    if peek () = Some '}' then (
      advance ();
      JObj [])
    else
      let rec loop acc =
        skip_ws ();
        let key = parse_string () in
        if List.mem_assoc key acc then error ("duplicate object key '" ^ key ^ "'");
        skip_ws ();
        expect ':';
        let v = parse_value () in
        skip_ws ();
        match peek () with
        | Some ',' ->
            advance ();
            skip_ws ();
            loop ((key, v) :: acc)
        | Some '}' ->
            advance ();
            JObj (List.rev ((key, v) :: acc))
        | _ -> error "expected ',' or '}'"
      in
      loop []
  in

  let v = parse_value () in
  skip_ws ();
  if !pos <> n then error "unexpected content after JSON value";
  v

let from_file (path : string) : json =
  let ic = open_in path in
  let s =
    Fun.protect
      ~finally:(fun () -> close_in_noerr ic)
      (fun () -> really_input_string ic (in_channel_length ic))
  in
  parse s

let member (key : string) (j : json) : json =
  match j with
  | JObj fields -> (
      try List.assoc key fields
      with Not_found ->
        raise (Json_error (Printf.sprintf "missing key '%s'" key)))
  | _ -> raise (Json_error (Printf.sprintf "expected object for key '%s'" key))

let to_string (j : json) : string =
  match j with JString s -> s | _ -> raise (Json_error "expected string")

let to_list (j : json) : json list =
  match j with JList l -> l | _ -> raise (Json_error "expected list")

let to_assoc (j : json) : (string * json) list =
  match j with
  | JObj fields -> fields
  | _ -> raise (Json_error "expected object")
