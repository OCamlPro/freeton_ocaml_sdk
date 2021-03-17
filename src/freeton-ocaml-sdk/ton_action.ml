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

external deploy :
  string array ->
  keypair : Ton_types.keypair ->
  wc : int ->
  string Ton_types.reply (* address *) = "deploy_contract_ml"


let deploy ~server_url ~tvc_file ~abi ~params ~keypair
    ?(initial_data="") ?(initial_pubkey="") ?(wc=0) () =
  Ton_types.reply
    (
      deploy [| server_url ; tvc_file ; abi ; params ;
                initial_data; initial_pubkey |] ~keypair ~wc
    )

external call :
  string array ->
  keypair : Ton_types.keypair option ->
  local : bool ->
  string Ton_types.reply = "call_contract_ml"

let call ~server_url ~address ~abi ~meth ~params ?keypair ~boc
    ~local () =
  Ton_types.reply (
    call [| server_url ; address ; abi ; meth ; params ; boc |]
      ~keypair
      ~local
  )

let call ~server_url ~address ~abi ~meth ~params ?keypair ~local () =
  match
      Ton_request.post server_url
      (Ton_request.account ~level:2 address) Ton_encoding.accounts_enc
  with
  | [] -> Printf.kprintf failwith "Account %s does not exist" address
  | _ :: _ :: _ -> assert false
  | [ acc ] ->
      match acc.acc_boc with
      | None ->
          Printf.kprintf failwith "Account %s is not initialized" address
      | Some boc ->
          call ~server_url ~address ~abi ~meth ~params ?keypair ~boc
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
