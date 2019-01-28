(* $Id: place.ml,v 5.21 2007-09-18 19:12:08 ddr Exp $ *)
(* Copyright (c) 1998-2007 INRIA *)

open Config
open Gwdb
open Util
open TemplAst

let normalize =
  (* petit hack en attendant une vraie gestion des lieux transforme
     "[foo-bar] - boobar (baz)" en "foo-bar, boobar (baz)" *)
  let r = Str.regexp "^\\[\\([^]]+\\)\\] *- *\\(.*\\)" in
  fun s -> Str.global_replace r "\\1, \\2" s

(* [String.length s > 0] is always true because we already tested [is_empty_string].
   If it is not true, then the base should be cleaned. *)
let fold_place_long inverted s =
  let len = String.length s in
  (* Trimm spaces after ',' and build reverse String.split_on_char ',' *)
  let rec loop iend list i ibeg =
    if i = iend
    then if i > ibeg then String.sub s ibeg (i - ibeg) :: list else list
    else
      let (list, ibeg) =
        match String.unsafe_get s i with
        | ',' ->
          let list =
            if i > ibeg then String.sub s ibeg (i - ibeg) :: list else list
          in
          list, i + 1
        | ' ' when i = ibeg -> (list, i + 1)
        | _ -> list, ibeg
      in
      loop iend list (i + 1) ibeg
  in
  let (iend, rest) =
    if String.unsafe_get s (len - 1) = ')'
    then match String.rindex_opt s '(' with
      | Some i when i < len - 2 ->
        let j =
          let rec loop i =
            if i >= 0 && String.unsafe_get s i = ' '
            then loop (i - 1) else i + 1
          in
          loop (i - 1)
        in
        j, [ String.sub s (i + 1) (len - i - 2) ]
      | _ -> len, []
    else len, []
  in
  let list = List.rev_append rest @@ loop iend [] 0 0 in
  if inverted then List.rev list else list

let fold_place_short s =
  let len = String.length s in
  let default () =
    let i =
      match String.rindex_opt s ',' with
      | Some i ->
        let rec l i =
          if i < len && String.unsafe_get s i = ' '
          then l (i + 1) else i in l (i + 1)
      | None -> 0
    in
    let i = if i = len then 0 else i in
    String.sub s i (len - i)
  in
  if String.unsafe_get s (len - 1) = ')'
  then match String.rindex_opt s '(' with
    | Some i when i < len - 2 ->
      String.sub s (i + 1) (len - i - 2)
    | _ -> default ()
  else default ()

let get_all =
  fun conf base ~add_birth ~add_baptism ~add_death ~add_burial
    (dummy_key : 'a)
    (dummy_value : 'c)
    (fold_place : string -> 'a)
    (filter : 'a -> bool)
    (mk_value : 'b option -> person -> 'b)
    (foo : 'b -> 'c) :
    ('a * 'c) array ->
  let add_marriage = p_getenv conf.env "ma" = Some "on" in
  let ht_size = 2048 in (* FIXME: find the good heuristic *)
  let ht : ('a, 'b) Hashtbl.t = Hashtbl.create ht_size in
  let ht_add istr p =
    let key : 'a = sou base istr |> normalize |> fold_place in
    if filter key then
      match Hashtbl.find_opt ht key with
      | Some _ as prev -> Hashtbl.replace ht key (mk_value prev p)
      | None -> Hashtbl.add ht key (mk_value None p)
  in
  if add_birth || add_death || add_baptism || add_burial then begin
    let len = nb_of_persons base in
    let aux b fn p =
      if b then let x = fn p in if not (is_empty_string x) then ht_add x p
    in
    let rec loop i =
      if i < len then begin
        let p = pget conf base (Adef.iper_of_int i) in
        if authorized_age conf base p then begin
          aux add_birth get_birth_place p ;
          aux add_baptism get_baptism_place p ;
          aux add_death get_death_place p ;
          aux add_burial get_burial_place p ;
        end ;
        loop (i + 1)
      end
    in
    loop 0 ;
  end ;
  if add_marriage then begin
    let rec loop i =
      let len = nb_of_families base in
      if i < len then begin
        let fam = foi base (Adef.ifam_of_int i) in
        if not @@ is_deleted_family fam then begin
          let pl_ma = get_marriage_place fam in
          if not (is_empty_string pl_ma) then
            let fath = pget conf base (get_father fam) in
            let moth = pget conf base (get_mother fam) in
            if authorized_age conf base fath
            && authorized_age conf base moth
            then begin
              ht_add pl_ma fath ;
              ht_add pl_ma moth
            end
        end ;
        loop (i + 1) ;
      end
    in
    loop 0 ;
  end ;
  let len = Hashtbl.length ht in
  let array = Array.make len (dummy_key, dummy_value) in
  let i = ref 0 in
  Hashtbl.iter
    (fun k v ->
       Array.unsafe_set array !i (k, foo v) ;
       incr i)
    ht ;
  array

let get_opt conf =
  let add_birth = p_getenv conf.env "bi" = Some "on" in
  let add_baptism = p_getenv conf.env "bp" = Some "on" in
  let add_death = p_getenv conf.env "de" = Some "on" in
  let add_burial = p_getenv conf.env "bu" = Some "on" in
  let add_marriage = p_getenv conf.env "ma" = Some "on" in
  let f_sort = p_getenv conf.env "f_sort" = Some "on" in
  (if add_birth then "&bi=on" else "") ^
  (if add_baptism then "&bp=on" else "") ^
  (if add_death then "&de=on" else "") ^
  (if add_burial then "&bu=on" else "") ^
  (if add_marriage then "&ma=on" else "") ^
  (if f_sort then "&f_sort=on" else "") ^
  "&dates=on"


type 'a env =
    Vlist_data of (string * (string * int) list) list
  | Vlist_ini of string list
  | Vlist_value of (string * (string * int) list) list
  | Venv_keys of (string * int) list
  | Vint of int
  | Vstring of string
  | Vbool of bool
  | Vother of 'a
  | Vnone

let get_env v env = try List.assoc v env with Not_found -> Vnone
let get_vother =
  function
    Vother x -> Some x
  | _ -> None
let set_vother x = Vother x
let bool_val x = VVbool x
let str_val x = VVstring x

let string_to_list str =
  let rec loop acc =
    function
      s ->
        if String.length s > 0 then
          let nbc = Name.nbc s.[0] in
          let c = String.sub s 0 nbc in
          let s1 = String.sub s nbc (String.length s - nbc) in
          loop (c :: acc) s1
        else acc
  in loop [] str

let rec eval_var conf base env xx _loc sl =
  try eval_simple_var conf base env xx sl with
    Not_found -> eval_compound_var conf base env xx sl
and eval_simple_var conf base env xx =
  function
    [s] ->
      begin try bool_val (eval_simple_bool_var conf base env xx s) with
        Not_found -> str_val (eval_simple_str_var conf base env xx s)
      end
  | _ -> raise Not_found
and eval_simple_bool_var _conf _base env _xx =
  function
  | "is_first" ->
      begin match get_env "first" env with
        Vbool x -> x
      | _ -> raise Not_found
      end
  | _ -> raise Not_found
and eval_simple_str_var _conf _base env _xx =
  function
  | "substr" -> eval_string_env "substr" env
  | "cnt" -> eval_int_env "cnt" env
  | "tail" -> eval_string_env "tail" env
  | "keys" ->
      let k =
        match get_env "keys" env with
          Venv_keys k -> k
        | _ -> []
      in
      List.fold_left
        (fun accu (k, i) -> accu ^ k ^ "=" ^ string_of_int i ^ "&") "" k
  | "env_key" -> eval_string_env "env_key" env
  | "env_val" -> eval_string_env "env_val" env
  | _ -> raise Not_found
and eval_compound_var conf base env xx sl =
  let rec loop =
    function
      [s] -> eval_simple_str_var conf base env xx s
    | ["evar"; "p"; s] ->
        begin match p_getenv conf.env s with
          Some s -> if String.length s > 1 then String.sub s 0 (String.length s - 1) else ""
        | None -> ""
        end
    | ["evar"; s] ->
        begin match p_getenv conf.env s with
          Some s -> s
        | None -> ""
        end
    | ["subs"; n; s] ->
        let n = int_of_string n in
        if String.length s > n then String.sub s 0 (String.length s - n) else ""
    | "encode" :: sl -> code_varenv (loop sl)
    | "escape" :: sl -> quote_escaped (loop sl)
    | "html_encode" :: sl -> no_html_tags (loop sl)
    | "printable" :: sl -> only_printable (loop sl)
    | _ -> raise Not_found
  in
  str_val (loop sl)
and eval_string_env s env =
  match get_env s env with
    Vstring s -> s
  | _ -> raise Not_found
and eval_int_env s env =
  match get_env s env with
    Vint i -> string_of_int i
  | _ -> raise Not_found
let print_foreach conf print_ast _eval_expr =
  let rec print_foreach env xx _loc s sl el al =
    match s :: sl with
    | ["env_binding"] -> print_foreach_env_binding env xx el al
    | _ -> raise Not_found
  and print_foreach_env_binding env xx _el al =
    let rec loop =
      function
        (k, v) :: l ->
          let env = ("env_key", Vstring k) :: ("env_val", Vstring v) :: env in
          List.iter (print_ast env xx) al; loop l
      | [] -> ()
    in
    loop conf.env
  in
  print_foreach

let get_ip_list (snl : (string * Adef.iper list) list) =
  List.map snd snl |> List.flatten |> List.sort_uniq compare

let _print_list list =
  let rec loop =
    function
    | (pl, snl) :: l ->
      Wserver.printf "Line: places";
      List.iter (fun p -> Wserver.printf ", %s" p) pl ;
      Wserver.printf ", persons: (%d)<br>\n" (List.length snl) ;
      loop l
    | [] -> ()
  in
  loop list

let get_new_list conf list =
  let k1 = match p_getenv conf.env "k1" with | Some s -> s | _ -> "" in
  let list1 =
    let rec loop acc =
      function
      | (pl, snl) :: l ->
        let pln = if k1 = "" then pl else if List.length pl > 0 then List.tl pl else [] in
        loop ((pln, pl, snl) :: acc) l
      | [] -> acc
    in
    loop [] list
  in
  let (new_list, cntt) =
    let rec loop cntt cnt acc acc_ip =
      function
      | ([], plo, snl) :: l ->
          let ipl = get_ip_list snl in
          let add = List.length ipl in
          loop (cntt + add) 0 (([], plo, (cnt + add), [],
            (ipl :: acc_ip)) :: acc) [] l
      | (pl, plo, snl) :: l ->
          if (List.hd pl) <> "" &&
             (List.hd pl) <>
             (if (List.length l > 0) then
               (let (pl1, _, _) = List.hd l in
                if List.length pl1 > 0 then List.hd pl1 else "") else "")
          then
            let ipl = get_ip_list snl in
            let add = List.length ipl in
            loop (cntt + add) 0 ((pl, plo, (cnt + add),
              (if List.tl pl <> [] then List.tl pl else []),
              (ipl :: acc_ip)) :: acc) [] l
          else
            let ipl = get_ip_list snl in
            let add = List.length ipl in
            loop (cntt + add) (cnt + add)
            acc (ipl :: acc_ip) l
      | [] -> (acc, cntt)
    in
    loop 0 0 [] [] list1
  in
  (new_list, cntt)

let get_k3 pl k1 k2 =
  Util.code_varenv (List.fold_left
  (fun acc p -> p ^ (if acc <> "" then ", " else "") ^ acc) ""
    (List.rev (
      if k1 <> "" && k2 <> ""
        then if List.length pl > 2 then (List.tl (List.tl pl)) else []
        else if k1 <> ""
          then if List.length pl > 1 then (List.tl pl) else []
          else pl)))

let print_section conf opt ps1 =
  Wserver.printf "</ul><h5><a href=\"%sm=PS%s%s%s\">%s</a></h5><ul>\n"
    (commd conf) opt "&long=on" ("&k1=" ^(Util.code_varenv ps1)) ps1

let print_html_places_surnames_long conf _base
  (array : (string list * (string * Adef.iper list) list) array) =
  let opt = get_opt conf in
  let k1 = match p_getenv conf.env "k1" with | Some s -> s | _ -> "" in
  let k2 = match p_getenv conf.env "k2" with | Some s -> s | _ -> "" in
  let list = Array.to_list array in
  (* print_list list ; *)
  let link_to_ind =
    match p_getenv conf.base_env "place_surname_link_to_ind" with
    | Some "yes" -> true
    | _ -> false
  in
  (*let (_new_list, cntt) = get_new_list conf list in
  let conf = {conf with env = ("k1_cnt", (string_of_int cntt)) :: conf.env} in *)
  let print_sn ((sn, ips), pl) =
    let len = List.length ips in
    let k3 = get_k3 pl k1 k2 in
    Wserver.printf "<a href=\"%sm=N&v=%s\">%s</a>" (commd conf)
        (code_varenv sn) sn ;
    if link_to_ind then
      begin
        Wserver.printf " (<a href=\"%sm=L&surn=%s&nb=%d"
          (commd conf) sn (List.length ips) ;
        List.iteri (fun i ip ->
          Wserver.printf "&i%d=%d" i (Adef.int_of_iper ip))
        ips ;
        let opt = get_opt conf in
        Wserver.printf "%s%s%s%s\">%d</a>)"
          (if k1 <> "" then "&k1=" ^ (Util.code_varenv k1)
           else "&k1=" ^ (if pl <> [] then List.hd pl else ""))
          (if k2 <> "" then "&k2=" ^ (Util.code_varenv k2)
           else if k1 = ""
            then
              if List.length pl > 1 then "&k2=" ^ (List.hd (List.tl pl))
              else ""
            else "&k2=" ^ (if pl <> [] then List.hd pl else ""))
          (if k3 <> "" then "&k3=" ^ k3 else "") opt len
      end
    else Wserver.printf " (%d)" len
  in
  let print_sn_list ((snl : (string * Adef.iper list) list), pl) =
    let snl = List.sort
      (fun (sn1, _) (sn2, _) -> Gutil.alphabetic_order sn1 sn2) snl
    in
    let snl =
      if p_getenv conf.env "f_sort" = Some "on" then
        List.rev
          (List.sort
            (fun (sn1, ipl1) (sn2, ipl2) ->
              let lipl1 = List.length ipl1 in
              let lipl2 = List.length ipl2 in
              if lipl1 = lipl2 then (Gutil.alphabetic_order sn1 sn2)
              else lipl1 - lipl2) snl)
      else snl
    in
    Wserver.printf "<li>\n" ;
    Mutil.list_iter_first
      (fun first x -> if not first then Wserver.printf ",\n" ;
        print_sn (x, pl)) snl ;
    Wserver.printf "\n" ;
    Wserver.printf "</li>\n"
  in
  let title = transl conf "long/short display" in
  let rec loop prev =
    function
    | (plo, snl) :: list ->
        let pl =
          if k1 = "" then plo
          else if List.length plo > 0 then List.tl plo else []
        in
        let ps1 = if List.length plo > 0 then List.hd plo else "" in
        let ps2 = if List.length plo > 1 then List.hd (List.tl plo) else "" in
        let rec loop1 prev pl lvl =
          match prev, pl with
          | [], l2 ->
            if List.length l2 = 0
            then print_section conf opt ps1 ;
            List.iteri
              (fun i x ->
                let href =
                  Printf.sprintf "%sm=PS%s%s%s%s"
                  (commd conf) opt
                  (if k1 <> "" then "&k1=" ^ Util.code_varenv (ps1) else
                    if k2 <> "" then "&k1=" ^ Util.code_varenv (ps1) else "")
                  (if (k2 <> ""  || (i + lvl) >= 0) && ps2 <> ""
                    then "&k2=" ^ Util.code_varenv (ps2) else "")
                  (if k1 <> "" && k2 <> "" then "&long=on" else "")
                in
                Wserver.printf "<li><a href=\"%s\" title=\"%s\">%s</a><ul>\n"
                href title x )
              l2
          | x1 :: l1, x2 :: l2 ->
              if x1 = x2 then loop1 l1 l2 (lvl + 1)
              else
                begin
                  List.iter (fun _ -> Wserver.printf "</ul></li>\n")
                    (x1 :: l1) ;
                  loop1 [] (x2 :: l2) (lvl + 1)
                end
          | _ ->
              List.iter (fun _ -> Wserver.printf "</ul></li>\n") prev ;
              print_section conf opt ps1
        in
        loop1 prev pl 0 ;
        let snl =
          List.fold_left
            (fun acc (sn, ipl) -> (sn, List.sort_uniq compare ipl) :: acc)
            [] snl
        in
        print_sn_list (snl, pl) ;
        loop pl list
    | [] -> List.iter (fun _ -> Wserver.printf "</ul></li>\n") prev
  in
  Wserver.printf "<ul>\n" ;
  loop [] list ;
  Wserver.printf "</ul>\n"

let print_html_places_surnames_short conf _base
  (array : (string list * (string * Adef.iper list) list) array) =
  let k1 = match p_getenv conf.env "k1" with | Some s -> s | _ -> "" in
  let long = p_getenv conf.env "long" = Some "on" in
  let opt = get_opt conf in
  let pl_sn_list = Array.to_list array in
  (*print_list pl_sn_list ;*)
  let (new_list, _cntt) = get_new_list conf pl_sn_list in
  let new_list =
    if p_getenv conf.env "f_sort" = Some "on" then
      List.rev (List.sort
      (fun (_, _, cnt1, _, _) (_, _, cnt2, _, _) -> (cnt1 - cnt2)) new_list)
    else new_list
  in
  let title = transl conf "long/short display" in
  (* in new_list, ps is a string, pl was a list of strings *)
  (* let conf = {conf with env = ("k1_cnt", (string_of_int cntt)) :: conf.env} in *)
  Mutil.list_iter_first
    (fun first (_pl, plo, _cnt, _, ipl) ->
      let ps1 = if List.length plo > 0 then List.hd plo else "" in
      let ps2 = if List.length plo > 1 then List.hd (List.tl plo) else ps1 in
      let ipl = List.flatten ipl |> List.sort_uniq compare in
      Wserver.printf
        "%s<a href=\"%sm=PS%s%s%s%s\" title=\"%s\">%s</a>"
        (if not first then ", " else "") (commd conf) opt
        ("&k1=" ^ Util.code_varenv ps1)
        (if k1 = "" then ""
         else if List.length plo > 1
          then "&k2=" ^ Util.code_varenv ps2 else "")
        (if not long then "&long=on" else "") title
        (if k1 = "" then ps1 else ps2) ;
      Wserver.printf " (<a href=\"%sm=L%s%s%s&nb=%d" (commd conf)
        ("&k1=" ^ (Util.code_varenv ps1))
        (if k1 = "" then ""
         else "&k2=" ^ (Util.code_varenv ps2))
        opt (List.length ipl) ;
      List.iteri (fun i ip ->
        Wserver.printf "&i%d=%d" i (Adef.int_of_iper ip))
      ipl ;
      Wserver.printf "\" title=\"%s\">%d</a>)"
        (capitale (transl conf "summary book ascendants")) (List.length ipl))
    new_list

let print_searchl conf searchl =
  match p_getenv conf.env "search" with
    | Some "on" ->
        let searchl = List.sort_uniq compare searchl in
        let opt = get_opt conf in
        let print_pl pl =
          Wserver.printf "<li><a href=\"%sm=PS%s&k1=%s\">%s</a>"
            (commd conf) opt (List.hd pl) (List.hd pl) ;
          if List.length pl > 1 then
            let k1 = List.hd pl in
            let k2 = List.hd (List.tl pl) in
            Wserver.printf " > <a href=\"%sm=PS%s&k1=%s&k2=%s\">%s</a>"
              (commd conf) opt k1 k2 k2 ;
          if List.length pl > 2 then
            List.iter (fun p -> Wserver.printf " > %s" p)
              (List.tl (List.tl pl)) ;
        in
        List.iter (fun pl -> print_pl pl; Wserver.printf "</li>") searchl
    | _ -> ()

let print_places_surnames conf base array long searchl=
  let rec sort_place_utf8 pl1 pl2 =
    match pl1, pl2 with
    | _, [] -> 1
    | [], _ -> -1
    | s1 :: pl11, s2 :: pl22 ->
        match Gutil.alphabetic_order s1 s2 with
        | 0 -> sort_place_utf8 pl11 pl22
        | x -> x
  in
  Array.sort (fun (pl1, _) (pl2, _) -> sort_place_utf8 pl1 pl2) array ;
  let title _ =
    Wserver.printf "%s / %s" (capitale (transl conf "place"))
      (capitale (transl_nth conf "surname/surnames" 0))
  in
  let k2_no = Array.for_all (fun (pl, _) -> pl = []) array in
  Hutil.header conf title ;
  Hutil.print_link_to_welcome conf true ;
  Hutil.interp_no_header conf "buttons_places"
    {Templ.eval_var = eval_var conf base;
     Templ.eval_transl = (fun _ -> Templ.eval_transl conf);
     Templ.eval_predefined_apply = (fun _ -> raise Not_found);
     Templ.get_vother = get_vother; Templ.set_vother = set_vother;
     Templ.print_foreach = print_foreach conf}
    [] () ;
  if array <> [||] then
    if long || k2_no
    then print_html_places_surnames_long conf base array
    else print_html_places_surnames_short conf base array;
  if searchl <> [] then
    begin
      let k1 = match p_getenv conf.env "k1" with | Some s -> s | _ -> "" in
      let k2 = match p_getenv conf.env "k2" with | Some s -> s | _ -> "" in
      let opt = get_opt conf in
      let substr = p_getenv conf.env "substr" = Some "on" in
      let exact = p_getenv conf.env "exact" = Some "on" in
      let search =
        match p_getenv conf.env "search" with
        | Some "on" -> ""
        | _ -> "&search=on"
      in
      let search_on = p_getenv conf.env "search" = Some "on" in
      Wserver.printf "<hr>";
      if not search_on then
        Wserver.printf "<a href=\"%sm=PS%s%s%s%s%s%s\">%s %s “%s”</a>\n"
          (commd conf)
          (if k1 <> "" then "&k1=" ^ k1 else "")
          (if k2 <> "" then "&k2=" ^ k2 else "") opt 
          (if substr then "&substr=on" else "")
          (if exact then "&exact=on" else "") search
          (capitale (transl_nth conf "visualize/show/hide/summary" 1))
          (transl conf "search results") k1
      else
        Wserver.printf "%s “%s”%s\n" (capitale (transl conf "search results"))
          k1 (transl conf ":");
      Wserver.printf "<ul class=\"list-unstyled my-2\">";
      print_searchl conf searchl;
      Wserver.printf "</ul>";
    end ;
  Hutil.trailer conf

let match_place str1 str2 exact substr =
  match (str1, str2) with
  | ("", "") -> true
  | (s1, s2) ->
      let s1 = if exact then s1 else Name.lower (Some.name_unaccent s1) in
      let s2 = if exact then s2 else Name.lower (Some.name_unaccent s2) in
      if not substr then s1 = s2
      else if s2 = "" then false else Mutil.contains s1 s2

let filter_array array place i exact substr =
  if place <> "" then
    Array.of_list (Array.fold_left
      (fun acc (pl, snl) ->
        if i = 0 then
          if match_place (if List.length pl > 0 then List.hd pl else "")
           place exact substr
          then (pl, snl) :: acc else acc
        else
          (* let _ = Printf.eprintf "Test: %s %s\n"
            place (if List.length pl > 1 then (List.hd (List.tl pl)) else "") in *)
          if match_place
            (if List.length pl > 1 then (List.hd (List.tl pl)) else "")
            place exact substr
          then (pl, snl) :: acc else acc) [] array)
  else array

let search_array array k exact =
  if k <> "" then
    let k = if exact then k else Name.lower (Some.name_unaccent k) in
    let is_in_list k l =
      List.exists (fun p -> Mutil.contains
        (if exact then p else (Name.lower (Some.name_unaccent p))) k) l
    in
    Array.fold_left
      (fun acc (pl, _) -> if is_in_list k pl then pl :: acc else acc) [] array
  else []

let print_places_surnames_some conf base array =
  let k1 = match p_getenv conf.env "k1" with | Some s -> s | _ -> "" in
  let k2 = match p_getenv conf.env "k2" with | Some s -> s | _ -> "" in
  let exact = p_getenv conf.env "exact" = Some "on" in
  let substr = p_getenv conf.env "substr" = Some "on" in
  (*
  let _ = Printf.eprintf "Exact : %s\n" (if exact then "true" else "false") in
  let _ = Printf.eprintf "Substr : %s\n" (if substr then "true" else "false") in
  let _ = flush stderr in
  *)
  let searchl = search_array array k1 exact in
  let array =
    if k1 <> "" then filter_array array k1 0 exact substr else array
  in
  (*let _ = Printf.eprintf "Array after k1 : %d\n" (Array.length array) in*)
  let array =
    if k2 <> "" then filter_array array k2 1 exact substr else array
  in
  (*let _ = Printf.eprintf "Array after k2 : %d\n" (Array.length array) in*)
  let long = p_getenv conf.env "long" = Some "on" in
  let k1 = p_getenv conf.env "k1" <> Some "" in
  let k2 =
    match p_getenv conf.env "k2" with
    | Some "" -> false
    | Some _ -> true
    | _ -> false
  in
  print_places_surnames conf base array
    (long || (k1 && k2)) searchl

let print_all_places_surnames conf base =
  let add_birth = p_getenv conf.env "bi" = Some "on" in
  let add_baptism = p_getenv conf.env "bp" = Some "on" in
  let add_death = p_getenv conf.env "de" = Some "on" in
  let add_burial = p_getenv conf.env "bu" = Some "on" in
  let inverted =
    try List.assoc "places_inverted" conf.base_env = "yes"
    with Not_found -> false
  in
  let array =
    get_all conf base ~add_birth ~add_baptism ~add_death ~add_burial
      [] [] (fold_place_long inverted) (fun _ -> true)
      (fun prev p ->
         let value = (get_surname p, get_key_index p) in
         match prev with Some list -> value :: list | None -> [ value ])
      (fun v ->
         let v = List.sort (fun (a, _) (b, _) -> compare a b) v in
         let rec loop acc list = match list, acc with
           | [], _ -> acc
           | (sn, iper) :: tl_list,
              (sn', iper_list) :: tl_acc when (sou base sn) = sn' ->
             loop ((sn', iper:: iper_list) :: tl_acc) tl_list
           | (sn, iper) :: tl_list, _ ->
             loop ((sou base sn, [iper]) :: acc) tl_list
         in
         loop [] v)
  in
  print_places_surnames_some conf base array


