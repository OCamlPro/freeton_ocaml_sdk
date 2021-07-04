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

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               TYPES                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module AddressStringFormat = struct

  type t =
    | AccountId  [@kind "AccountId"] [@kind_label "type"]
    | Hex   [@kind "Hex"] [@kind_label "type"]
    | Base64 of {
        url: bool ;
        test: bool ;
        bounce: bool ;
      }
      [@kind "Base64"] [@kind_label "type"]
  [@@deriving json_encoding ]

  let t_enc = enc
end

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               FUNCTIONS                                *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module ConvertAddress = struct

  type params = {
    address: string ;
    output_format: AddressStringFormat.t ;
  }
  [@@deriving json_encoding]

  type result = {
    address: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "convert_address" ~params_enc ~result_enc

end

module CalcStorageFee = struct

  type params = {
    account: string ;
    period: int ;
  }
  [@@deriving json_encoding]

  type result = {
    fee: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "calc_storage_fee" ~params_enc ~result_enc

end

module CompressZstd = struct
  type params = {
    uncompressed: string ;
    level: int option ; [@opt None ]
  }
  [@@deriving json_encoding]

  type result = {
    compressed: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "compress_zstd" ~params_enc ~result_enc

end

module DecompressZstd = struct

  type params = {
    compressed: string
  }
  [@@deriving json_encoding]

  type result = {
    decompressed: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "decompress_zstd" ~params_enc ~result_enc

end

let convert_address = Tc.request ConvertAddress.f
let calc_storage_fee = Tc.request CalcStorageFee.f
let compress_zstd = Tc.request CompressZstd.f
let decompress_zstd = Tc.request DecompressZstd.f
