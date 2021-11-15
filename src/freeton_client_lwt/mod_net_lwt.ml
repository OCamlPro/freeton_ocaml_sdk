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

include Ton_client.NET

let query = Tc_lwt.request Query.f
let batch_query = Tc_lwt.request BatchQuery.f
let query_collection = Tc_lwt.request QueryCollection.f
let aggregate_collection = Tc_lwt.request AggregateCollection.f
let wait_for_collection = Tc_lwt.request WaitForCollection.f
let query_counterparties = Tc_lwt.request QueryCounterparties.f
let unsubscribe = Tc_lwt.request Unsubscribe.f
let subscribe_collection = Tc_lwt.request SubscribeCollection.f
let suspend = Tc_lwt.request Suspend.f
let resume = Tc_lwt.request Resume.f
let find_last_shard_block = Tc_lwt.request FindLastShardBlock.f
let fetch_endpoints = Tc_lwt.request FetchEndpoints.f
let set_endpoints = Tc_lwt.request SetEndpoints.f
let get_endpoints = Tc_lwt.request GetEndpoints.f
let query_transaction_tree = Tc_lwt.request QueryTransactionTree.f
let create_block_iterator = Tc_lwt.request CreateBlockIterator.f
let resume_block_iterator = Tc_lwt.request ResumeBlockIterator.f
let create_transaction_iterator = Tc_lwt.request CreateTransactionIterator.f
let resume_transaction_iterator = Tc_lwt.request ResumeTransactionIterator.f
let iterator_next = Tc_lwt.request IteratorNext.f
let remove_iterator = Tc_lwt.request RemoveIterator.f
