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

external find_last_shard_block_ml :
  Ton_types.client->
  string ->
  string Ton_types.reply = "find_last_shard_block_ml"

let find_last_shard_block ~client ~address =
  Ton_types.reply
    (
      find_last_shard_block_ml client address
    )

external wait_next_block_ml :
  Ton_types.client->
  string ->
  string ->
  int64 option ->
  Ton_types.block Ton_types.reply = "wait_next_block_ml"

(* timeout is in ms *)
let wait_next_block ~client ~blockid ~address ?timeout () =
  Ton_types.reply
    (
      wait_next_block_ml client blockid address timeout
    )
