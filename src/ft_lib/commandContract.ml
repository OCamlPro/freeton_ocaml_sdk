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

open EzCompat (* for StringSet *)
open Ezcmd.V2
open EZCMD.TYPES
open EzFile.OP
open Types

type create =
  | UseAccount
  | CreateAccount of string
  | ReplaceAccount of string

type todo =
    ListContracts
  | BuildContract of string
  | DeployContract of string

let remove_files dirname files =
  List.iter (fun file ->
      if Sys.file_exists file then
        Sys.remove file
    ) ( files @ List.map (fun file -> dirname // file) files)

let check_exists dirname file =
  if Sys.file_exists file then
    file
  else
    let file = dirname // file in
    if Sys.file_exists file then
      file
    else
      Error.raise "File %s was not generated" file

let action ~todo ~force ~sign ~params ~wc ~create =
  match todo with
  | ListContracts ->
      CommandList.list_contracts ()
  | BuildContract filename ->
      (* TODO: check that no account is using this contract,
         otherwise, these accounts will become unreachable, i.e. we
         lose the tvc file and so how to regen their address. *)
      let dirname = Filename.dirname filename in
      let basename = Filename.basename filename in
      let name, ext = EzString.cut_at basename '.' in
      if ext <> "sol" then
        Error.raise "File %s must end with .sol extension" basename;
      let known = CommandList.known_contracts () in
      if not force && StringMap.mem name known then
        Error.raise "Contract %s already exists (use -f to override)" name;
      let solc = Misc.binary_file "solc" in
      let tvm_linker = Misc.binary_file "tvm_linker" in
      let stdlib = Misc.binary_file "stdlib_sol.tvm" in

      let abi_file = name ^ ".abi.json" in
      let code_file = name ^ ".code" in
      let tvm_file = name ^ ".tvm" in
      remove_files dirname [ abi_file ; code_file ; tvm_file ];
      Misc.call [ solc ; filename ];
      let abi_file = check_exists dirname abi_file in
      let code_file = check_exists dirname code_file in
      Misc.call [ tvm_linker ; "compile" ; "-o" ; tvm_file ;
                  code_file ;
                  "--abi-json" ; abi_file ;
                  "--lib" ; stdlib
                ];
      let tvm_file = check_exists dirname tvm_file in

      Misc.call [ "cp" ; "-f" ; filename ; abi_file ; Globals.contracts_dir ];
      let tvc_file = Globals.contracts_dir // name ^ ".tvc" in
      Misc.call [ "cp" ; "-f" ; tvm_file ; tvc_file ];
      ()

  | DeployContract contract ->

      let config = Config.config () in
      let net = Misc.current_network config in
      let create =
        match create with
        | ReplaceAccount sign ->
            Misc.delete_account config net sign;
            CreateAccount sign
        | UseAccount | CreateAccount _ -> create
      in
      let sign =
        match create with
        | CreateAccount sign ->
            CommandAccount.genkey ~name:sign ~contract:contract config;
            CommandMultisig.send_transfer
              ~src:net.net_deployer
              ~dst:sign
              ~bounce:false
              ~amount:"1";
            sign
        | ReplaceAccount _ -> assert false
        | UseAccount ->
          match sign with
          | None -> Error.raise "--deploy CONTRACT requires --sign SIGNER"
          | Some sign -> sign
      in
      let key = Misc.find_key_exn net sign in
      begin
        match key.key_account with
        | Some { acc_contract = Some acc_contract ; _ } ->
            if acc_contract <> contract then
              Error.raise "Wrong contract %S for signer %S" acc_contract sign
        | _ -> ()
      end;
      CommandOutput.with_substituted config params (fun params ->
          Misc.deploy_contract config ~key ~contract ~params ~wc)

let cmd =
  let set_todo, with_todo = Misc.todo_arg () in
  let force = ref false in
  let signer = ref None in
  let params = ref "{}" in
  let wc = ref None in
  let create = ref UseAccount in
   EZCMD.sub
    "contract"
    (fun () ->
       with_todo (fun todo ->
           action
             ~todo ~force:!force
             ~sign:!signer
             ~params:!params
             ~wc:!wc
             ~create:!create
         )
    )
    ~args:
      [
        [ "list" ], Arg.Unit (fun () -> set_todo "--list" ListContracts ),
        EZCMD.info "List known contracts";

        [ "force" ], Arg.Set force,
        EZCMD.info "Override existing contracts";

        [ "build"], Arg.String (fun filename ->
            set_todo "--build" (BuildContract filename)),
        EZCMD.info "Build a contract and remember it";

        [ "deploy" ], Arg.String (fun contract ->
            set_todo "--deploy" (DeployContract contract)
          ),
        EZCMD.info "CONTRACT Deploy contract CONTRACT";

        [ "sign" ], Arg.String (fun s ->
            signer := Some s),
        EZCMD.info "ACCOUNT Sign with account ACCOUNT";

        [ "params" ], Arg.String (fun s ->
            params := s),
        EZCMD.info "PARAMS Constructor/call Arguments ({} by default)";

        [ "create" ], Arg.String (fun s -> create := CreateAccount s),
        EZCMD.info "ACCOUNT Create ACCOUNT by deploying contract (with --deploy)";

        [ "replace" ], Arg.String (fun s -> create := ReplaceAccount s),
        EZCMD.info "ACCOUNT Replace ACCOUNT when deploying contract (with --deploy)";

      ]
    ~doc: "Manage contracts"
