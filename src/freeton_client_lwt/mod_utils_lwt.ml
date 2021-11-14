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

include Ton_client.UTILS

let convert_address = Tc_lwt.request ConvertAddress.f
let calc_storage_fee = Tc_lwt.request CalcStorageFee.f
let compress_zstd = Tc_lwt.request CompressZstd.f
let decompress_zstd = Tc_lwt.request DecompressZstd.f
