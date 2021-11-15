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


external generate_mnemonic_ml: unit -> string Sdk_types.reply =
  "generate_mnemonic_ml"
let generate_mnemonic () = Sdk_types.reply (generate_mnemonic_ml ())

external generate_keypair_from_mnemonic :
  string -> string option -> Sdk_types.keypair Sdk_types.reply =
  "generate_keypair_from_mnemonic_ml"

let generate_keypair_from_mnemonic ?path m =
  Sdk_types.reply ( generate_keypair_from_mnemonic m path )

external generate_address :
  string array ->
  int ->
  string Sdk_types.reply =
  "generate_address_ml"

let generate_address ~tvc_file ~abi
    ?keypair
    ?(pubkey = match keypair with
      | None -> assert false
      | Some keypair -> keypair.Sdk_types.public)
    ?(wc = 0)
    ?(initial_data = "")
    ?(initial_pubkey = "")
    () =
  Sdk_types.reply ( generate_address
                          [| tvc_file ; abi ; initial_data ;
                             pubkey ; initial_pubkey |]
                      wc )

let std_path list =
  match list with
  | [] -> "m/44'/396'"
  | x :: tail ->
      Printf.sprintf "m/44'/396'/%s"
        (String.concat "/"
           (Printf.sprintf "%d'" x :: List.map string_of_int tail ))
