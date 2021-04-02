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

external deploy_contract_ml :
  Ton_types.client->
  string array ->
  keypair : Ton_types.keypair ->
  wc : int ->
  string Ton_types.reply (* address *) = "deploy_contract_ml"


let deploy ~client ~tvc_file ~abi ~params ~keypair
    ?(initial_data="") ?(initial_pubkey="") ?(wc=0) () =
  Ton_types.reply
    (
      deploy_contract_ml client [| tvc_file ; abi ; params ;
                initial_data; initial_pubkey |] ~keypair ~wc
    )

external call_contract_ml :
  Ton_types.client ->
  string array ->
  keypair : Ton_types.keypair option ->
  local : bool ->
  string Ton_types.reply = "call_contract_ml"

let call ~client ~address ~abi ~meth ~params ?keypair ~boc
    ~local () =
  Ton_types.reply (
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
      | [] -> Printf.kprintf failwith "Account %s does not exist" address
      | _ :: _ :: _ -> assert false
      | [ acc ] ->
          match acc.acc_boc with
          | None ->
              Printf.kprintf failwith "Account %s is not initialized" address
          | Some boc ->
              let client =
                match client with
                | Some client -> client
                | None -> Ton_client.create server_url
              in
              let v =
                call ~client ~address ~abi ~meth ~params ?keypair ~boc
                  ~local ()
              in
              Lwt.return v
    )

let call_run ?client ~server_url ~address ~abi ~meth ~params ?keypair ~local () =
  match
    Ton_request.post_run server_url
      (Ton_request.account ~level:2 address)
  with
  | [] -> Printf.kprintf failwith "Account %s does not exist" address
  | _ :: _ :: _ -> assert false
  | [ acc ] ->
      match acc.acc_boc with
      | None ->
          Printf.kprintf failwith "Account %s is not initialized" address
      | Some boc ->
          let client =
            match client with
            | Some client -> client
            | None -> Ton_client.create server_url
          in
          call ~client ~address ~abi ~meth ~params ?keypair ~boc
            ~local ()

external update_contract_state :
  string array -> unit Ton_types.reply = "update_contract_state_ml"

let update_contract_state ~tvc_file ~pubkey ?(data="") ~abi () =
  Ton_types.reply (
    update_contract_state [| tvc_file ; pubkey ; data ; abi |]
  )

external parse_message :
  string -> string Ton_types.reply = "parse_message_ml"

let parse_message s = Ton_types.reply ( parse_message s )
