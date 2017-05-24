(* camlp4r pa_extend.cmo q_MLast.cmo *)
(* $Id: pa_lock.ml,v 5.3 2007-09-12 09:58:44 ddr Exp $ *)
(* Copyright (c) 1998-2007 INRIA *)

open Camlp4.PreCast;

value expr = Gram.Entry.mk "expr";

EXTEND Gram
  expr: LEVEL "top"
    [ [ "lock"; fn = expr; "with";
        "["; UIDENT "Accept"; "->"; ea = expr;
        "|"; UIDENT "Refuse"; "->"; er = expr; "]" ->
          <:expr<
            match Lock.control $fn$ False (fun () -> $ea$) with
            [ Some x -> x
            | None -> $er$ ] >>
      |
        "lock_wait"; fn = expr; "with";
        "["; UIDENT "Accept"; "->"; ea = expr;
        "|"; UIDENT "Refuse"; "->"; er = expr; "]" ->
          <:expr<
            match Lock.control $fn$ True (fun () -> $ea$) with
            [ Some x -> x
            | None -> $er$ ] >> ] ]
  ;
END;
