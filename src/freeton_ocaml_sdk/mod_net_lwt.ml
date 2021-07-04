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
include Ton_client.NET

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
