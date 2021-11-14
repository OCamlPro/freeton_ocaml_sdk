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

let read filename =
  let json = EzFile.read_file filename in
  EzEncoding.destruct  Ton_types.AbiContract.t_enc json

let write file abi =
  let json = EzEncoding.construct
      ~compact:false Ton_types.AbiContract.t_enc  abi in
  EzFile.make_dir ~p:true (Filename.dirname file);
  EzFile.write_file file json
