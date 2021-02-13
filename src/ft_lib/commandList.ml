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

open EzCompat
open Ezcmd.V2

let known_contracts () =
  let contracts = ref StringSet.empty in
  List.iter (fun file ->
      if Filename.dirname file = "contracts" then
        match EzString.split (Filename.basename file) '.' with
        | [ name ; "abi" ; "json" ] ->
            contracts := StringSet.add name !contracts
        | _ -> ()
    ) Files.file_list;
  !contracts

let list_contracts () =
  let set = known_contracts () in
  Printf.printf "Known contracts:\n";
  StringSet.iter  (fun s ->
      Printf.printf "* %s\n" s) set;
  Printf.printf "%!"

let action () =
  list_contracts ()

let cmd =
  EZCMD.sub
    "list"
    (fun () -> action ())
    ~args: []
    ~doc: "List known contracts"
