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
  Freeton_types.state_init Freeton_types.reply = "tvc_load_ml"

let read filename = Freeton_types.reply @@ read_ml filename


external data_ml :
  Freeton_types.state_init -> string Freeton_types.reply = "tvc_data_ml"
let data state = Freeton_types.reply @@ data_ml state

external code_ml :
  Freeton_types.state_init -> string Freeton_types.reply = "tvc_code_ml"
let code state = Freeton_types.reply @@ code_ml state

external code_hash_ml :
  Freeton_types.state_init -> string Freeton_types.reply = "tvc_code_hash_ml"
let code_hash state = Freeton_types.reply @@ code_hash_ml state

external code_depth_ml :
  Freeton_types.state_init -> int64 Freeton_types.reply = "tvc_code_depth_ml"
let code_depth state = Freeton_types.reply @@ code_depth_ml state

external data_hash_ml :
  Freeton_types.state_init -> string Freeton_types.reply = "tvc_data_hash_ml"
let data_hash state = Freeton_types.reply @@ data_hash_ml state

external data_depth_ml :
  Freeton_types.state_init -> int64 Freeton_types.reply = "tvc_data_depth_ml"
let data_depth state = Freeton_types.reply @@ data_depth_ml state
