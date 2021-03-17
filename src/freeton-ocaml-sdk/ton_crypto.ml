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


external generate_mnemonic_ml: unit -> string Ton_types.reply =
  "generate_mnemonic_ml"
let generate_mnemonic () = Ton_types.reply (generate_mnemonic_ml ())

external generate_keypair_from_mnemonic :
  string -> Ton_types.keypair Ton_types.reply =
  "generate_keypair_from_mnemonic_ml"

let generate_keypair_from_mnemonic m =
  Ton_types.reply ( generate_keypair_from_mnemonic m )

external generate_address :
  string array ->
  Ton_types.keypair ->
  int ->
  string Ton_types.reply =
  "generate_address_ml"

let generate_address ~tvc_file ~abi ~keypair
    ?(wc = 0)
    ?(initial_data = "") () =
  Ton_types.reply ( generate_address
                      [| tvc_file ; abi ; initial_data |]
                      keypair wc )
