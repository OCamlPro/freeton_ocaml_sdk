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

val call_lwt :
  ?client:Sdk_types.client ->
  server_url:string ->
  address:string ->
  abi:string ->
  meth:string ->
  params:string ->
  ?keypair:Sdk_types.keypair -> local:bool -> unit ->
  ( string, exn ) result Lwt.t

val call :
  ?client:Sdk_types.client ->
  server_url:string ->
  address:string ->
  abi:string ->
  meth:string ->
  params:string ->
  ?keypair:Sdk_types.keypair -> local:bool -> unit -> string
