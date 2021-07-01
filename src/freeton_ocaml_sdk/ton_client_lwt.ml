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

module TC = struct
  include Ton_client.TC

end


(*
val request : context -> name:string -> params:string -> response list Lwt.t
*)

type request = {
  mutable responses : TC.response list ;
  trigger : TC.response list Lwt.u ;
}

let request_counter = ref 0
let waiting_requests = Hashtbl.create 13

open Lwt.Infix
let rec waiting_thread () =
  Lwt_unix.sleep 0.1 >>=
  let rec iter () =
    if TC.has_response () then
      let r = TC.get_response () in
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
    Lwt.async waiting_thread ;
  end

let () = init ()

let request context ~name ~params =
  let id = !request_counter in
  request_counter := ( !request_counter + 1 ) land 0xffffffff;
  let (thread, trigger) = Lwt.wait () in
  let request = {
    responses = [] ;
    trigger ;
  } in
  Hashtbl.add waiting_requests id request ;
  TC.request context name params id;
  thread
