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

val read : string -> Sdk_types.state_init

(* returns "None" or base64 encoding of data *)
val data : Sdk_types.state_init -> string

(* returns hex encoding of data hash *)
val data_hash : Sdk_types.state_init -> string

(* returns depth of data cell *)
val data_depth : Sdk_types.state_init -> int64

(* returns "None" or base64 encoding of code *)
val code : Sdk_types.state_init -> string

(* returns hex encoding of code hash *)
val code_hash : Sdk_types.state_init -> string

(* returns depth of code cell *)
val code_depth : Sdk_types.state_init -> int64
