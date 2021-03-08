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

module Crypto = Ton_crypto
module Rpc = Ton_rpc

external deploy :
  string array ->
  wc : int ->
  string (* address *) = "deploy_contract_ml"


let deploy ~server_url ~tvc_file ~abi_file ~params ~keys_file ~wc =
  deploy [| server_url ; tvc_file ; abi_file ; params ; keys_file |] ~wc
