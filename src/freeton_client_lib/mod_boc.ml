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

(*
enum BocErrorCode {
    InvalidBoc = 201,
    SerializationError = 202,
    InappropriateBlock = 203,
    MissingSourceBoc = 204,
    InsufficientCacheSize = 205,
    BocRefNotFound = 206,
    InvalidBocRef = 207
}
*)

type any = Json_repr.ezjsonm [@@deriving json_encoding]
type number = int [@@deriving json_encoding]

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               TYPES                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module BocCacheType = struct

  type t =
    | Pinned of ( string  [@obj1 "pin"] )
                [@kind "Pinned" ] [@kind_label "type"]
    | Unpinned
      [@kind "Unpinned" ] [@kind_label "type"]
  [@@deriving json_encoding ]

  let t_enc = enc

end

module BuilderOp = struct

  type t =
    | Integer of { size: int ; value : any }
                 [@kind "Integer" ] [@kind_label "type"]
    | BitString of { value : string }
                   [@kind "BitString" ] [@kind_label "type"]
    | Cell of { builder: any (* TODO BuilderOp.t list *) }
              [@kind "Cell" ] [@kind_label "type"]
    | CellBoc of { boc : string }
                 [@kind "CellBoc" ] [@kind_label "type"]
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

module Parse = struct
  type params = {
    boc: string
  }
  [@@deriving json_encoding]

  type result = {
    parsed: any ;
  }
  [@@deriving json_encoding]
end

module ParseMessage = struct
  open Parse
  let f = Tc.f "parse_message" ~params_enc ~result_enc
end

module ParseTransaction = struct
  open Parse

  let f = Tc.f "parse_transaction" ~params_enc ~result_enc
end

module ParseAccount = struct
  open Parse

  let f = Tc.f "parse_account" ~params_enc ~result_enc
end

module ParseBlock = struct
  open Parse

  let f = Tc.f "parse_block" ~params_enc ~result_enc
end

module ParseShardstate = struct
  type params = {
    boc: string ;
    id: string ;
    workchain_id: int ;
  }
  [@@deriving json_encoding]

  type result = {
    parsed: any
  }
  [@@deriving json_encoding]

  let f = Tc.f "parse_shardstate" ~params_enc ~result_enc
end

module GetBlockchainConfig = struct

  type params = {
    block_boc: string ;
  }
  [@@deriving json_encoding]

  type result = {
    config_boc: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "get_blockchain_config" ~params_enc ~result_enc

end

module GetBocHash = struct

  type params = {
    boc: string
  }
  [@@deriving json_encoding]

  type result = {
    hash: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "get_boc_hash" ~params_enc ~result_enc

end

module GetCodeFromTvc = struct

  type params = {
    tvc: string
  }
  [@@deriving json_encoding]

  type result = {
    code: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "get_code_from_tvc" ~params_enc ~result_enc

end

module BocCacheGet = struct

  type params = {
    boc_ref: string
  }
  [@@deriving json_encoding]

  type result = {
    boc: string option ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "cache_get" ~params_enc ~result_enc

end

module BocCacheSet = struct

  type params = {
    boc: string ;
    cache_type: BocCacheType.t ;
  }
  [@@deriving json_encoding]

  type result = {
    boc_ref: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "cache_set" ~params_enc ~result_enc

end

module BocCacheUnpin = struct
  type params = {
    pin: string ;
    boc_ref: string option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "cache_unpin" ~params_enc ~result_enc

end

module EncodeBoc = struct

  type params = {
    builder: BuilderOp.t list ;
    boc_cache: BocCacheType.t option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    boc: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "encode_boc" ~params_enc ~result_enc

end


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
