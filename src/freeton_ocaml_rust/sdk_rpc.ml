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

external sync_ml : string -> string -> string ->
  string Sdk_types.reply = "ton_client_request_ml"

let sync ~network ~meth ~params =
  Sdk_types.reply ( sync_ml network meth params )
