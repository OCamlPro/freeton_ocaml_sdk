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

let action switch =
  match switch with
  | None -> Config.print ()
  | Some s ->
      Config.set_config := Some s;
      let config = Config.config () in
      config.modified <- true

let cmd =
  let switch = ref None in
  EZCMD.sub
    "switch"
    (fun () -> action !switch)
    ~args: (
      [ ( [],
          Arg.Anon (0, fun s -> switch := Some s),
          EZCMD.info "New switch config" )
      ] )
    ~doc: "Change current switch"
