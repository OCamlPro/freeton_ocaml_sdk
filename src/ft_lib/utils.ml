(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2021 OCamlPro SAS & Origin Labs SAS                     *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the GNU Lesser General    *)
(*  Public License version 2.1, with the special exception on linking     *)
(*  described in the LICENSE.md file in the root directory.               *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

(* These functions are 'misc' functions, except that they depend on
   the 'Config' module, so they cannot be in 'Misc'. *)

(*
open EzFile.OP
open Types
*)

let with_keypair key_pair f =
  let keypair_file = Misc.gen_keyfile key_pair in
  match f ~keypair_file with
  | exception exn ->
      Sys.remove keypair_file; raise exn
  | v ->
      Sys.remove keypair_file; v

let with_key_keypair key f =
  with_keypair (Misc.get_key_pair_exn key) f

let with_account_keypair net account f =
  let key = Misc.find_key_exn net account in
  with_key_keypair key f

let with_contract contract f =

  let contract_tvc = Misc.get_contract_tvcfile contract in
  let contract_abi = Misc.get_contract_abifile contract in

  f ~contract_tvc ~contract_abi
