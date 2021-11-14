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
  Sdk_types.client->
  string array ->
  keypair : Sdk_types.keypair ->
  wc : int ->
  string Sdk_types.reply (* address *) = "deploy_contract_ml"


let deploy ~client ~tvc_file ~abi ~params ~keypair
    ?(initial_data="") ?(initial_pubkey="") ?(wc=0) () =
  Sdk_types.reply
    (
      deploy_contract_ml client [| tvc_file ; abi ; params ;
                initial_data; initial_pubkey |] ~keypair ~wc
    )

external prepare_message_ml :
  Sdk_types.client ->
  string array ->
  keypair : Sdk_types.keypair option ->
  EncodedMessage.t Sdk_types.reply = "prepare_message_ml"

let prepare_message ~client ~address ~abi ~meth ~params ?keypair () =
  Sdk_types.reply (
    prepare_message_ml client [| address ; abi ; meth ; params |]
      ~keypair
  )

external call_contract_ml :
  Sdk_types.client ->
  string array ->
  keypair : Sdk_types.keypair option ->
  local : bool ->
  string Sdk_types.reply = "call_contract_ml"

let call_lwt ~client ~address ~abi ~meth ~params ?keypair ~boc
    ~local () =
  Sdk_types.reply_lwt (
    call_contract_ml client [| address ; abi ; meth ; params ; boc |]
      ~keypair
      ~local
  )

let call ~client ~address ~abi ~meth ~params ?keypair ~boc
    ~local () =
  Sdk_types.reply (
    call_contract_ml client [| address ; abi ; meth ; params ; boc |]
      ~keypair
      ~local
  )

external update_contract_state :
  string array -> unit Sdk_types.reply = "update_contract_state_ml"

let update_contract_state ~tvc_file ~pubkey ?(data="") ~abi () =
  Sdk_types.reply (
    update_contract_state [| tvc_file ; pubkey ; data ; abi |]
  )

external parse_message :
  string -> string Sdk_types.reply = "parse_message_ml"

let parse_message s = Sdk_types.reply ( parse_message s )




external call_contract_local_ml :
  Sdk_types.client ->
  string ->
  string ->
  string ->
  string Sdk_types.reply = "call_contract_local_ml"

let call_contract_local ~client ~abi ~msg ~boc =
  Sdk_types.reply ( call_contract_local_ml client abi msg boc )

module SendMessageResult = struct

  type t = {
    shard_block_id : string ;
    sending_endpoints : string array ;
  }
end

external send_message_ml :
  Sdk_types.client ->
  string ->
  string ->
  SendMessageResult.t Sdk_types.reply = "send_message_ml"

let send_message ~client ~abi ~msg =
  Sdk_types.reply ( send_message_ml client abi msg )

external wait_for_transaction_ml :
  Sdk_types.client ->
  string ->
  string ->
  SendMessageResult.t ->
  string Sdk_types.reply = "wait_for_transaction_ml"

let wait_for_transaction ~client ~abi ~msg send =
  Sdk_types.reply ( wait_for_transaction_ml client abi msg send )
