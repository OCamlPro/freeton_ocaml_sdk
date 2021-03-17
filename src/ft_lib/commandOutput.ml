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

open Ezcmd.V2
open EZCMD.TYPES
open Ez_subst.V1

(* open Types *)

(* Use %{account}, %{account:addr}, %{account:keyfile}, %{acccount:pubkey}
   %{contract:tvc}, %{contract:abi}

   Also:
  * %{nanoton<S}
  * %{hex<S}
  * %{base64}
 *)

let subst_string config =
  let net = Misc.current_network config in
  let files = ref [] in
  let brace () s =

    let rec iter = function
      | [ "env" ; var ] -> begin
          match Sys.getenv var with
          | exception Not_found ->
              Error.raise "Env variable %S is not defined" var
          | s -> s
        end

      (* Accounts substitutions: *)
      | [ "addr" ; "zero" ] ->
          "0:0000000000000000000000000000000000000000000000000000000000000000"

      (* Account substitutions *)
      | [ "account" ; "addr" ; account ] ->
          let key = Misc.find_key_exn net account in
          Misc.get_key_address_exn key
      | [ "account" ; "wc" ; account ] ->
          let key = Misc.find_key_exn net account in
          let acc = Misc.get_key_account_exn key in
          Misc.string_of_workchain acc.acc_workchain
      | [ "account" ; "pubkey" ; account ] ->
          let key = Misc.find_key_exn net account in
          let key_pair = Misc.get_key_pair_exn key in
          key_pair.public
      | [ "account" ; "passphrase" ; account ] ->
          let key = Misc.find_key_exn net account in
          Misc.get_key_passphrase_exn key
      | [ "account" ; "keyfile" ; account ] ->
          let key = Misc.find_key_exn net account in
          let key_pair = Misc.get_key_pair_exn key in
          let file = Misc.gen_keyfile key_pair in
          files := file :: !files;
          file
      | [ "account" ; "contract" ; "tvc" ; account ] ->
          let key = Misc.find_key_exn net account in
          let contract = Misc.get_key_contract_exn key in
          Misc.get_contract_tvcfile contract
      | [ "account" ; "contract" ; "abi" ; account ] ->
          let key = Misc.find_key_exn net account in
          let contract = Misc.get_key_contract_exn key in
          Misc.get_contract_abifile contract

      (* Contracts substitutions *)
      | [ "contract" ; "tvc" ; contract ] ->
          Misc.get_contract_tvcfile contract
      | [ "contract" ; "abi" ; contract ] ->
          Misc.get_contract_abifile contract

      (* Node substitutions *)
      | [ "node" ; "url" ] ->
          let net = Misc.current_network config in
          let node = Misc.current_node net in
          node.node_url

      | [ "ton" ; n ] ->
          Int64.to_string ( Misc.nanotokens_of_string n )
      | [ "file" ; file ] ->
          String.trim ( EzFile.read_file file )

      | "string" :: rem -> String.concat ":" rem

      (* encoders *)
      | "read" :: rem -> EzFile.read_file ( iter rem )
      | "hex" :: rem ->
          let `Hex s = Hex.of_string ( iter rem ) in s
      | "base64" :: rem ->
          Base64.encode_string ( iter rem )

      (* deprecated *)
      | [ account ; "addr" ]
      | [ "addr" ; account ] ->
          let key = Misc.find_key_exn net account in
          Misc.get_key_address_exn key
      | [ account ; "wc" ]
      | [ "wc" ; account ] ->
          let key = Misc.find_key_exn net account in
          let acc = Misc.get_key_account_exn key in
          Misc.string_of_workchain acc.acc_workchain
      | [ account ; "pubkey" ]
      | [ "pubkey" ; account ]->
          let key = Misc.find_key_exn net account in
          let key_pair = Misc.get_key_pair_exn key in
          key_pair.public
      | [ account ; "passphrase" ]
      | [ "passphrase" ; account ] ->
          let key = Misc.find_key_exn net account in
          Misc.get_key_passphrase_exn key
      | [ account ; "keyfile" ]
      | [ "keyfile" ; account ] ->
          let key = Misc.find_key_exn net account in
          let key_pair = Misc.get_key_pair_exn key in
          let file = Misc.gen_keyfile key_pair in
          files := file :: !files;
          file
      | [ account ; "contract"; "tvc" ]
      | [ "account-tvc" ; account ] ->
          let key = Misc.find_key_exn net account in
          let contract = Misc.get_key_contract_exn key in
          Misc.get_contract_tvcfile contract
      | [ account ; "contract" ; "abi" ]
      | [ "account-abi" ; account ] ->
          let key = Misc.find_key_exn net account in
          let contract = Misc.get_key_contract_exn key in
          Misc.get_contract_abifile contract

      (* Contracts substitutions *)
      | [ contract ; "tvc" ]
      | [ "tvc" ; contract ]->
          Misc.get_contract_tvcfile contract
      | [ contract ; "abi" ]
      | [ "abi" ; contract ] ->
          Misc.get_contract_abifile contract

      | [ n ; "ton" ] -> Int64.to_string ( Misc.nanotokens_of_string n )


      | _ ->
          Error.raise "Cannot substitute %S" s
    in
    iter ( EzString.split s ':' )
  in
  (fun s -> EZ_SUBST.string ~sep:'%' ~brace ~ctxt:() s), files

let with_substituted config params f =
  let (subst, files) = subst_string config in
  let clean () = List.iter Sys.remove !files in
  let params = subst params in
  match
    f params
  with
  | res -> clean (); res
  | exception exn -> clean () ; raise exn

let action ~stdout ~input ~keyfile ~addr =
  let config = Config.config () in
  let subst, _files = subst_string config in
  let content =
    match input with
    | Some file ->
        subst ( EzFile.read_file file )
    | None ->
        match keyfile with
        | Some account ->
            let net = Misc.current_network config in
            let key = Misc.find_key_exn net account in
            let key_pair = Misc.get_key_pair_exn key in
            EzEncoding.construct ~compact:false Encoding.keypair key_pair
        | None ->
            match addr with
            | Some account ->
                let net = Misc.current_network config in
                let key = Misc.find_key_exn net account in
                let acc = Misc.get_key_account_exn key in
                acc.acc_address
            | None ->
                Error.raise "Use one of the arguments"
  in
  match stdout with
  | None -> Printf.printf "%s\n%!" content
  | Some stdout ->
      EzFile.write_file stdout content

let cmd =
  let stdout = ref None in
  let input = ref None in
  let keyfile = ref None in
  let addr = ref None in
  EZCMD.sub
    "output"
    (fun () ->
       action
         ~stdout:!stdout
         ~input:!input
         ~keyfile:!keyfile
         ~addr:!addr
    )
    ~args:
      [
        [ "o" ], Arg.String (fun s -> stdout := Some s),
        EZCMD.info "FILE Save command stdout to file";

        [ "subst" ], Arg.String (fun s -> input := Some s),
        EZCMD.info "FILE Output content of file after substitution";

        [ "keyfile" ], Arg.String (fun s -> keyfile := Some s ),
        EZCMD.info "ACCOUNT Output key file of account";

        [ "addr" ], Arg.String (fun s -> addr := Some s),
        EZCMD.info "ACCOUNT Output address of account";

      ]
    ~doc: "Call tonos-cli, use -- to separate arguments"
