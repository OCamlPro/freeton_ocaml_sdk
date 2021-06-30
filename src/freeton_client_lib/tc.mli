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

type context

val create_context : string -> context
val destroy_context : context -> unit

val init : unit -> unit

type response_kind =
  | SUCCESS
  | ERROR
  | NOP
  | APP_REQUEST
  | APP_NOTIFY
  | CUSTOM

type response = {
  id : int ;
  params : string ;
  kind : response_kind ;
  finished : bool ;
}

val request : context -> name:string -> params:string -> response list Lwt.t

val request_sync :
  string ->
  params_enc: 'a Json_encoding.encoding ->
  result_enc: 'b Json_encoding.encoding ->
  context -> 'a -> 'b
