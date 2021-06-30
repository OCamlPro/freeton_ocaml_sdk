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
  } [@@deriving json_encoding]

  type result = {
    body: string ;
    data_to_sign : string option ; [@opt None]
  } [@@deriving json_encoding]

  let f =
    Tc.request_sync "encode_message_body"
      ~params_enc ~result_enc

end

let encode_message_body = EncodeMessageBody.f
