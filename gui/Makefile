# $Id: Makefile,v 1.6 2007-09-12 09:58:44 ddr Exp $
# Copyright (c) 2006-2007 INRIA

include ../tools/Makefile.config

LABLGTK2=`ocamlfind query lablgtk2`/
OCAMLC=ocamlc.opt
OCAMLOPT=ocamlopt.opt -annot
GWB=..

OBJS=../src/version.cmo ../src/iovalue.cmo ../src/buff.cmo \
../src/name.cmo ../src/mutil.cmo gui.cmo

OCAMLI=-I ../src -I $(LABLGTK2)
TEST_DIR=test $$(basename "$<") = "$<" || { echo "Please run 'make' in directory '$$(dirname "$<")' first"; exit 1; }

#all:: opt

out:: gui.out
	$(RM) gui
	cp gui.out gui

opt:: gui.opt
	$(RM) gui
	cp gui.opt gui

gui.out: $(OBJS)
	$(OCAMLC) -I $(LABLGTK2) lablgtk.cma unix.cma $(OBJS) -o gui.out

gui.opt: $(OBJS:.cmo=.cmx)
	$(OCAMLOPT) -I $(LABLGTK2) lablgtk.cmxa unix.cmxa $(OBJS:.cmo=.cmx) -o gui.opt

%.cmo: %.ml
	@$(TEST_DIR)
	ocamlc -pp camlp5r $(OCAMLI) -I $(LABLGTK2) -c $<

.PHONY: clean
clean:
	$(RM) *.out *.opt *.cm[oixa] *.cmxa *.pp[oi] *.o *.a *.obj *.lib \
	*.lck *.bak *~ .#* *.annot
	$(RM) gui *.bat
	$(RM) -r test

.PHONY: depend
depend:
	$(ROOT)/tools/camlp5_depend.sh $(CAMLP5F) $(OCAMLI) -- *.ml* > .depend

.depend:
	@if [ ! -e $@ ]; then $(MAKE) -o $@ depend; fi

ifeq ($(filter $(MAKECMDGOALS),clean depend),)
  include .depend
endif
