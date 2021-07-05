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

module TYPES = Freeton_types

module CLIENT = Freeton_client

module CRYPTO = Ton_crypto
module RPC = Ton_rpc

module BLOCK = Ton_block
module REQUEST = Ton_request
module ENCODING = Ton_encoding

module ACTION = Ton_action
module ABI = Ton_abi

module TVC = Ton_tvc

module SDK : sig

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
      key_pair : TYPES.keypair option ;
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
end = struct


  module Message = struct

    type t = {
      id : string ; (* hex-encoded string *)
      serialized_message : string ; (* base64-encoded string *)
      address : string ;
    }

  end

  module EncodeFunctionCall = struct

    type t = {
      abi : string ;
      meth : string ;
      header : string option ;
      parameters : string ;
      internal : bool ;
      key_pair : TYPES.keypair option ;
    }

    (*    external encode_function_call : t ->  *)

  end

  module EncodeInternalMessage = struct

    type t = {
      address : string ;
      src_address : string option ;
      ihr_disabled : bool ;
      bounce : bool ;
      value : int64 ;
      call : EncodeFunctionCall.t option ;
      payload : string option ;
    }

    external rs : t -> Message.t Freeton_types.reply = "encode_internal_message_ml"

  end

  let encode_internal_message
      ~address
        ?src_address
        ?(ihr_disabled = false)
        ?(bounce = true)
        ?(value = 10_000_000L)
        ?payload
        ?call
        () =
      Freeton_types.reply @@
      EncodeInternalMessage.rs
        EncodeInternalMessage.{ address ; src_address ; ihr_disabled ;
          bounce ; value ; payload ; call
        }

end

module Ton_client = Ton_client
module Ton_client_lwt = struct

  module ABI = Mod_abi_lwt
  module BOC = Mod_boc_lwt
  module CLIENT = Mod_client_lwt
  module CRYPTO = Mod_crypto_lwt
  module DEBOT = Mod_debot_lwt
  module NET = Mod_net_lwt
  module PROCESSING = Mod_processing_lwt
  module TVM = Mod_tvm_lwt
  module UTILS = Mod_utils_lwt
end
