# Network server programming with OCaml

<i>7 January, 2012</i>

Some years ago, I [experimented with networking in
SML/NJ](http://github.com/tonyg/smlnj-networking/#readme) and spent a few
hours figuring out how to write a multithreaded TCP/IP server using
SML/NJ. Here, I've performed the same exercise with OCaml 3.12.1.

## Download source code, building, and running

The following example is comprised of a `_tags` file for controlling
`ocamlbuild` and the `.ml` file itself. The complete sources:

 - [`_tags`](https://raw.github.com/tonyg/ocaml-networking/master/_tags)
 - [`test.ml`](https://raw.github.com/tonyg/ocaml-networking/master/test.ml)

Running the following command compiles the project:

    ocamlbuild test.native

The `ocamlbuild` output is a native executable. The executable is
placed in the `_build` directory, and a symbolic link to the
executable is placed in the working directory. To run the program:

    ./test.native

## The build control file

The
[`_tags`](https://raw.github.com/tonyg/ocaml-networking/master/_tags)
file contains

    true: use_unix
    true: thread

which instructs the build system to include the `Unix` POSIX module,
which provides a BSD-sockets API, and to configure the OCaml runtime
to support the `Thread` lightweight-threads module.  For more
information about `ocamlbuild`, see
[here](http://nicolaspouillard.fr/ocamlbuild/ocamlbuild-user-guide.pdf).

## The example source code

Turning to
[`test.ml`](https://raw.github.com/tonyg/ocaml-networking/master/test.ml)
now, we first bring the contents of a few modules into scope:

    open Unix
    open Printf
    open Thread

The `Unix` module, mentioned above, provides a POSIX BSD-sockets API;
`Printf` is for formatted printing; and `Thread` is for
multithreading. We'll be using a single thread per connection. Other
models are possible.

OCaml programs end up being written upside down, in a sense, because
function definitions need to precede their use (unless
mutually-recursive definitions are used). For this reason, the next
chunk is `conn_main`, the function called in a new lightweight thread
when an inbound TCP connection has been accepted. Here, it simply
prints out a countdown from 10 over the course of the next five
seconds or so, before closing the socket. Multiple connections end up
running `conn_main` in independent threads of control, leading
automatically to the natural and obvious interleaving of outputs on
concurrent connections.

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

Note the calls to `flush`, forcing buffered output out to the actual
socket.

The function that depends on `conn_main` is the accept loop, which
repeatedly accepts a connection and spawns a connection thread for it.

    let rec accept_loop sock =
      let (s, _) = accept sock in
      printf "Accepted a connection.\n%!";
      let _ = Thread.create conn_main s in
      accept_loop sock

Finally, the block of code that starts the whole service running,
creating the TCP server socket and entering the accept loop. We set
`SO_REUSEADDR` on the socket, listen on port 8989 with a connection
backlog of 5, and enter the accept loop.

    let _ =
      let sock = socket PF_INET SOCK_STREAM 0 in
      setsockopt sock SO_REUSEADDR true;
      bind sock (ADDR_INET (inet_addr_of_string "0.0.0.0", 8989));
      listen sock 5;
      printf "Entering accept loop...\n%!";
      accept_loop sock
