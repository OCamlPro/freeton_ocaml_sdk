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

open Ton_client.TC

type request = {
  trigger : (string, string) result Lwt.u ;
}

let request_counter = ref 0
let waiting_requests = Hashtbl.create 13

open Lwt.Infix
let rec waiting_thread () =
  Lwt_unix.sleep 0.1 >>=
  let rec iter () =
    if has_response () then
      let r = get_response () in
      let request = Hashtbl.find waiting_requests r.id in
      if r.finished then
        Hashtbl.remove waiting_requests r.id ;
      begin
        match r.kind with
        | NOP -> ()
        | APP_REQUEST -> assert false
        | APP_NOTIFY -> assert false
        | CUSTOM -> assert false
        | SUCCESS ->
            Lwt.wakeup request.trigger (Ok r.params)
        | ERROR ->
            Lwt.wakeup request.trigger (Error r.params)
      end;
      iter ()
    else
      waiting_thread
  in
  iter ()

let init_done = ref false
let init () =
  if not !init_done then begin
    init_done := true ;
    Lwt.async waiting_thread ;
  end

let () = init ()

let request f context params =
  let id = !request_counter in
  request_counter := ( !request_counter + 1 ) land 0xffffffff;
  let (thread, trigger) = Lwt.wait () in
  let request = {
    trigger ;
  } in
  Hashtbl.add waiting_requests id request ;
  let params = EzEncoding.construct ~compact:true f.call_params params in
  request_c context f.call_name params id;
  thread >>= function
  | Ok params ->
      Lwt.return (Ok (EzEncoding.destruct f.call_result params))
  | Error params ->
      Lwt.return (Error params)
