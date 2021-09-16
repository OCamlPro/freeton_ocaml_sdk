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

(* open EzAPI *)
open Graphql

let dev_base = EzAPI.TYPES.BASE "https://net.ton.dev"
let base = EzAPI.TYPES.BASE "https://main.ton.dev"

let service
    ?section ?name ?descr ?errors ?params ?security ?register
    ?input_example ?output_example
    (output: 'a Json_encoding.encoding) :
  (query, 'a, 'error, 'security) EzAPI.post_service0 =
  EzAPI.post_service
    ?section ?name ?descr ?errors ?params ?security ?register
    ?input_example ?output_example
    ~input:request_encoding
    ~output:Json_encoding.(obj1 (req "data" output))
    EzAPI.Path.(root // "graphql")


let debug_graphql = match Sys.getenv "FT_DEBUG_GRAPHQL" with
  | exception _ -> false
  | _ -> true

type 'a t = {
  input : query ;
  output : 'a Json_encoding.encoding ;
}

let post_lwt url ( req : 'a t ) =
  let url = EzAPI.TYPES.BASE url in
  let open Lwt.Infix in
  let request () =
    if debug_graphql then begin
      Printf.eprintf "Graphql query (input): %s\n%!"
        (Graphql.string_of_query req.input);
    end;
    EzCohttp_lwt.post0
      url (service req.output)
      ~input:req.input >|= function res ->
    match res with
    | Error e ->
        let s =
          EzRequest_lwt.string_of_error
            (fun exn -> Some (Printexc.to_string exn)) e
        in
        if debug_graphql then
          Printf.eprintf "Graphql error: %s\n%!" s;

        Error (Failure s)
    | Ok v ->
        if debug_graphql then
          Printf.eprintf "Server replied: %s\n%!"
            (EzEncoding.construct ~compact:false req.output v);
        Ok v
  in
  request ()

let post_run url req =
  Lwt_main.run (post_lwt url req)

let astring = astring
let aint = aint
let aeq name value = [ name, aobj [ "eq", value ] ]
let acomp name ~comp value = [ name, aobj [ comp, value ] ]
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
  scalar "last_trans_lt";
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
  scalar "end_lt";
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
  scalar "tr_count";
  scalar "workchain_id";
  scalar "shard";
  scalar "start_lt";
]

let block_info2 =
  block_info1 @ [

    fields "in_msg_descr" [
      scalar "msg_id" ;
      scalar "msg_type_name" ;
      scalar "transaction_id" ];
    fields "out_msg_descr"
      [ scalar "msg_id" ;
        scalar "msg_type_name" ;
        scalar "transaction_id" ];

  ]

let block_info3 =
  block_info2 @ [

    fields "prev_ref" ext_blk_ref;
    scalar "created_by";
    scalar "key_block";
    fields "value_flow" block_value_flow;

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

let block ?level ?(filter=[]) (id : [< `int of int | `string of string ]) =
  let filter =
    filter @
    match id with `string s -> aeq "id" (astring s) | `int i -> aeq "seq_no" (aint i) in
  blocks ?level ~filter []

let head ?filter ?level () =
  blocks ?level ?filter ~limit:1 ~order:("seq_no", None) []















let message_info1 = [
  scalar "id";
  (*  scalar "msg_type"; *)
  scalar "msg_type_name";
  (* scalar "status"; *)
  scalar "status_name";
  scalar "block_id";
  scalar "src";
  scalar "dst";
  scalar ~args:["format", araw "DEC"] "value";
  scalar "bounce";
]

let message_info2 =
  message_info1 @
  [
    scalar "boc";
    scalar "body";
    scalar "bounced";
    scalar ~args:["format", araw "DEC"] "fwd_fee";
    scalar ~args:["format", araw "DEC"] "ihr_fee";
    scalar ~args:["format", araw "DEC"] "import_fee";
  ]

let message_info3 =
  message_info2 @
  [
    scalar "body_hash";
    scalar "code";
    scalar "code_hash";
    scalar "created_at";
    scalar "created_at_string";
    scalar "created_lt";
    scalar "data";
    scalar "data_hash";
    scalar "ihr_disabled";
    scalar "dst_workchain_id";
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
  (* scalar "tr_type"; *)
  scalar "tr_type_name";
  (* scalar "status"; *)
  scalar "status_name";
  scalar "block_id";
  scalar ~args:["format", araw "DEC"] "total_fees";
  scalar ~args:["format", araw "DEC"] "balance_delta";
  (*  fields "in_message" message_info; *)
  scalar "in_msg";
  scalar "out_msgs";
  scalar "lt";
  scalar "now";
]

let transaction_info2 =
  transaction_info1 @ [
    scalar "boc" ;
    scalar "destroyed";
    (* scalar "end_status"; *)
    scalar "end_status_name";
    scalar "installed";
    scalar "new_hash";
    scalar "old_hash";
    (* scalar "orig_status"; *)
    scalar "orig_status_name";
    (* scalar "outmsg_cnt"; *)
    scalar "prepare_transaction";
    scalar "prev_trans_hash";
    scalar "prev_trans_lt";
    scalar "proof";
    scalar "tt";
  ]

let transaction_info3 =
  transaction_info2 @ [

    fields "action" [
      scalar "action_list_hash" ;
      scalar "msgs_created" ;
      scalar "no_funds" ;
      scalar "result_arg" ;
      scalar "result_code" ;
      scalar "skipped_actions" ;
      scalar "spec_actions" ;
      (* scalar "status_change" ; *)
      scalar "status_change_name" ;
      scalar "success" ;
      scalar "tot_actions" ;
      scalar ~args:["format", araw "DEC"] "total_action_fees" ;
      scalar ~args:["format", araw "DEC"]"total_fwd_fees" ;
      scalar "total_msg_size_bits" ;
      scalar "total_msg_size_cells" ;
      scalar "valid" ;

    ];
    fields "bounce" [
      (* scalar "bounce_type" ; *)
      scalar "bounce_type_name" ;
      scalar ~args:["format", araw "DEC"] "fwd_fees" ;
      scalar ~args:["format", araw "DEC"] "msg_fees" ;
      scalar "msg_size_bits" ;
      scalar "msg_size_cells" ;
      scalar ~args:["format", araw "DEC"] "req_fwd_fees" ;
    ];
    fields "compute" [
      scalar "account_activated" ;
      (* scalar "compute_type" ; *)
      scalar "compute_type_name" ;
      scalar "exit_arg" ;
      scalar "exit_code" ;
      scalar "gas_credit" ;
      scalar ~args:["format", araw "DEC"] "gas_fees" ;
      scalar ~args:["format", araw "DEC"] "gas_limit" ;
      scalar ~args:["format", araw "DEC"] "gas_used" ;
      scalar "mode" ;
      scalar "msg_state_used" ;
      (*      scalar "skipped_reason" ; *)
      scalar "skipped_reason_name" ;
      scalar "success" ;
      scalar "vm_final_state_hash" ;
      scalar "vm_init_state_hash" ;
      scalar "vm_steps" ;
    ];
    fields "credit" [
      scalar ~args:["format", araw "DEC"] "credit";
      scalar ~args:["format", araw "DEC"] "due_fees_collected";
    ];
    scalar "credit_first";
    fields "storage" [
      (*      scalar "status_change" ; *)
      scalar "status_change_name" ;
      scalar ~args:["format", araw "DEC"] "storage_fees_collected";
      scalar ~args:["format", araw "DEC"] "storage_fees_due";
    ];
  ]



let transaction_info ~level =
  match level with
  | 0|1 -> transaction_info1
  | 2 -> transaction_info2
  | _ -> transaction_info3


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

let (let>) p f = Lwt.bind p f

let head_time ~url =
  let> head = post_lwt url (head ~level:1 ()) in
  match head with
  | Ok [] -> Lwt.return "0" (* No head *)
  | Ok [{bl_start_lt = None; _}] -> assert false (* Head with no time *)
  | Ok [{bl_start_lt = Some time; _}] -> Lwt.return time
  | Ok _ -> assert false (* Multiple heads *)
  | Error exn ->
      Printf.eprintf "Failed to load head: %s\n%!"
        (Printexc.to_string exn);
      exit 2

let iter_past_transactions ~address ~url
    ?known_transactions ?last_trans_lt ?(level=1) ?(limit=max_int) f =

  let known_transactions = match known_transactions with
    | None -> Hashtbl.create 1111
    | Some h -> h
  in

  let> last_trans_lt = match last_trans_lt with
    | Some last_trans_lt -> Lwt.return last_trans_lt
    | None ->
        let> result = post_lwt url
            (account ~level:1 address) in
        match result with
        | Ok [ { acc_last_trans_lt = Some last_trans_lt ;  _} ] ->
            Lwt.return last_trans_lt
        | Ok [ { acc_last_trans_lt = None ;  _} ] ->
            (* No last transaction, checking from the head *)
            head_time ~url
        | Ok [] ->
            Printf.eprintf "No contract event_address\n%!";
            exit 2
        | Ok _ -> assert false (* Multiple 'last transaction' *)
        | Error exn ->
            Printf.eprintf "Failed to load event_address last_trans_lt: %s\n%!"
              (Printexc.to_string exn);
            exit 2
  in

  let rec iter_new_transactions trs =
    match trs with
    | [] -> Lwt.return_unit
    | tr :: rem_trs ->
        let> () =
          if Hashtbl.mem known_transactions tr.Ton_encoding.tr_id then
            Lwt.return_unit
          else begin
            Printf.eprintf "Adding former transaction %s\n%!" tr.tr_id;
            f tr
          end
        in
        iter_new_transactions rem_trs
  in

  let rec paginate_transactions limit next last_trans_lt =
    let req_limit = min limit 3 in
    let> result = post_lwt url
        (transactions ~level
           ~account_addr:address
           ~limit:req_limit
           ~order:("lt", None)
           ~filter:( acomp "lt" ~comp:"lt"
                       ( astring last_trans_lt))
           [])
    in
    match result with
    | Ok [] -> iter_new_transactions next
    | Ok trs ->
        let trs = List.rev trs in
        (*
        List.iteri (fun i tr ->
            Printf.eprintf "%d -> %Ld\n%!" i
              (match tr.Ton_encoding.tr_lt with
               | None -> assert false
               | Some lt -> Int64.of_string lt );
          ) trs ;
*)
        paginate_transactions2 limit trs next
    | Error exn ->
        Printf.eprintf "failed to load new transactions %s\n%!"
          (Printexc.to_string exn);
        exit 2

  and paginate_transactions2 limit trs next =
    match trs with
    | { tr_id ; tr_lt = Some lt ; _ } :: rem_trs  ->
        if Hashtbl.mem known_transactions tr_id then
          paginate_transactions2 0 rem_trs next
        else
          let limit = limit - List.length trs in
          let next = trs @ next in
          if limit > 0 then
            paginate_transactions limit next lt
          else
            iter_new_transactions next
    | [] -> iter_new_transactions next
    | _ -> assert false
  in
  let> () = paginate_transactions limit [] last_trans_lt in
  Lwt.return_unit
