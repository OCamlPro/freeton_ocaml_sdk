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

open EzAPI
open Graphql

let dev_base = TYPES.BASE "https://net.ton.dev"
let base = TYPES.BASE "https://main.ton.dev"

let service
  ?section ?name ?descr ?error_outputs ?params ?security ?register ?input_example ?output_example
  (output: 'a Json_encoding.encoding) : (query, 'a, 'error, 'security) post_service0 =
  post_service
    ?section ?name ?descr ?error_outputs ?params ?security ?register ?input_example ?output_example
    ~input:request_encoding
    ~output:Json_encoding.(obj1 (req "data" output))
    Path.(root // "graphql")


let debug_graphql = match Sys.getenv "FT_DEBUG_GRAPHQL" with
  | exception _ -> false
  | _ -> true

let post url input output =
  let url = EzAPI.TYPES.BASE url in
  let open Lwt.Infix in
  let request () =
    if debug_graphql then begin
      Printf.eprintf "Graphql query (input): %s\n%!"
        (Graphql.string_of_query input);
    end;
    EzCohttp_lwt.post0
      url (service output)
      ~input >|= function
    | Error e ->
        failwith
          (EzRequest_lwt.string_of_error
             (fun exn -> Some (Printexc.to_string exn)) e);
    | Ok v ->
        if debug_graphql then
          Printf.eprintf "Server replied: %s\n%!"
            (EzEncoding.construct ~compact:false output v);
        v
  in
  Lwt_main.run (request ())



let aeq name value = [ name, aobj [ "eq", value ] ]
let alimit n = [ "limit", aint n ]
let aorder ?(direction="DESC") name =
  [ "orderBy", aobj [ "path", `string name; "direction", `raw direction ] ]
let afilter l = [ "filter", aobj l ]
let alist ?limit ?order ?filter args =
  let args = match filter with None -> args | Some l -> afilter l @ args in
  let args = match order with None -> args | Some (name, direction) -> aorder ?direction name @ args in
  match limit with None -> args | Some n -> alimit n @ args

let version = fields "info" [ scalar "version"; scalar "time" ]

let account_info1 = [
  scalar "id";
  scalar "acc_type";
  scalar "acc_type_name";
  scalar ~args:["format", araw "DEC"] "balance";
]

let account_info2 =
  account_info1 @ [
  (* balance_other: [OtherCurrency] *)
  scalar "boc";
  scalar "code";
  scalar "code_hash";
  scalar "data" ;
  scalar "data_hash" ;
]

let account_info3 =
  account_info2 @ [
  (*  due_payment(format: BigIntFormat): String *)
  scalar "last_paid" ;
  (* last_trans_lt(format: BigIntFormat): String *)
  scalar "library" ;
  scalar "library_hash" ;
  scalar "proof" ;
  scalar "split_depth" ;
  scalar "state_hash" ;
  scalar "tick" ;
  scalar "tock" ;
  scalar "workchain_id" ;
]

let accounts ?(level=1) ?limit ?order ?filter args =
  let args = alist ?limit ?order ?filter args in
  fields ~args "accounts" (match level with
      | 0 | 1 -> account_info1
      | 2 -> account_info2
      | _ -> account_info3 )

let account ?level id =
  accounts ?level ~filter:(aeq "id" (astring id)) []

let ext_blk_ref = [
  scalar ~args:["format", araw "DEC"] "end_lt";
  scalar "seq_no";
  scalar "root_hash";
  scalar "file_hash" ]

let block_value_flow = [
  scalar ~args:["format", araw "DEC"] "to_next_blk";
  scalar ~args:["format", araw "DEC"] "fees_collected";
  scalar ~args:["format", araw "DEC"] "minted";
]

let block_info = [
  scalar "id";
  scalar "status";
  scalar "workchain_id";
  scalar "shard";
  scalar "seq_no";
  fields "prev_ref" ext_blk_ref;
  scalar "gen_utime";
  scalar "created_by";
  scalar "tr_count";
  scalar "key_block";
  fields "value_flow" block_value_flow;
]

let blocks ?limit ?order ?filter args =
  let args = alist ?limit ?order ?filter args in
  fields ~args "blocks" block_info

let block (id : [< `int of int | `string of string ]) =
  let filter = match id with `string s -> aeq "id" (astring s) | `int i -> aeq "seq_no" (aint i) in
  blocks ~filter []

let head () = blocks ~limit:1 ~order:("seq_no", None) []

let message_info = [
  scalar "id";
  scalar "msg_type";
  scalar "status";
  scalar "block_id";
  scalar "src";
  scalar "dst";
  scalar ~args:["format", araw "DEC"] "value"
]

let messages ?limit ?order ?filter args =
  let args = alist ?limit ?order ?filter args in
  fields ~args "messages" message_info

let transaction_info = [
  scalar "id";
  scalar "tr_type";
  scalar "status";
  scalar "block_id";
  scalar "account_addr";
  scalar ~args:["format", araw "DEC"] "total_fees";
  scalar ~args:["format", araw "DEC"] "balance_delta";
  fields "in_message" message_info;
]

let transactions ?limit ?order ?filter args =
  let args = alist ?limit ?order ?filter args in
  fields ~args "transactions" transaction_info

let transaction id =
  transactions ~filter:(aeq "id" (astring id)) []

let block_transactions id =
  transactions ~filter:(aeq "block_id" (astring id)) []

let account_transactions id =
  transactions ~filter:(aeq "account_addr" (astring id)) []
