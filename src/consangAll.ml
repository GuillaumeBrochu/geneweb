(* $Id: consangAll.ml,v 2.1 1999-05-23 09:51:59 ddr Exp $ *)
(* Copyright (c) 1999 INRIA *)

open Def;
open Gutil;

value no_consang = Adef.fix (-1);

value rec clear_descend_consang base mark ifam =
  let fam = foi base ifam in
  Array.iter
    (fun ip ->
       if not mark.(Adef.int_of_iper ip) then
         let a = aoi base ip in
         do a.consang := no_consang; mark.(Adef.int_of_iper ip) := True; return
         let p = poi base ip in
         Array.iter (clear_descend_consang base mark) p.family
       else ())
    fam.children
;

value relationship base tab ip1 ip2 =
  fst (Consang.relationship_and_links base tab False ip1 ip2)
;

value trace quiet cnt max_cnt =
  do if quiet then
       let cnt = max_cnt - cnt in
       let already_disp = cnt * 60 / max_cnt in
       let to_disp = (cnt + 1) * 60 / max_cnt in
       for i = already_disp + 1 to to_disp do Printf.eprintf "#"; done
     else Printf.eprintf "%6d\008\008\008\008\008\008" cnt;
     flush stderr;
  return ()
;

value compute base from_scratch quiet =
  let _ = base.data.ascends.array () in
  let _ = base.data.couples.array () in
  let _ = base.data.families.array () in
  let tab =
    Consang.make_relationship_table base (Consang.topological_sort base)
  in
  let cnt = ref 0 in
  do if not from_scratch then
       let mark = Array.create base.data.ascends.len False in
       List.iter
         (fun ip ->
            let p = poi base ip in
            Array.iter (clear_descend_consang base mark) p.family)
         (base.func.patched_ascends ())
     else ();
     for i = 0 to base.data.ascends.len - 1 do
       let a = base.data.ascends.get i in
       do if from_scratch then a.consang := no_consang else (); return
       if a.consang == no_consang then incr cnt else ();
     done;
  return
  let max_cnt = cnt.val in
  let most = ref None in
  do Printf.eprintf "To do: %d persons\n" max_cnt;
     if max_cnt = 0 then ()
     else if quiet then
       do for i = 1 to 60 do Printf.eprintf "."; done;
          Printf.eprintf "\r";
       return ()
     else Printf.eprintf "Computing consanguinity...";
     flush stderr;
     let running = ref True in
     while running.val do
       running.val := False;
       for i = 0 to base.data.ascends.len - 1 do
         let a = base.data.ascends.get i in
         if a.consang == no_consang then
           match a.parents with
           [ Some ifam ->
               let cpl = coi base ifam in
               let fath = aoi base cpl.father in
               let moth = aoi base cpl.mother in
               if fath.consang != no_consang && moth.consang != no_consang then
                 let consang = relationship base tab cpl.father cpl.mother in
                 let fix_consang = Adef.fix_of_float consang in
                 let fam = foi base ifam in
                 for i = 0 to Array.length fam.children - 1 do
                   let ip = Array.unsafe_get fam.children i in
                   let a = aoi base ip in
                   if a.consang == no_consang then
                     do trace quiet cnt.val max_cnt;
                        decr cnt;
                        a.consang := fix_consang;
                        if not quiet then
                          let better =
                            match most.val with
                            [ Some m -> a.consang > m.consang
                            | None -> True ]
                          in
                          if better then
                            do Printf.eprintf
                                 "\nMax consanguinity %g for %s... "
                                 consang (denomination base (poi base ip));
                               flush stderr;
                            return most.val := Some a
                          else ()
                        else ();
                     return ()
                   else ();
                 done
               else running.val := True
           | None ->
               do trace quiet cnt.val max_cnt;
                  decr cnt;
               return a.consang := Adef.fix_of_float 0.0 ]
         else ();
       done;
     done;
     if max_cnt = 0 then ()
     else if quiet then Printf.eprintf "\n"
     else Printf.eprintf " done   \n";
     flush stderr;
  return ()
;
