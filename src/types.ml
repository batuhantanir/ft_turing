type direction = Left | Right

type transition = {
  read : string;
  to_state : string;
  write : string;
  action : direction;
}

type machine = {
  name : string;
  alphabet : string list;
  blank : string;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string * transition list) list;
}
