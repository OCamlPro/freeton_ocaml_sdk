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

include Ton_client.ABI

let encode_message_body = Tc_lwt.request EncodeMessageBody.f
let attach_signature_to_message_body =
  Tc_lwt.request AttachSignatureToMessageBody.f
let encode_message = Tc_lwt.request EncodeMessage.f
let encode_internal_message = Tc_lwt.request EncodeInternalMessage.f
let attach_signature =
  Tc_lwt.request AttachSignature.f
let decode_message = Tc_lwt.request DecodeMessage.f
let decode_message_body = Tc_lwt.request DecodeMessageBody.f
let encode_account = Tc_lwt.request EncodeAccount.f
