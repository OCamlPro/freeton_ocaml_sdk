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

open Ton_client_lwt
include Ton_client.BOC

let parse_message = Tc.request ParseMessage.f
let parse_transaction = Tc.request ParseTransaction.f
let parse_account = Tc.request ParseAccount.f
let parse_block = Tc.request ParseBlock.f
let parse_shardstate = Tc.request ParseShardstate.f
let get_blockchain_config = Tc.request GetBlockchainConfig.f
let get_boc_hash = Tc.request GetBocHash.f
let get_code_from_tvc = Tc.request GetCodeFromTvc.f
let cache_get = Tc.request BocCacheGet.f
let cache_set = Tc.request BocCacheSet.f
let cache_unpin = Tc.request BocCacheUnpin.f
let encode_boc = Tc.request EncodeBoc.f
