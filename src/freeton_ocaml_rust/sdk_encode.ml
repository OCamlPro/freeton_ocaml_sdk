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
    key_pair : Sdk_types.keypair option ;
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

  external rs : t -> Message.t Sdk_types.reply = "encode_internal_message_ml"

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
  Sdk_types.reply @@
  EncodeInternalMessage.rs
    EncodeInternalMessage.{ address ; src_address ; ihr_disabled ;
                            bounce ; value ; payload ; call
                          }
