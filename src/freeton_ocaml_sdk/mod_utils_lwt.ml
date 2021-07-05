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

open Ton_client_lwt
include Ton_client.UTILS

let convert_address = Tc.request ConvertAddress.f
let calc_storage_fee = Tc.request CalcStorageFee.f
let compress_zstd = Tc.request CompressZstd.f
let decompress_zstd = Tc.request DecompressZstd.f
