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

open Mod_boc
open Mod_abi

(*
enum NetErrorCode {
    QueryFailed = 601,
    SubscribeFailed = 602,
    WaitForFailed = 603,
    GetSubscriptionResultFailed = 604,
    InvalidServerResponse = 605,
    ClockOutOfSync = 606,
    WaitForTimeout = 607,
    GraphqlError = 608,
    NetworkModuleSuspended = 609,
    WebsocketDisconnected = 610,
    NotSupported = 611,
    NoEndpointsProvided = 612,
    GraphqlWebsocketInitError = 613,
    NetworkModuleResumed = 614
}
*)

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               TYPES                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module SortDirection = struct

  type t = string
    [@@deriving json_encoding ]

      (* enum SortDirection {
    ASC = "ASC",
    DESC = "DESC"
}
      *)

  let t_enc = enc

end

module OrderBy = struct

  type t = {
    path: string ;
    direction: SortDirection.t ;
  }
  [@@deriving json_encoding ]

  let t_enc = enc

end

module AggregationFn = struct

  type t = string
  [@@deriving json_encoding ]

  (*
enum AggregationFn {
    COUNT = "COUNT",
    MIN = "MIN",
    MAX = "MAX",
    SUM = "SUM",
    AVERAGE = "AVERAGE"
}
*)

  let t_enc = enc

end

module FieldAggregation = struct

  type t = {
    field: string ;
    fn: AggregationFn.t ;
  }
  [@@deriving json_encoding ]

  let t_enc = enc

end

module EndpointsSet = struct
  type t = {
    endpoints: string list
  }
  [@@deriving json_encoding]

  let t_enc = enc
end

module MessageNode = struct

  type t = {
    id: string ;
    src_transaction_id: string option ; [@opt None]
    dst_transaction_id: string option ; [@opt None]
    src: string option ; [@opt None]
    dst: string option ; [@opt None]
    value: string option ; [@opt None]
    bounce: bool ;
    decoded_body: DecodedMessageBody.t option ; [@opt None]
  }
  [@@deriving json_encoding]
  let t_enc = enc

end

module TransactionNode = struct

  type t = {
    id: string ;
    in_msg: string ;
    out_msgs: string list ;
    account_addr: string ;
    total_fees: string ;
    aborted: bool ;
    exit_code: number option ;
  }
  [@@deriving json_encoding]
  let t_enc = enc

end

module RegisteredIterator = struct
  type t = {
    handle: number
  }
  [@@deriving json_encoding]
  let t_enc = enc
end

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               FUNCTIONS                                *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module Query = struct

  type params = {
    query: string ;
    variables: any option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    result: any ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "query" ~params_enc ~result_enc

end

module QueryCollection = struct

  type params = {
    collection: string ;
    filter: any option ; [@opt None]
    result: string ;
    order: OrderBy.t list option ; [@opt None]
    limit: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    result: any list;
  }
  [@@deriving json_encoding]

  let f = Tc.f "query_collection" ~params_enc ~result_enc

end

module WaitForCollection = struct

  type params = {
    collection: string ;
    filter : any option ; [@opt None]
    result : string ;
    timeout: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    result: any
  }
  [@@deriving json_encoding]

  let f = Tc.f "wait_for_collection" ~params_enc ~result_enc

end

module AggregateCollection = struct
  type params = {
    collection: string ;
    filter: any option ; [@opt None ]
    fields: FieldAggregation.t list option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    values: any ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "aggregate_collection" ~params_enc ~result_enc

end

module QueryCounterparties = struct

  type params = {
    account: string ;
    result: string ;
    first: number option ; [@opt None]
    after: string option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    result: any list
  }
  [@@deriving json_encoding]

  let f = Tc.f "query_counterparties" ~params_enc ~result_enc

end

module ParamsOfQueryOperation = struct

  type t =
    | QueryCollection of QueryCollection.params
                         [@kind "QueryCollection" ] [@kind_label "type"]
    | WaitForCollection of WaitForCollection.params
                           [@kind "WaitForCollection" ] [@kind_label "type"]
    | AggregateCollection of AggregateCollection.params
                             [@kind "AggregateCollection" ] [@kind_label "type"]
    | QueryCounterparties of QueryCounterparties.params
                             [@kind "QueryCounterparties" ] [@kind_label "type"]
  [@@deriving json_encoding]

  let t_enc = enc

end

module BatchQuery = struct

  type params = {
    operations: ParamsOfQueryOperation.t list ;
  }
  [@@deriving json_encoding]

  type result = {
    results: any list ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "batch_query" ~params_enc ~result_enc

end

module SubscribeCollection = struct

  type params = {
    collection: string ;
    filter: any option ; [@opt None]
    result: string
  }
  [@@deriving json_encoding]

  type result = {
    handle: number
  }
  [@@deriving json_encoding]

  let f = Tc.f "subscribe_collection" ~params_enc ~result_enc

end

module Unsubscribe = struct

  type params = SubscribeCollection.result
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "unsubscribe" ~params_enc ~result_enc

end

module Suspend = struct

  type params = unit
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "suspend" ~params_enc ~result_enc

end

module Resume = struct

  type params = unit
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "resume" ~params_enc ~result_enc

end

module FindLastShardBlock = struct

  type params = {
    address: string
  }
  [@@deriving json_encoding]

  type result = {
    block_id: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "find_last_shard_block" ~params_enc ~result_enc

end

module FetchEndpoints = struct

  type params = unit
  [@@deriving json_encoding]

  type result = EndpointsSet.t
  [@@deriving json_encoding]

  let f = Tc.f "fetch_endpoints" ~params_enc ~result_enc

end

module SetEndpoints = struct

  type params = EndpointsSet.t
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "set_endpoints" ~params_enc ~result_enc

end

module GetEndpoints = struct

  type params = unit
  [@@deriving json_encoding]

  type result = {
    query: string ;
    endpoints: string list ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "get_endpoints" ~params_enc ~result_enc

end

module QueryTransactionTree = struct

  type params = {
    in_msg: string ;
    abi_registry: Abi.t list option ; [@opt None]
    timeout : number ;
  }
  [@@deriving json_encoding]

  type result = {
    messages: MessageNode.t list ;
    transactions: TransactionNode.t list ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "query_transaction_tree" ~params_enc ~result_enc

end

module CreateBlockIterator = struct
  type params = {
    start_time: number option ; [@opt None]
    end_time: number option ; [@opt None]
    shard_filter: string list option ; [@opt None]
    result: string option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = RegisteredIterator.t
  [@@deriving json_encoding]

  let f = Tc.f "create_block_iterator" ~params_enc ~result_enc


end

module ResumeBlockIterator = struct

  type params = {
    resume_state: any
  }
  [@@deriving json_encoding]

  type result = RegisteredIterator.t
  [@@deriving json_encoding]

  let f = Tc.f "resume_block_iterator" ~params_enc ~result_enc

end

module CreateTransactionIterator = struct
  type params = {
    start_time: number option ; [@opt None]
    end_time: number option ; [@opt None]
    shard_filter: string list option ; [@opt None]
    accounts_filter: string list option ; [@opt None]
    result: string option ; [@opt None]
    include_transfers: bool option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = RegisteredIterator.t
  [@@deriving json_encoding]

  let f = Tc.f "create_transaction_iterator" ~params_enc ~result_enc

end

module ResumeTransactionIterator = struct

  type params = {
    resume_state: any ;
    accounts_filter: string list option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = RegisteredIterator.t
  [@@deriving json_encoding]

  let f = Tc.f "resume_transaction_iterator" ~params_enc ~result_enc

end

module IteratorNext = struct

  type params = {
    iterator: number ;
    limit: number option ; [@opt None]
    return_resume_state: bool option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    items: any list ;
    has_more: bool ;
    resume_state: any option ; [@opt None]
  }
  [@@deriving json_encoding]

  let f = Tc.f "iterator_next" ~params_enc ~result_enc

end

module RemoveIterator = struct

  type params = RegisteredIterator.t
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "remove_iterator" ~params_enc ~result_enc

end

let query = Tc.request Query.f
let batch_query = Tc.request BatchQuery.f
let query_collection = Tc.request QueryCollection.f
let aggregate_collection = Tc.request AggregateCollection.f
let wait_for_collection = Tc.request WaitForCollection.f
let query_counterparties = Tc.request QueryCounterparties.f
let unsubscribe = Tc.request Unsubscribe.f
let subscribe_collection = Tc.request SubscribeCollection.f
let suspend = Tc.request Suspend.f
let resume = Tc.request Resume.f
let find_last_shard_block = Tc.request FindLastShardBlock.f
let fetch_endpoints = Tc.request FetchEndpoints.f
let set_endpoints = Tc.request SetEndpoints.f
let get_endpoints = Tc.request GetEndpoints.f
let query_transaction_tree = Tc.request QueryTransactionTree.f
let create_block_iterator = Tc.request CreateBlockIterator.f
let resume_block_iterator = Tc.request ResumeBlockIterator.f
let create_transaction_iterator = Tc.request CreateTransactionIterator.f
let resume_transaction_iterator = Tc.request ResumeTransactionIterator.f
let iterator_next = Tc.request IteratorNext.f
let remove_iterator = Tc.request RemoveIterator.f
