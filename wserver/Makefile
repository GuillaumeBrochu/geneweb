# $Id: Makefile,v 4.1.2.1 2007-05-11 09:55:39 ddr Exp $

include ../tools/Makefile.inc

OBJS=wserver.cmo

all:: pa_ifdef.cmo $(OBJS)
opt:: pa_ifdef.cmo $(OBJS:.cmo=.cmx)

depend:
	TOP=.. ../tools/camlp4_depend.sh $(OCAMLI) *.ml* > .depend

pa_ifdef.cmo: pa_ifdef.ml
	camlp4r pa_extend.cmo q_MLast.cmo pa_ifdef.ml -o pa_ifdef.ppo
	ocamlc -c -I $$(camlp4 -where) -impl pa_ifdef.ppo
	rm pa_ifdef.ppo

include .depend
