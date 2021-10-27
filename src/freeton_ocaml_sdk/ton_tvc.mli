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

val read : string -> Freeton_types.state_init

(* returns "None" or base64 encoding of data *)
val data : Freeton_types.state_init -> string

(* returns hex encoding of data hash *)
val data_hash : Freeton_types.state_init -> string

(* returns depth of data cell *)
val data_depth : Freeton_types.state_init -> int64

(* returns "None" or base64 encoding of code *)
val code : Freeton_types.state_init -> string

(* returns hex encoding of code hash *)
val code_hash : Freeton_types.state_init -> string

(* returns depth of code cell *)
val code_depth : Freeton_types.state_init -> int64
