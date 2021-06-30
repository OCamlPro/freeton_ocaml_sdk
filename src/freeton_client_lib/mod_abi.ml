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

open Ton_types

module EncodeMessageBody = struct

  type params = {
    abi: Abi.t ;
    call_set: CallSet.t ;
    is_internal: bool ;
    signer: Signer.t ;
    processing_try_index: int option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    body: string ;
    data_to_sign : string option ; [@opt None]
  }
  [@@deriving json_encoding]

  let f =
    Tc.request_sync "encode_message_body" ~params_enc ~result_enc

end

module EncodeMessage = struct
  type params = {
    abi: Abi.t ;
    address: string option ; [@opt None]
    deploy_set: DeploySet.t option ; [@opt None]
    call_set: CallSet.t option ; [@opt None]
    signer: Signer.t ;
    processing_try_index: int option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    message: string ;
    data_to_sign: string option ; [@opt None]
    address: string ;
    message_id: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.request_sync "encode_message" ~params_enc ~result_enc

end

(* TODO:
attach_signature_to_message_body

encode_internal_message – Encodes an internal ABI-compatible message

attach_signature – Combines hex-encoded signature with base64-encoded unsigned_message. Returns signed message encoded in base64.

decode_message – Decodes message body using provided message BOC and ABI.

decode_message_body – Decodes message body using provided body BOC and ABI.

encode_account – Creates account state BOC
*)

let encode_message_body = EncodeMessageBody.f
let encode_message = EncodeMessage.f
