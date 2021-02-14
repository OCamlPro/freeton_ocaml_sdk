(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2021 OCamlPro SAS & Origin Labs SAS                     *)
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

let action args =
  let config = Config.config () in
  Misc.call ( Misc.tonoscli config args )

let cmd =
  let args = ref [] in
  EZCMD.sub
    "client"
    (fun () ->
       action !args
    )
    ~args:
      [ [],
        Arg.Anons (fun list -> args := list),
        EZCMD.info "Arguments to tonos-cli" ;
      ]
    ~doc: "Call tonos-cli, use -- to separate arguments"
