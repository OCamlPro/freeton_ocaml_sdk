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

external has_tc_response : unit -> bool = "has_tc_response_ml" [@@noalloc]
external get_tc_response : unit -> response = "get_tc_response_ml"

type request = {
  mutable responses : response list ;
  trigger : response list Lwt.u ;
}

let request_counter = ref 0
let waiting_requests = Hashtbl.create 13

external request_c :
  int -> string -> string -> int -> unit = "tc_request_ml"

let request context ~name ~params =
  let id = !request_counter in
  request_counter := ( !request_counter + 1 ) land 0xffffffff;
  let (thread, trigger) = Lwt.wait () in
  let request = {
    responses = [] ;
    trigger ;
  } in
  Hashtbl.add waiting_requests id request ;
  request_c context name params id;
  thread

open Lwt.Infix
let rec waiting_thread () =
  Lwt_unix.sleep 0.1 >>=
  let rec iter () =
    if has_tc_response () then
      let r = get_tc_response () in
      let request = Hashtbl.find waiting_requests r.id in
      request.responses <- r :: request.responses ;
      if r.finished then begin
        Hashtbl.remove waiting_requests r.id ;
        Lwt.wakeup request.trigger (List.rev request.responses)
      end ;
      iter ()
    else
      waiting_thread
  in
  iter ()

let init_done = ref false
let init () =
  if not !init_done then begin
    init_done := true ;
    let _t = Thread.self () in
    Lwt.async waiting_thread ;
    init ()
  end

let () = init ()


external request_sync_c :
  int -> string -> string -> string = "tc_request_sync_ml"
let request_sync name ~params_enc ~result_enc context params =
  let r =
    request_sync_c context name
      ( EzEncoding.construct ~compact:true params_enc params )
  in
  EzEncoding.destruct result_enc r
