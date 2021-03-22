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

type kind = Messages | Transactions

let action ~account ~kind =
  (* TODO *)
  ignore( account, kind )

let cmd =
  let account = ref None in
  let kind = ref Transactions in
  EZCMD.sub
    "watch"
    (fun () ->
       action
         ~account:!account
         ~kind:!kind
    )
    ~args:
      [

        [ "account" ], Arg.String (fun s -> account := Some s),
        EZCMD.info "ACCOUNT Output account of account";

        [ "messages" ], Arg.Unit (fun () -> kind := Messages),
        EZCMD.info "Monitor messages instead of transactions";
      ]
    ~doc: "Monitor a given account"
