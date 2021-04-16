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

val read : string -> Ton_types.ABI.contract
val write : string -> Ton_types.ABI.contract -> unit

(* not yet ready: *)
val encode_body :
  abi:string -> meth:string -> params:string -> string
