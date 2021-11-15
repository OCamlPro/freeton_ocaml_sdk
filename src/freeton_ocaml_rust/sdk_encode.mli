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

module Message : sig

  type t = {
    id : string ; (* hex-encoded string *)
    serialized_message : string ; (* base64-encoded string *)
    address : string ;
  }

end

module EncodeFunctionCall : sig

  type t = {
    abi : string ;
    meth : string ;
    header : string option ;
    parameters : string ;
    internal : bool ;
    key_pair : Sdk_types.keypair option ;
  }

  (*    external encode_function_call : t ->  *)

end

val encode_internal_message :
  address:string ->
  ?src_address:string ->
  ?ihr_disabled:bool ->
  ?bounce:bool ->
  ?value:int64 ->
  ?payload:string -> ?call:EncodeFunctionCall.t -> unit -> Message.t
