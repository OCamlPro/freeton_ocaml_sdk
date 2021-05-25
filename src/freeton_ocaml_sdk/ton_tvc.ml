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

external read_ml : string ->
  Ton_types.state_init Ton_types.reply = "tvc_load_ml"

let read filename = Ton_types.reply @@ read_ml filename


external data_ml :
  Ton_types.state_init -> string Ton_types.reply = "tvc_data_ml"
let data state = Ton_types.reply @@ data_ml state

external code_ml :
  Ton_types.state_init -> string Ton_types.reply = "tvc_code_ml"
let code state = Ton_types.reply @@ code_ml state

external code_hash_ml :
  Ton_types.state_init -> string Ton_types.reply = "tvc_code_hash_ml"
let code_hash state = Ton_types.reply @@ code_hash_ml state
