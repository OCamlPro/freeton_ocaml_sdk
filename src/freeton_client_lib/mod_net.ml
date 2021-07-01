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


(* TODO:

unsubscribe – Cancels a subscription

subscribe_collection – Creates a subscription

suspend – Suspends network module to stop any network activity

resume – Resumes network module to enable network activity

find_last_shard_block – Returns ID of the last block in a specified account shard

fetch_endpoints – Requests the list of alternative endpoints from server

set_endpoints – Sets the list of endpoints to use on reinit

get_endpoints – Requests the list of alternative endpoints from server

query_transaction_tree – Returns transactions tree for specific message.

create_block_iterator – Creates block iterator.

resume_block_iterator – Resumes block iterator.

create_transaction_iterator – Creates transaction iterator.

resume_transaction_iterator – Resumes transaction iterator.

iterator_next – Returns next available items.

remove_iterator – Removes an iterator
*)

let query = Tc.request_sync Query.f
let batch_query = Tc.request_sync BatchQuery.f
let query_collection = Tc.request_sync QueryCollection.f
let aggregate_collection = Tc.request_sync AggregateCollection.f
let wait_for_collection = Tc.request_sync WaitForCollection.f
let query_counterparties = Tc.request_sync QueryCounterparties.f
