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

val deploy :
  client:Ton_types.client ->
  tvc_file:string ->
  abi:string ->
  params:string ->
  keypair:Ton_types.keypair ->
  ?initial_data:string ->
  ?initial_pubkey:string -> ?wc:int -> unit -> string

val call :
  ?client:Ton_types.client ->
  server_url:string ->
  address:string ->
  abi:string ->
  meth:string ->
  params:string ->
  ?keypair:Ton_types.keypair -> local:bool -> unit -> string

(* Modify a TVC file *)
val update_contract_state :
  tvc_file:string ->
  pubkey:string -> (* in hex format *)
  ?data:string -> (* initial_data in JSON format ? *)
  abi:string -> (* abi in JSON format *)
  unit ->
  unit

val parse_message : string -> string
