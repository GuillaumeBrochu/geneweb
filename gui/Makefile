# $Id: Makefile,v 1.6 2007-09-12 09:58:44 ddr Exp $
# Copyright (c) 2006-2007 INRIA

include ../tools/Makefile.inc
LABLGTK2=`ocamlfind query lablgtk2`/
GWB=..
OBJS=../src/version.cmo ../src/iovalue.cmo ../src/buff.cmo ../src/name.cmo ../src/mutil.cmo gui.cmo
OCAMLI=-I ../src -I $(LABLGTK2)

all:: out

out:: gui.out
	$(RM) gui
	cp gui.out gui

opt:: gui.opt
	$(RM) gui
	cp gui.opt gui
	$(STRIP) gui

gui.out: $(OBJS)
	$(OCAMLC) -I $(LABLGTK2) lablgtk.cma unix.cma $(OBJS) -o gui.out

gui.opt: $(OBJS:.cmo=.cmx)
	$(OCAMLOPT) -I $(LABLGTK2) lablgtk.cmxa unix.cmxa $(OBJS:.cmo=.cmx) -o gui.opt

clean::
	$(RM) gui

depend:
	$(ROOT)/tools/camlp5_depend.sh $(CAMLP5F) $(OCAMLI) -- *.ml* > .depend

%.cmo: %.ml
	$(OCAMLC) -pp camlp5r $(OCAMLI) -I $(LABLGTK2) -c $<

include .depend
