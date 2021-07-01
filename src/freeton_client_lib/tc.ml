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

type context  = int

type create_context_reply = {
  result : int ;
} [@@deriving json_encoding]

external create_context_c : string -> string = "tc_create_context_ml"
let create_context config =
  let s = create_context_c config in
  let s = EzEncoding.destruct create_context_reply_enc s in
  s.result

external destroy_context : int -> unit = "tc_destroy_context_ml"

external init : unit -> unit = "tc_init_ml" [@@noalloc]

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

external has_response : unit -> bool = "has_tc_response_ml" [@@noalloc]
external get_response : unit -> response = "get_tc_response_ml"

external request  :
  int -> string -> string -> int -> unit = "tc_request_ml"

let init_done = ref false
let init () =
  if not !init_done then begin
    init_done := true ;
    let _t = Thread.self () in
    init ()
  end

let () = init ()


external request_sync_c :
  int -> string -> string -> string = "tc_request_sync_ml"


type ('params, 'result) f = {
  call_name : string ;
  call_params : 'params Json_encoding.encoding ;
  call_result : 'result Json_encoding.encoding ;
}

let f call_name ~params_enc ~result_enc =
  { call_name ; call_params = params_enc ; call_result = result_enc }

let request_sync f context params =
  let r =
    request_sync_c context f.call_name
      ( EzEncoding.construct ~compact:true f.call_params params )
  in
  EzEncoding.destruct f.call_result r
