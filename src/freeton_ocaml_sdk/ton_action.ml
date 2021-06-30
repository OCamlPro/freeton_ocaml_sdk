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

(* see EncodedMessage in types.rs *)

module EncodedMessage = struct

  type t = {
    message_id : string ;
    message : string ;
    expire : int64 option ;
  }

end

external deploy_contract_ml :
  Freeton_types.client->
  string array ->
  keypair : Freeton_types.keypair ->
  wc : int ->
  string Freeton_types.reply (* address *) = "deploy_contract_ml"


let deploy ~client ~tvc_file ~abi ~params ~keypair
    ?(initial_data="") ?(initial_pubkey="") ?(wc=0) () =
  Freeton_types.reply
    (
      deploy_contract_ml client [| tvc_file ; abi ; params ;
                initial_data; initial_pubkey |] ~keypair ~wc
    )

external prepare_message_ml :
  Freeton_types.client ->
  string array ->
  keypair : Freeton_types.keypair option ->
  EncodedMessage.t Freeton_types.reply = "prepare_message_ml"

let prepare_message ~client ~address ~abi ~meth ~params ?keypair () =
  Freeton_types.reply (
    prepare_message_ml client [| address ; abi ; meth ; params |]
      ~keypair
  )

external call_contract_ml :
  Freeton_types.client ->
  string array ->
  keypair : Freeton_types.keypair option ->
  local : bool ->
  string Freeton_types.reply = "call_contract_ml"

let call_lwt ~client ~address ~abi ~meth ~params ?keypair ~boc
    ~local () =
  Freeton_types.reply_lwt (
    call_contract_ml client [| address ; abi ; meth ; params ; boc |]
      ~keypair
      ~local
  )

let call_lwt
    ?client ~server_url ~address ~abi ~meth ~params ?keypair ~local () =
  Lwt.bind
    (Ton_request.post_lwt server_url
       (Ton_request.account ~level:2 address) )
    (function
      | Error err -> Lwt.return (Error err)
      | Ok [] ->
          Lwt.return
            (Error
               (Failure
                  (Printf.sprintf "Account %s does not exist" address)))
      | Ok (_ :: _ :: _) -> assert false
      | Ok [ acc ] ->
          match acc.acc_boc with
          | None ->
              Lwt.return
                (Error
                   (Failure
                      (Printf.sprintf "Account %s is not initialized" address)))
          | Some boc ->
              let client =
                match client with
                | Some client -> client
                | None -> Freeton_client.create server_url
              in
              call_lwt ~client ~address ~abi ~meth ~params ?keypair ~boc
                ~local ()
    )

let call ~client ~address ~abi ~meth ~params ?keypair ~boc
    ~local () =
  Freeton_types.reply (
    call_contract_ml client [| address ; abi ; meth ; params ; boc |]
      ~keypair
      ~local
  )

let call_run ?client ~server_url ~address ~abi ~meth ~params ?keypair ~local () =
  match
    Ton_request.post_run server_url
      (Ton_request.account ~level:2 address)
  with
  | Error exn -> raise exn
  | Ok [] -> Printf.kprintf failwith "Account %s does not exist" address
  | Ok ( _ :: _ :: _ ) -> assert false
  | Ok [ acc ] ->
      match acc.acc_boc with
      | None ->
          Printf.kprintf failwith "Account %s is not initialized" address
      | Some boc ->
          let client =
            match client with
            | Some client -> client
            | None -> Freeton_client.create server_url
          in
          call ~client ~address ~abi ~meth ~params ?keypair ~boc
            ~local ()

external update_contract_state :
  string array -> unit Freeton_types.reply = "update_contract_state_ml"

let update_contract_state ~tvc_file ~pubkey ?(data="") ~abi () =
  Freeton_types.reply (
    update_contract_state [| tvc_file ; pubkey ; data ; abi |]
  )

external parse_message :
  string -> string Freeton_types.reply = "parse_message_ml"

let parse_message s = Freeton_types.reply ( parse_message s )




external call_contract_local_ml :
  Freeton_types.client ->
  string ->
  string ->
  string ->
  string Freeton_types.reply = "call_contract_local_ml"

let call_contract_local ~client ~abi ~msg ~boc =
  Freeton_types.reply ( call_contract_local_ml client abi msg boc )

module SendMessageResult = struct

  type t = {
    shard_block_id : string ;
    sending_endpoints : string array ;
  }
end

external send_message_ml :
  Freeton_types.client ->
  string ->
  string ->
  SendMessageResult.t Freeton_types.reply = "send_message_ml"

let send_message ~client ~abi ~msg =
  Freeton_types.reply ( send_message_ml client abi msg )

external wait_for_transaction_ml :
  Freeton_types.client ->
  string ->
  string ->
  SendMessageResult.t ->
  string Freeton_types.reply = "wait_for_transaction_ml"

let wait_for_transaction ~client ~abi ~msg send =
  Freeton_types.reply ( wait_for_transaction_ml client abi msg send )
