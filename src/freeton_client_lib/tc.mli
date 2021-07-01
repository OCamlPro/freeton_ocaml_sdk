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

val has_response : unit -> bool
val get_response : unit -> response
val request : context -> string -> string -> int -> unit


type ('params, 'result) f = {
  call_name : string ;
  call_params : 'params Json_encoding.encoding ;
  call_result : 'result Json_encoding.encoding ;
}

val f :
           string ->
           params_enc:'a Json_encoding.encoding ->
           result_enc:'b Json_encoding.encoding -> ('a, 'b) f


val request_sync : ('a, 'b) f -> context -> 'a -> 'b
