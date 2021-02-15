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
open Ez_subst.V1

(* open Types *)

(* Use %{account}, %{account:addr}, %{account:keyfile}, %{acccount:pubkey}
   %{contract:tvc}, %{contract:abi}
 *)

let action ~exec args =
  let config = Config.config () in
  let net = Misc.current_network config in
  let files = ref [] in
  let subst () s =
    match EzString.split s ':' with
    | [ account ]
    | [ account ; "addr" ] ->
        let key = Misc.find_key_exn net account in
        Misc.get_key_address_exn key
    | [ account ; "wc" ] ->
        let key = Misc.find_key_exn net account in
        let acc = Misc.get_key_account_exn key in
        Misc.string_of_workchain acc.acc_workchain
    | [ account ; "pubkey" ] ->
        let key = Misc.find_key_exn net account in
        let key_pair = Misc.get_key_pair_exn key in
        key_pair.public
    | [ account ; "passphrase" ] ->
        let key = Misc.find_key_exn net account in
        Misc.get_key_passphrase_exn key
    | [ account ; "keyfile" ] ->
        let key = Misc.find_key_exn net account in
        let key_pair = Misc.get_key_pair_exn key in
        let file = Misc.gen_keyfile key_pair in
        files := file :: !files;
        key_pair.public
    | [ account ; "contract"; "tvc" ] ->
        let key = Misc.find_key_exn net account in
        let contract = Misc.get_key_contract_exn key in
        Misc.get_contract_tvcfile contract
    | [ account ; "contract" ; "abi" ] ->
        let key = Misc.find_key_exn net account in
        let contract = Misc.get_key_contract_exn key in
        Misc.get_contract_abifile contract
    | [ contract ; "tvc" ] ->
        Misc.get_contract_tvcfile contract
    | [ contract ; "abi" ] ->
        Misc.get_contract_abifile contract
    | [ "node" ; "url" ] ->
        let node = Misc.current_node config in
        node.node_url
    | _ ->
        Error.raise "Cannot substitute %S" s
  in
  let args = List.map (fun arg ->
      EZ_SUBST.string ~sep:'%' ~brace:subst ~ctxt:() arg
    ) args in
  let clean () =
    List.iter Sys.remove !files
  in
  match Misc.call ( if exec then args else Misc.tonoscli config args ) with
  | exception exn -> clean () ; raise exn
  | v -> v

let cmd =
  let exec = ref false in
  let args = ref [] in
  EZCMD.sub
    "client"
    (fun () ->
       action !args ~exec:!exec
    )
    ~args:
      [ [],
        Arg.Anons (fun list -> args := list),
        EZCMD.info "Arguments to tonos-cli" ;

        [ "exec" ], Arg.Set exec,
        EZCMD.info "Do not call tonos-cli, the command is in the arguments";
      ]
    ~doc: "Call tonos-cli, use -- to separate arguments"
