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

module CLIENT = Sdk_client
module CRYPTO = Sdk_crypto
module RPC = Sdk_rpc
module BLOCK = Sdk_block
module ACTION = Sdk_action
module TVC = Sdk_tvc
module ENCODE = Sdk_encode

module CALL = Ton_call

module TYPES = struct
  include Sdk_types
  include TON.TYPES
end

module REQUEST = TON.REQUEST
module ENCODING = TON.ENCODING
module ABI = struct
  include Sdk_abi
  include TON.ABI
end
