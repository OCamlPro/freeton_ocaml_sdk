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

external encode_body_ml :
  string array ->
  string Sdk_types.reply = "encode_body_ml"


let encode_body ~abi ~meth ~params =
  Sdk_types.reply
    (
      encode_body_ml [| abi ; meth ; params |]
    )
