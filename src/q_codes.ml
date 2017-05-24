(* camlp4r *)
(* $Id: q_codes.ml,v 5.4 2012-01-16 22:11:29 ddr Exp $ *)
(* Copyright (c) 1998-2007 INRIA *)

open Camlp4.PreCast;

value f _ =
  fun
  [ "PREFIX_SMALL_BLOCK" -> "0x80"
  | "PREFIX_SMALL_INT" -> "0x40"
  | "PREFIX_SMALL_STRING" -> "0x20"
  | "CODE_INT8" -> "0x0"
  | "CODE_INT16" -> "0x1"
  | "CODE_INT32" -> "0x2"
  | "CODE_BLOCK32" -> "0x8"
  | "CODE_BLOCK64" -> "0x13"
  | "CODE_STRING8" -> "0x9"
  | "CODE_STRING32" -> "0xA"
  | x ->
      Loc.raise (Loc.mk x)
        (Failure ("bad code " ^ x)) ]
;

(* MAUVAIS *)
(* Quotation.add "codes" (Quotation.ExStr f); *)
Quotation.default.val := "codes";

