all: test.native

clean:
	ocamlbuild -clean

%.native: %.ml
	ocamlbuild $@

run: all
	./test.native
