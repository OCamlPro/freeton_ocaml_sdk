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

open Mod_abi
open Mod_boc

(*
enum TvmErrorCode {
    CanNotReadTransaction = 401,
    CanNotReadBlockchainConfig = 402,
    TransactionAborted = 403,
    InternalError = 404,
    ActionPhaseFailed = 405,
    AccountCodeMissing = 406,
    LowBalance = 407,
    AccountFrozenOrDeleted = 408,
    AccountMissing = 409,
    UnknownExecutionError = 410,
    InvalidInputStack = 411,
    InvalidAccountBoc = 412,
    InvalidMessageType = 413,
    ContractExecutionError = 414
}
*)

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               TYPES                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)


module TransactionFees = struct
  type t = {
    in_msg_fwd_fee: string ; (* bigint in fact *)
    storage_fee: string ;
    gas_fee: string ;
    out_msgs_fwd_fee: string ;
    total_account_fees: string ;
    total_output: string ;
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module AccountForExecutor = struct

  type t =
    | None [@kind "None"] [@kind_label "type"]
    | Uninit [@kind "Uninit"] [@kind_label "type"]
    | Account of { boc : string ;
                   unlimited_balance : bool option; [@opt None]
                 }
                 [@kind "Account"] [@kind_label "type"]
  [@@deriving json_encoding ]

  let t_enc = enc
end

module ExecutionOptions = struct
  type t = {
    blockchain_config: string option ; [@opt None]
    block_time: int option ; [@opt None]
    block_lt: string option ; [@opt None] (* bigint *)
    transaction_lt: string option ; [@opt None] (* bigint *)
  }
  [@@deriving json_encoding ]

  let t_enc = enc

end

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               FUNCTIONS                                *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module RunExecutor = struct

  type params = {
    message: string ;
    account: AccountForExecutor.t ;
    execution_options: ExecutionOptions.t option ; [@opt None]
    abi: Abi.t option ; [@opt None]
    skip_transaction_check: bool option ; [@opt None]
    boc_cache: BocCacheType.t option ; [@opt None]
    return_updated_account: bool option ;  [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    transaction: any ;
    out_messages: string list ;
    decoded: DecodedOutput.t option ; [@opt None]
    account: string ;
    fees: TransactionFees.t ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "run_executor" ~params_enc ~result_enc

end

module RunTvm = struct

  type params = {
    message: string ;
    account: string ;
    execution_options: ExecutionOptions.t option ; [@opt None]
    abi: Abi.t option ; [@opt None]
    boc_cache: BocCacheType.t option ; [@opt None]
    return_updated_account: bool option  ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    out_messages: string list ;
    decoded: DecodedOutput.t option ; [@opt None]
    account: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "run_tvm" ~params_enc ~result_enc

end

module RunGet = struct

  type params = {
    account: string ;
    function_name: string ;
    input: any option ; [@opt None]
    execution_options: ExecutionOptions.t option ; [@opt None]
    tuple_list_as_array: bool option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    output: any ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "run_get" ~params_enc ~result_enc

end

let run_executor = Tc.request_sync RunExecutor.f
let run_tvm = Tc.request_sync RunTvm.f
let run_get = Tc.request_sync RunGet.f
