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

val generate_mnemonic : unit -> string

val generate_keypair_from_mnemonic : ?path:string -> string -> Ton_types.keypair

val generate_address :
  tvc_file:string -> abi:string -> keypair:Ton_types.keypair ->
  ?wc:int -> ?initial_data:string -> unit -> string

val std_path : int list -> string
