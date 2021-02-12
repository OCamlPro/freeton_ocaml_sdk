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

open EzFile.OP
open Types

let verbose i = !Globals.verbosity >= i

let tmpfile () = Filename.temp_file ~temp_dir:Globals.ft_dir "tmpfile" ".tmp"

let call ?(stdout = Unix.stdout) args =
  if verbose 1 then
    Printf.eprintf "Calling %s\n%!" (String.concat " " (Array.to_list args));
  let pid = Unix.create_process args.(0) args Unix.stdin stdout Unix.stderr in
  let rec iter () =
    match Unix.waitpid [] pid with
    | exception Unix.Unix_error (EINTR, _, _) -> iter ()
    | _pid, status -> (
      match status with
      | WEXITED 0 -> ()
      | _ ->
        Error.raise "Command '%s' exited with error code %s"
          (String.concat " " (Array.to_list args))
          ( match status with
          | WEXITED n -> string_of_int n
          | WSIGNALED n -> Printf.sprintf "SIGNAL %d" n
          | WSTOPPED n -> Printf.sprintf "STOPPED %d" n ) )
  in
  iter ()

let call_stdout_file args =
  let tmpfile = tmpfile () in
  let stdout = Unix.openfile tmpfile
      [ Unix.O_CREAT ; Unix.O_WRONLY ; Unix.O_TRUNC ] 0o644 in
  call ~stdout args;
  Unix.close stdout;
  tmpfile

let call_stdout args =
  let file = call_stdout_file args in
  let stdout = EzFile.read_file file in
  Sys.remove file;
  stdout

let call_stdout_lines args =
  let file = call_stdout_file args in
  let stdout = EzFile.read_lines file in
  Sys.remove file;
  Array.to_list stdout

let net_dir config = Globals.ft_dir // config.current_network
let tonoscli_binary config = net_dir config // "bin" // "tonos-cli"
let tonoscli_config config = net_dir config // "tonos-cli.config"

let tonoscli config args =
  Array.of_list
    ( tonoscli_binary config ::
      "--config" ::
      tonoscli_config config ::
      args )

let tonoscli config args =
  if not ( Sys.file_exists ( tonoscli_config config ) ) then begin
    let binary = tonoscli_binary config in
    if not ( Sys.file_exists binary ) then begin
      EzFile.make_dir ~p:true ( Filename.dirname binary );
      Error.raise "You must put a copy of tonos-cli binary in %s\n%!" binary
    end;
    call (tonoscli config ["config" ;]);
    Sys.rename "tonlabs-cli.conf.json" ( tonoscli_config config );
  end;
  tonoscli config args

let read_json_file encoding filename =
  let json = EzFile.read_file filename in
  EzEncoding.destruct encoding json

let write_file file content =
  EzFile.make_dir ~p:true (Filename.dirname file);
  EzFile.write_file file content

let write_json_file encoding filename value =
  let json = EzEncoding.construct ~compact:false encoding value in
  write_file filename json


let check_new_key net name =
  List.iter (fun key ->
      if key.key_name = name then
        Error.raise "Key %S already exists" name
    ) net.net_keys
