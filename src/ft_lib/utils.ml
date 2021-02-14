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

open EzFile.OP
open Types

let with_keypair key_pair f =
  let keypair_file = Misc.tmpfile () in
  Misc.write_json_file Encoding.keypair keypair_file key_pair;
  match f ~keypair_file with
  | exception exn ->
      Sys.remove keypair_file; raise exn
  | v ->
      Sys.remove keypair_file; v

let with_key_keypair key f =
  match key.key_pair with
  | None
  | Some { secret = None ; _ } ->
      Error.raise "Account %S does not have a secret key" key.key_name
  | Some key_pair ->
      with_keypair key_pair f

let with_account_keypair net account f =
  let key = Misc.find_key_exn net account in
  with_key_keypair key f

let with_contract contract f =

  let tvc_name = Printf.sprintf "contracts/%s.tvc" contract in
  let tvc_content =
    match Files.read tvc_name with
    | None ->
        Error.raise "Unknown contract %S" contract
    | Some tvc_content -> tvc_content
  in
  let contract_tvc = Globals.ft_dir // tvc_name in
  Misc.write_file contract_tvc tvc_content;
  match
    let abi_name = Printf.sprintf "contracts/%s.abi.json" contract in
    let abi_content = match Files.read abi_name with
      | None -> assert false
      | Some abi_content -> abi_content
    in
    let contract_abi = Globals.ft_dir // abi_name in
    Misc.write_file contract_abi abi_content;
    match f ~contract_tvc ~contract_abi with
    | exception exn ->
        Sys.remove contract_abi; raise exn
    | v ->
        Sys.remove contract_abi; v
  with
  | exception exn ->
      Sys.remove contract_tvc; raise exn
  | v ->
      Sys.remove contract_tvc; v
