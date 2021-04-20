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
let wait_next_block ~client ~block_id ~address ?timeout () =
  Ton_types.reply
    (
      wait_next_block_ml client block_id address timeout
    )

external decode_message_boc_ml :
  Ton_types.client->
  string ->
  string ->
  Ton_types.decoded_message_body Ton_types.reply = "decode_message_boc_ml"

let decode_message_boc ~client ~boc ~abi =
  Ton_types.reply
    (
      decode_message_boc_ml client boc abi
    )
