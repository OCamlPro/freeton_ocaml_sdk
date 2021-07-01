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

module EncodedMessage : sig

  type t = {
    message_id : string ;
    message : string ;
    expire : int64 option ;
  }

end

val deploy :
  client:Freeton_types.client ->
  tvc_file:string ->
  abi:string ->
  params:string ->
  keypair:Freeton_types.keypair ->
  ?initial_data:string ->
  ?initial_pubkey:string -> ?wc:int -> unit -> string

val call_lwt :
  ?client:Freeton_types.client ->
  server_url:string ->
  address:string ->
  abi:string ->
  meth:string ->
  params:string ->
  ?keypair:Freeton_types.keypair -> local:bool -> unit ->
  ( string, exn ) result Lwt.t

val call_run :
  ?client:Freeton_types.client ->
  server_url:string ->
  address:string ->
  abi:string ->
  meth:string ->
  params:string ->
  ?keypair:Freeton_types.keypair -> local:bool -> unit -> string

(* Modify a TVC file *)
val update_contract_state :
  tvc_file:string ->
  pubkey:string -> (* in hex format *)
  ?data:string -> (* initial_data in JSON format ? *)
  abi:string -> (* abi in JSON format *)
  unit ->
  unit

val parse_message : string -> string

val prepare_message :
  client:Freeton_types.client ->
  address:string ->
  abi:string ->
  meth:string ->
  params:string ->
  ?keypair:Freeton_types.keypair ->
  unit -> EncodedMessage.t

(* we should also lift 'send_message' and 'wait_for_transaction' to be
   able to completely debug a call *)

val call_contract_local :
  client:Freeton_types.client ->
  abi:string -> msg:string -> boc:string -> string


module SendMessageResult : sig

  type t = {
    shard_block_id : string ;
    sending_endpoints : string array ;
  }
end

val send_message :
  client:Freeton_types.client ->
  abi:string ->
  msg:string -> (* base64 of message *)
  SendMessageResult.t

val wait_for_transaction :
  client:Freeton_types.client ->
  abi:string -> msg:string -> SendMessageResult.t -> string
