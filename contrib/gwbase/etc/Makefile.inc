# $Id: Makefile.inc,v 4.5 2009-03-11 10:58:50 deraugla Exp $

D=.
CAMLP5_COMM=$D/camlp5_comm.sh -I $(GWB)/src pa_macro.cmo
CAMLP5F=-DUNIX
CAMLP5D=`camlp5 -where`
LIBUNIX=-cclib -lunix
include $(GWB)/tools/Makefile.debian
OCAMLI=
RM=/bin/rm -f
EXE=

all::
opt::

clean::
	$(RM) *.out *.opt *.cm[oixa] *.cmxa *.pp[oi] *.o *.obj *.lck *.bak *~ .#*

.SUFFIXES: .ml .cmo .mli .cmi .cmx

.mli.cmi:
	@$(TEST_DIR)
	@$(CAMLP5_COMM) $(CAMLP5F) $< -o $*.ppi
	$(OCAMLC) $(OCAMLI) -I $(CAMLP5D) -c -intf $*.ppi
	$(RM) $*.ppi

.ml.cmo:
	@$(TEST_DIR)
	@$(CAMLP5_COMM) $(CAMLP5F) $< -o $*.ppo
	$(OCAMLC) $(OCAMLI) -I $(CAMLP5D) -c -impl $*.ppo
	$(RM) $*.ppo

.ml.cmx:
	@$(TEST_DIR)
	@$(CAMLP5_COMM) $(CAMLP5F) $< -o $*.ppo
	$(OCAMLOPT) $(OCAMLI) -I $(CAMLP5D) -c -impl $*.ppo
	$(RM) $*.ppo
