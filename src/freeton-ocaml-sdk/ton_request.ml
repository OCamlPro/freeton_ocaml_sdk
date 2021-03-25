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

type 'a t = {
  input : query ;
  output : 'a Json_encoding.encoding ;
}

let post url ( req : 'a t ) =
  let url = EzAPI.TYPES.BASE url in
  let open Lwt.Infix in
  let request () =
    if debug_graphql then begin
      Printf.eprintf "Graphql query (input): %s\n%!"
        (Graphql.string_of_query req.input);
    end;
    EzCohttp_lwt.post0
      url (service req.output)
      ~input:req.input >|= function
    | Error e ->
        failwith
          (EzRequest_lwt.string_of_error
             (fun exn -> Some (Printexc.to_string exn)) e);
    | Ok v ->
        if debug_graphql then
          Printf.eprintf "Server replied: %s\n%!"
            (EzEncoding.construct ~compact:false req.output v);
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
  (*  scalar "acc_type"; *)
  scalar "acc_type_name";
  scalar ~args:["format", araw "DEC"] "balance";
  scalar "code_hash";
]

let account_info2 =
  account_info1 @ [
  (* balance_other: [OtherCurrency] *)
  scalar "boc";
  scalar "code";
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

let account_info ~level =
  match level with
  | 0 | 1 -> account_info1
  | 2 -> account_info2
  | _ -> account_info3

let accounts ?(level=1) ?limit ?order ?filter args =
  let input =
    let args = alist ?limit ?order ?filter args in
    fields ~args "accounts" (account_info ~level)
  in
  let output = Ton_encoding.accounts_enc in
  { input ; output }

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

let block_info1 = [
  scalar "id";
  scalar "status_name";
  scalar "seq_no";
  scalar "gen_utime";
  fields "in_msg_descr" [
    scalar "msg_id" ;
    scalar "msg_type_name" ;
    scalar "transaction_id" ];
  fields "out_msg_descr"
    [ scalar "msg_id" ;
      scalar "msg_type_name" ;
      scalar "transaction_id" ];
]

let block_info2 =
  block_info1 @ [

    scalar "workchain_id";
    scalar "shard";
    fields "prev_ref" ext_blk_ref;
    scalar "created_by";
    scalar "tr_count";
    scalar "key_block";
    fields "value_flow" block_value_flow;

  ]

let block_info3 =
  block_info2 @ [

  ]


let block_info ~level =
  match level with
  | 0 | 1 -> block_info1
  | 2 -> block_info2
  | _ -> block_info3

let blocks ?(level=1) ?limit ?order ?filter args =
  let args = alist ?limit ?order ?filter args in
  let input = fields ~args "blocks" (block_info ~level) in
  let output = Ton_encoding.blocks_enc in
  { input ; output }

let block ?level (id : [< `int of int | `string of string ]) =
  let filter = match id with `string s -> aeq "id" (astring s) | `int i -> aeq "seq_no" (aint i) in
  blocks ?level ~filter []

let head ?level () = blocks ?level ~limit:1 ~order:("seq_no", None) []















let message_info1 = [
  scalar "id";
  scalar "msg_type";
  scalar "msg_type_name";
  scalar "status";
  scalar "status_name";
  scalar "block_id";
  scalar "src";
  scalar "dst";
  scalar ~args:["format", araw "DEC"] "value"
]

let message_info2 =
  message_info1 @
  [
    scalar "boc";
    scalar "body";
    scalar "body_hash";
    scalar "bounce";
    scalar "bounced";
    scalar "code";
    scalar "code_hash";
    scalar "created_at";
    scalar "created_at_string";
    scalar "created_lt";
    scalar "data";
    scalar "data_hash";
    scalar "dst_workchain_id";
    scalar ~args:["format", araw "DEC"] "fwd_fee";
    scalar "ihr_disabled";
    scalar ~args:["format", araw "DEC"] "ihr_fee";
    scalar ~args:["format", araw "DEC"] "import_fee";
    scalar "library";
    scalar "library_hash";
    scalar "proof";
    scalar "split_depth";
    scalar "src_workchain_id";
    scalar "tick";
    scalar "tock";
    fields "src_transaction" [ scalar "id" ];
    fields "dst_transaction" [ scalar "id" ];
  ]

let message_info3 =
  message_info2 @
  [

  ]



let message_info ~level =
  match level with
  | 0 | 1 -> message_info1
  | 2 -> message_info2
  | _ -> message_info3

let messages ?(level=1) ?id ?limit ?order ?(filter=[]) args =
  let input =
    let filter =
      (match id with
       | None -> []
       | Some id -> aeq "id" (astring id)
      ) @ filter
    in
    let args = alist ?limit ?order ~filter args in
    ignore (level);
    fields ~args "messages" (message_info ~level)
  in
  let output = Ton_encoding.messages_enc in
  { input ; output }





















let transaction_info1 = [
  scalar "id";
  scalar "aborted";
  scalar "account_addr";
  scalar "tr_type";
  scalar "tr_type_name";
  scalar "status";
  scalar "status_name";
  scalar "block_id";
  scalar ~args:["format", araw "DEC"] "total_fees";
  scalar ~args:["format", araw "DEC"] "balance_delta";
  (*  fields "in_message" message_info; *)
  scalar "in_msg";
  scalar "out_msgs";
]

let transaction_info2 =
  transaction_info1 @ [
    scalar "boc" ;
    scalar "destroyed";
    scalar "end_status";
    scalar "end_status_name";
    scalar "installed";
    scalar "lt";
    scalar "new_hash";
    scalar "now";
    scalar "old_hash";
    scalar "orig_status";
    scalar "orig_status_name";
    scalar "outmsg_cnt";
    scalar "prepare_transaction";
    scalar "prev_trans_hash";
    scalar "prev_trans_lt";
    scalar "proof";
    scalar "tt";
  ]

let transaction_info ~level =
  match level with
  | 0|1 -> transaction_info1
  | _ -> transaction_info2


let transactions ?(level=1) ?limit ?order ?filter args =
  let input =
    let args = alist ?limit ?order ?filter args in
    fields ~args "transactions" ( transaction_info ~level )
  in
  let output = Ton_encoding.transactions_enc in
  { input ; output }

let transaction ?level id =
  transactions ?level ~filter:(aeq "id" (astring id)) []

let transactions ?level ?block_id ?account_addr ?limit ?order ?(filter=[]) args =
  let filter =
    (match block_id with
     | None -> []
     | Some id -> aeq "block_id" (astring id)
    )
    @
    (match account_addr with
     | None -> []
     | Some id -> aeq "account_addr" (astring id)
    )
    @
    filter
  in
  let filter = match filter with
      [] -> None
    | filter -> Some filter
  in
  transactions ?level ?filter ?limit ?order args




(*

EXAMPLE:

{ transactions
  (limit: 10,
   filter:
    { account_addr:
     { eq: "0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94" },
      block_id:
      { eq: "c51b78e4be021caaa552ffea848e6958c446f870f0a698e324916f474383ea76" }
    }) {
    id tr_type status block_id account_addr
    total_fees(format: DEC) balance_delta(format: DEC)
    in_message { id msg_type status block_id src dst value(format: DEC) } }
}


*)
