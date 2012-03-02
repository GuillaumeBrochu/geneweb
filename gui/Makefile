# $Id: Makefile,v 1.6 2007-09-12 09:58:44 ddr Exp $
# Copyright (c) 2006-2007 INRIA

include ../tools/Makefile.inc

OCAMLC=ocamlc.opt
OCAMLOPT=ocamlopt.opt
GWB=..
OBJS=../src/version.cmo ../src/iovalue.cmo ../src/buff.cmo ../src/name.cmo ../src/mutil.cmo gui.cmo
OCAMLI=-I ../src -I +lablgtk2
TEST_DIR=test $$(basename "$<") = "$<" || { echo "Please run 'make' in directory '$$(dirname "$<")' first"; exit 1; }

all:: out

out:: gui.out
	$(RM) gui
	cp gui.out gui

opt:: gui.opt
	$(RM) gui
	cp gui.opt gui

gui.out: $(OBJS)
	$(OCAMLC) -I +lablgtk2 lablgtk.cma gtkInit.cmo unix.cma $(OBJS) -o gui.out

gui.opt: $(OBJS:.cmo=.cmx)
	$(OCAMLOPT) -I +lablgtk2 lablgtk.cmxa unix.cmxa $(OBJS:.cmo=.cmx) -o gui.opt

clean::
	$(RM) gui

depend:
	export LC_ALL=C; TOP=$(GWB) $(GWB)/tools/camlp5_depend.sh $(OCAMLI) $$(ls *.mli *.ml) | sed -e 's|\.\.|$$(GWB)|g' > .depend.new
	mv .depend.new .depend

%.cmo: %.ml
	@$(TEST_DIR)
	ocamlc -pp camlp5r $(OCAMLI) -I +lablgtk2 -c $<

include .depend