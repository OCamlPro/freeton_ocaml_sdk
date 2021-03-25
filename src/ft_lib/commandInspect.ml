(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2021 OCamlPro SAS                                       *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the GNU Lesser General    *)
(*  Public License version 2.1, with the special exception on linking     *)
(*  described in the LICENSE.md file in the root directory.               *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

open Ezcmd.V2
open EZCMD.TYPES
(* open Ez_subst.V1 *)
(* open EzFile.OP *)
open Ton_sdk (* REQUEST, ENCODING *)

let query_message config ~level msg_id =
  Utils.post config (match msg_id with
      | "all" -> REQUEST.messages ~level []
      | _ -> REQUEST.messages ~level ~id:msg_id [])


let query_messages config ~level ids =
  List.flatten ( List.map  ( query_message ~level config ) ids )

let inspect_transaction ~v tr_id =
  let config = Config.config () in

  let trs =
    Utils.post config
      (match tr_id with
       | "all" -> REQUEST.transactions ~level:3 []
       | _ -> REQUEST.transaction ~level:3 tr_id
      )
  in
  List.iter (fun tr ->

      Printf.printf "\nTRANSACTION: %s\n%!"
        (ENCODING.string_of_transaction tr);

      if v then begin

        let msgs = query_messages ~level:1 config [ tr.tr_in_msg ] in
        List.iter (fun tr ->
            Printf.printf "\n  IN MESSAGE: %s\n%!"
              (ENCODING.string_of_message tr);
          ) msgs ;

        let msgs = query_messages ~level:1 config tr.tr_out_msgs in
        List.iter (fun tr ->
            Printf.printf "\n  OUT MESSAGE: %s\n%!"
              (ENCODING.string_of_message tr);
          ) msgs ;
      end

    ) trs

let inspect_account ~level account =
  let config = Config.config () in
  let request = match account with
    | "all" ->
        REQUEST.accounts ~level []
    | _ ->
        let address = Utils.address_of_account config account in
        REQUEST.account ~level address
  in
  let accounts =
    Utils.post config request
  in
  List.iter (fun account ->
      Printf.printf "\nACCOUNT: %s\n%!"
        (ENCODING.string_of_account account) ) accounts

let inspect_block ~level ~id =
  let config = Config.config () in
  let blocks =
    Utils.post config (match id with
        | `string "all" -> REQUEST.blocks ~level []
        | _ -> REQUEST.block ~level id)
  in
  List.iter (fun b ->
      Printf.printf "\nBLOCK: %s\n%!"
        (ENCODING.string_of_block b) ) blocks

let inspect_head ~level () =
  let config = Config.config () in
  let blocks =
    Utils.post config (REQUEST.head ~level ())
  in
  List.iter (fun b ->
      Printf.printf "BLOCK: %s\n%!"
        (ENCODING.string_of_block b) ) blocks


let inspect_message ~level id =
  let config = Config.config () in
  let messages = query_message config ~level id in
  List.iter (fun msg ->
      Printf.printf "MESSAGE\n: %s\n%!"
        (ENCODING.string_of_message msg) ) messages


let cmd =
  EZCMD.sub
    "inspect"
    (fun () -> ())
    ~args:
      [
        [ "t" ], Arg.String (fun s -> inspect_transaction ~v:false s),
        EZCMD.info "TR_ID Inspect transaction TR_ID on blockchain";
        [ "t2"; "t3" ], Arg.String (fun s -> inspect_transaction ~v:true s),
        EZCMD.info "TR_ID Inspect transaction TR_ID on blockchain";

        [ "a" ], Arg.String (fun s -> inspect_account ~level:1 s),
        EZCMD.info "ACCOUNT Inspect account TR_ID on blockchain";
        [ "a2" ], Arg.String (fun s -> inspect_account ~level:2 s),
        EZCMD.info "ACCOUNT Inspect account TR_ID on blockchain";
        [ "a3" ], Arg.String (fun s -> inspect_account ~level:3 s),
        EZCMD.info "ACCOUNT Inspect account TR_ID on blockchain";

        [ "bn" ], Arg.String (fun s ->
            inspect_block ~level:3 ~id:(`int (int_of_string s))),
        EZCMD.info "LEVEL Inspect block at LEVEL on blockchain";

        [ "b" ], Arg.String (fun s ->
            inspect_block ~level:1 ~id:(`string s)),
        EZCMD.info "BLOCK Inspect block TR_ID on blockchain";
        [ "b2" ], Arg.String (fun s ->
            inspect_block ~level:2 ~id:(`string s)),
        EZCMD.info "BLOCK Inspect block TR_ID on blockchain";
        [ "b3" ], Arg.String (fun s ->
            inspect_block ~level:3 ~id:(`string s)),
        EZCMD.info "BLOCK Inspect block TR_ID on blockchain";

        [ "h" ], Arg.Unit (fun () -> inspect_head ~level:1 ()),
        EZCMD.info "Inspect head";
        [ "h2" ], Arg.Unit (fun () -> inspect_head ~level:2 ()),
        EZCMD.info "Inspect head";
        [ "h3" ], Arg.Unit (fun () -> inspect_head ~level:3 ()),
        EZCMD.info "Inspect head";

        [ "m" ], Arg.String (fun s -> inspect_message ~level:1 s),
        EZCMD.info "MSG_ID Inspect message MSG_ID on blockchain";
        [ "m2" ], Arg.String (fun s -> inspect_message ~level:2 s),
        EZCMD.info "MSG_ID Inspect message MSG_ID on blockchain";
        [ "m3" ], Arg.String (fun s -> inspect_message ~level:3 s),
        EZCMD.info "MSG_ID Inspect message MSG_ID on blockchain";
      ]
    ~doc: "Monitor a given account"
