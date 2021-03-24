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

open Ezcmd.V2
open EZCMD.TYPES
(* open Ez_subst.V1 *)
(* open EzFile.OP *)

type kind = Messages | Transactions

let action ~account ~kind:_ =
  match account with
  | None -> assert false
  | Some account ->
      let open Ton_sdk in
      let config = Config.config () in
      let address = Utils.address_of_account config account in
      let node = Config.current_node config in
      let client = CLIENT.create node.node_url in
      let blockid = BLOCK.find_last_shard_block ~client ~address in
      Printf.eprintf "blockid = %S\n%!" blockid ;
      let timeout = 300_000L in (* in ms *)
      let rec iter blockid =
        let b = BLOCK.wait_next_block
            ~client ~blockid ~address
            ~timeout () in
        Printf.eprintf "next = %s\n%!"
          (Ton_sdk.TYPES.string_of_block b) ;
        begin
          match
            Utils.post config
              (REQUEST.transactions
                 ~level:3
                 ~block_id:b.id
                 ~account_addr:address [])
          with
          | [] -> ()
          | trs ->
              List.iter (fun tr ->
                  Printf.eprintf "TRANSACTION: %s\n%!"
                    (ENCODING.string_of_transaction tr)
                ) trs
        end;

        (*
        let graphql_query =
          Printf.sprintf
          {|{ "query": "{ transactions
  (limit: 10,
   filter:
    { account_addr:
     { eq: \"%s\" },
      block_id:
      { eq: \"%s\" }
    }) {
    id
    aborted
    action { action_list_hash }
    bounce { bounce_type  bounce_type_name fwd_fees(format: DEC) msg_fees(format: DEC) msg_size_bits msg_size_cells req_fwd_fees(format: DEC) }
    compute { account_activated  compute_type compute_type_name exit_arg exit_code gas_credit gas_fees(format: DEC) gas_limit(format: DEC) gas_used(format: DEC) mode msg_state_used skipped_reason success vm_final_state_hash vm_init_state_hash vm_steps }
    credit { credit(format: DEC) due_fees_collected(format: DEC) }
    credit_first tr_type status block_id account_addr
    total_fees(format: DEC) balance_delta(format: DEC)
    in_message { id msg_type status block_id src dst value(format: DEC) }
  }
}
"
}
|}
          address
          b.id
        in
        begin
          match
            Lwt_main.run
          (EzRequest_lwt.ANY.post (URL
                              ( node.node_url // "graphql" )
                           )
          ~content:graphql_query
          ~content_type:"application/json"
          )
          with
            Ok s ->
              Printf.eprintf "result: %s\n%!" s
          | Error (code, msg) ->
              Printf.eprintf "query failed %d: %s\n%!"
                code
                (match msg with None -> "-" | Some msg -> msg)

        end;
*)
        iter b.id
      in
      iter blockid

let cmd =
  let account = ref None in
  let kind = ref Transactions in
  EZCMD.sub
    "watch"
    (fun () ->
       action
         ~account:!account
         ~kind:!kind
    )
    ~args:
      [

        [ "account" ], Arg.String (fun s -> account := Some s),
        EZCMD.info "ACCOUNT Output account of account";

        [ "messages" ], Arg.Unit (fun () -> kind := Messages),
        EZCMD.info "Monitor messages instead of transactions";
      ]
    ~doc: "Monitor a given account"
