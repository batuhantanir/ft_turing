type action = Left | Right | Stay
type state = Scanright | Eraseone | Subone | Skip | Halt

let tape = Array.of_list (List.init 30 (fun i ->
  if i < String.length "1111-11=" then "1111-11=".[i] else '.'
))

let head = ref 0
let current = ref Scanright

let read () = tape.(!head)
let write c = tape.(!head) <- c
let move = function
  | Left -> decr head
  | Right -> incr head
  | Stay -> ()

let rec step () =
  match !current, read () with
  | Halt, _ -> ()
  | Scanright, '.' -> move Right; step ()
  | Scanright, '1' -> move Right; step ()
  | Scanright, '-' -> move Right; step ()
  | Scanright, '=' -> write '.'; move Left; current := Eraseone; step ()

  | Eraseone, '1' -> write '='; move Left; current := Subone; step ()
  | Eraseone, '-' -> write '.'; move Left; current := Halt; step ()

  | Subone, '1' -> move Left; step ()
  | Subone, '-' -> move Left; current := Skip; step ()

  | Skip, '.' -> move Left; step ()
  | Skip, '1' -> write '.'; move Right; current := Scanright; step ()

  | _, _ -> current := Halt; step ()

let () =
  print_endline "Başlangıç:";
  Array.iter (Printf.printf "%c") tape; print_newline ();
  step ();
  print_endline "\nSonuç:";
  Array.iter (Printf.printf "%c") tape; print_newline ()