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

open Ezcmd.V2
open EZCMD.TYPES

let test1 file =
  let abi = Misc.read_json_file Ton_lib.Types.ABI.contract_enc file in
  Misc.write_json_file Ton_lib.Types.ABI.contract_enc (file ^ ".enc") abi

let action test files =
  match test with
  | 1 ->
      List.iter test1 files
  | _ -> failwith "no such test"

let cmd =
  let files = ref [] in
  let test = ref 1 in
  EZCMD.sub
    "test"
    (fun () -> action !test !files)
    ~args:
      [
        [], Arg.Anons (fun list -> files := list),
        EZCMD.info "args";

        [ "test1" ], Arg.Unit (fun () -> test := 1),
        EZCMD.info "Run test1";
      ]
    ~doc: "For testing only"
