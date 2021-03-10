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

module TYPES = Ton_types

module CRYPTO = Ton_crypto
module RPC = Ton_rpc

external deploy :
  string array ->
  wc : int ->
  string TYPES.reply (* address *) = "deploy_contract_ml"


let deploy ~server_url ~tvc_file ~abi_file ~params ~keys_file
    ?(initial_data="") ?(initial_pubkey="") ?(wc=0) () =
  TYPES.reply
    (
      deploy [| server_url ; tvc_file ; abi_file ; params ;
                keys_file; initial_data; initial_pubkey |] ~wc
    )


module REQUEST = Ton_request
module ENCODING = Ton_encoding



external call :
  string array ->
  local : bool ->
  string TYPES.reply = "call_contract_ml"

let call ~server_url ~address ~abi_file ~meth ~params ~keys_file ~boc
    ~local () =
  TYPES.reply (
    call [| server_url ; address ; abi_file ; meth ; params ; keys_file ; boc |]
      ~local
  )
