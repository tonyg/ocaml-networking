open Unix
open Printf
open Thread

let conn_main s =
  let cout = out_channel_of_descr s in
  let rec count n =
    match n with
    | 0 ->
	fprintf cout "Bye!\r\n%!"
    | _ ->
	fprintf cout "Hello %d\r\n%!" n;
	Thread.delay 0.5;
	count (n - 1)
  in
  count 10;
  printf "Closing the connection.\n%!";
  flush cout;
  close s

let rec accept_loop sock =
  let (s, _) = accept sock in
  printf "Accepted a connection.\n%!";
  let _ = Thread.create conn_main s in
  accept_loop sock

let _ =
  Sys.set_signal Sys.sigpipe Sys.Signal_ignore;
  let sock = socket PF_INET SOCK_STREAM 0 in
  setsockopt sock SO_REUSEADDR true;
  bind sock (ADDR_INET (inet_addr_of_string "0.0.0.0", 8989));
  listen sock 5;
  printf "Entering accept loop...\n%!";
  accept_loop sock
