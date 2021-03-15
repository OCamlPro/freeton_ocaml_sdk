(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2021 Origin Labs & OCamlPro SAS                         *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the GNU Lesser General    *)
(*  Public License version 2.1, with the special exception on linking     *)
(*  described in the LICENSE.md file in the root directory.               *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

open Json_encoding

type info_in = {
  ton_version : string;
  ton_time : int64 [@encoding Json_encoding.int53];
} [@@deriving json_encoding]

type info = info_in [@obj1 "info"] [@@deriving json_encoding]

let z_enc = conv Z.to_string Z.of_string string
type z = Z.t [@encoding z_enc] [@@deriving json_encoding]

(* AccountStatusEnum can be:
   0 => Uninit
   1 => Active
 *)
type account = {
  acc_id : string;
  acc_type : int; [@key "acc_type"]
  acc_type_name: string option ; (* AccountStatusEnum *) [@key "acc_type_name"]
  acc_balance : z option;
  (*  balance_other: [OtherCurrency] *)
  acc_boc : string option ;
  acc_code : string option ;
  acc_code_hash : string option ;
  acc_data: string option ;
  acc_data_hash: string option ;
  (*  due_payment(format: BigIntFormat): String *)
  acc_last_paid: float option ;
  (* last_trans_lt(format: BigIntFormat): String *)
  acc_library: string option ;
  acc_library_hash: string option ;
  acc_proof: string option ;
  acc_split_depth: int option ;
  acc_state_hash: string option ;
  acc_tick: bool option ;
  acc_tock: bool option ;
  acc_workchain_id: int option ;
} [@@deriving json_encoding]

type accounts = account list [@obj1 "accounts"] [@@deriving json_encoding]

type ext_blk_ref = {
  ebr_end_lt : string;
  ebr_seq_no : int;
  ebr_root_hash : string;
  ebr_file_hash : string;
} [@@deriving json_encoding]

type block_value_flow = {
  bl_volume : z; [@key "to_next_blk"]
  bl_fees : z; [@key "fees_collected"]
  bl_minted : z;
} [@@deriving json_encoding]

type block = {
  bl_id : string;
  bl_status : int;
  bl_chain : int; [@key "workchain_id"]
  bl_shard : string;
  bl_level : int; [@key "seq_no"]
  bl_prev_ref : ext_blk_ref;
  bl_time : int64; [@key "gen_utime"] [@encoding int53]
  bl_collator : string; [@key "created_by"]
  bl_tr_count : int;
  bl_key_block : bool;
  bl_value_flow : block_value_flow;
} [@@deriving json_encoding]

type blocks = block list [@obj1 "blocks"] [@@deriving json_encoding]

type message = {
  msg_id : string;
  msg_type : int; [@key "msg_type"]
  msg_status : int;
  msg_block_id : string option;
  msg_src : string;
  msg_dst : string;
  msg_value : z option;
} [@@deriving json_encoding {option="option"}]

type messages = message list [@obj1 "messages"] [@@deriving json_encoding]

type transaction = {
  tr_id : string;
  tr_type : int; [@key "tr_type"]
  tr_status : int;
  tr_block_id : string;
  tr_account_addr : string;
  tr_total_fees : z;
  tr_balance_delta : z;
  tr_in_message : message option;
} [@@deriving json_encoding {option="option"}]

type transactions = transaction list [@obj1 "transactions"] [@@deriving json_encoding]
