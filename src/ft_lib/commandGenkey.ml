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
open EzFile.OP

let tonoscli_binary = Globals.homedir // ".ft" // "net.ton.dev" // "bin" // "tonos-cli"
let tonoscli_config = Globals.homedir // ".ft" // "net.ton.dev" // "tonos-cli.config"

let tonoscli args =
  Array.of_list
    ( tonoscli_binary ::
      "--config" ::
      tonoscli_config ::
      args )

let tonoscli args =
  if not ( Sys.file_exists tonoscli_config ) then begin
    Misc.call (tonoscli ["config" ;]);
    Sys.rename "tonlabs-cli.conf.json" tonoscli_config;
  end;
  tonoscli args

let genkey _maybe_name =
  let stdout = Misc.call_stdout_lines (tonoscli ["genphrase"]) in
  let seed_phrase =
    match stdout with
    | [| _ ; "Succeeded." ; seed |] ->
        begin match EzString.split seed '"' with
          | [ "Seed phrase: " ; seed_phrase ; "" ] ->
              seed_phrase
          | _ ->
              Error.raise "Could not parse seed phrase of tonos-cli genphrase"
        end
    | _ -> Error.raise "Could not parse output of tonos-cli genphrase: [%s]"
             (String.concat "|" (Array.to_list stdout))
  in

  let stdout = Misc.call_stdout_lines [| tonoscli_binary ; "genpubkey" ; seed_phrase  |] in
  let pubkey =
    match Array.to_list stdout with
    | _ :: "Succeeded." :: pubkey :: _ ->
        begin match EzString.split pubkey ' ' with
          | [ "Public"; "key:" ; pubkey ] -> pubkey
          | stdout ->
              Error.raise "Could not parse pubkey of tonos-cli genpubkey: [%s]"
                (String.concat "|" stdout)
        end
    | _ -> Error.raise "Could not parse output of tonos-cli genpubkey: [%s]"
             (String.concat "|" (Array.to_list stdout))
  in
  Misc.call [| tonoscli_binary ; "getkeypair" ; Misc.tmpfile; seed_phrase  |];

  let json = EzFile.read_file Misc.tmpfile in
  let json = Ezjsonm.from_string json in
  let keypair = Json_encoding.destruct Encoding.keypair json in
  Printf.eprintf "pubkey: %s\n%!" pubkey;
  Printf.eprintf "secret: %s\n%!" keypair.secret

let action args =
  match args with
    [] -> genkey None
  | _ ->
      List.iter (fun arg ->
          genkey (Some arg)
        ) args

let cmd =
  let args = ref [] in
  EZCMD.sub
    "genkey"
    (fun () -> action !args)
    ~args: (
      [ ( [],
          Arg.Anons (fun list -> args := list),
          EZCMD.info "Names of keys" )
      ] )
    ~doc: "Generate new keys"
