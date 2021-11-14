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

include Ton_client.BOC

let parse_message = Tc_lwt.request ParseMessage.f
let parse_transaction = Tc_lwt.request ParseTransaction.f
let parse_account = Tc_lwt.request ParseAccount.f
let parse_block = Tc_lwt.request ParseBlock.f
let parse_shardstate = Tc_lwt.request ParseShardstate.f
let get_blockchain_config = Tc_lwt.request GetBlockchainConfig.f
let get_boc_hash = Tc_lwt.request GetBocHash.f
let get_code_from_tvc = Tc_lwt.request GetCodeFromTvc.f
let cache_get = Tc_lwt.request BocCacheGet.f
let cache_set = Tc_lwt.request BocCacheSet.f
let cache_unpin = Tc_lwt.request BocCacheUnpin.f
let encode_boc = Tc_lwt.request EncodeBoc.f
