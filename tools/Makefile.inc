# $Id: Makefile.inc,v 4.5.2.2 2007-05-11 09:55:39 ddr Exp $

TOP=..
CAMLP4_COMM=TOP=$(TOP) $(TOP)/tools/camlp4_comm.sh ../wserver/pa_ifdef.cmo
CAMLP4F=-DUNIX -loc loc
CAMLP4D=`camlp4 -where`
LIBUNIX=-cclib -lunix
OCAMLC=ocamlc.opt -warn-error A
OCAMLOPT=ocamlopt.opt -warn-error A
OCAMLI=
OCAMLD=
STRIP=strip
RM=/bin/rm -f
EXE=
STATIC=-ccopt -static
STATIC=

all::
opt::

clean::
	$(RM) *.out *.opt *.cm[oixa] *.cmxa *.pp[oi] *.o *.a *.obj *.lib *.lck *.bak *~ .#*

.SUFFIXES: .ml .cmo .mli .cmi .cmx

.mli.cmi:
	@if test `basename $<` != $<; then echo "Bad directory for $<"; exit 1; fi
	@$(CAMLP4_COMM) $(CAMLP4F) $< -o $*.ppi
	$(OCAMLC) $(OCAMLI) -I $(CAMLP4D) -c -intf $*.ppi
	$(RM) $*.ppi

.ml.cmo:
	@if test `basename $<` != $<; then echo "Bad directory for $<"; exit 1; fi
	@$(CAMLP4_COMM) $(CAMLP4F) $< -o $*.ppo
	$(OCAMLC) $(OCAMLI) $(OCAMLD) -I $(CAMLP4D) -c -impl $*.ppo
	$(RM) $*.ppo

.ml.cmx:
	@if test `basename $<` != $<; then echo "Bad directory for $<"; exit 1; fi
	@$(CAMLP4_COMM) $(CAMLP4F) $< -o $*.ppo
	$(OCAMLOPT) $(OCAMLI) -I $(CAMLP4D) -c -impl $*.ppo
	$(RM) $*.ppo