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
open Types
(* open EzFile.OP *)

type todo =
    NodeStart
  | NodeStop
  | NodeWeb
  | NodeGive

let container_of_node local_node =
  Printf.sprintf "local-node-%d" local_node.local_port

let action ~todo =
  let config = Config.config () in
  let net = Misc.current_network config in
  let node = Misc.current_node net in
  match node.node_local with
  | None ->
      Error.raise "cannot manage remote node %S" node.node_name
  | Some local_node ->
      match todo with
      | NodeStart ->
          Misc.call [ "docker"; "start" ; container_of_node local_node ]
      | NodeStop ->
          Misc.call [ "docker"; "stop" ; container_of_node local_node ]
      | NodeWeb ->
          Misc.call [ "xdg-open";
                      Printf.sprintf "http://0.0.0.0:%d/graphql"
                        local_node.local_port ]
      | NodeGive ->
          for user = 0 to 9 do
            CommandClient.action
              ~exec:false
              [
                "call" ; "%{account:addr:giver}"; "sendGrams" ;
                Printf.sprintf
                  {|{ "dest": "%%{account:addr:user%d}", "amount": "%%{1000:ton}" }|}
                  user;
                "--abi"; "%{abi:Giver}" ;
                "--sign" ; Printf.sprintf "%%{account:keyfile:user%d}" user
              ]
          done

let cmd =
  let set_todo, with_todo = Misc.todo_arg () in
  EZCMD.sub
    "node"
    (fun () ->
       with_todo (fun todo ->
           action ~todo
         )
    )
    ~args: [

      [ "start" ], Arg.Unit (fun () -> set_todo "--start" NodeStart ),
      EZCMD.info "Start network node";

      [ "stop" ], Arg.Unit (fun () -> set_todo "--stop" NodeStop ),
      EZCMD.info "Stop network node";

      [ "web" ], Arg.Unit (fun () -> set_todo "--web" NodeWeb ),
      EZCMD.info "Open Node GraphQL webpage";

      [ "give" ], Arg.Unit (fun () -> set_todo "--give" NodeGive ),
      EZCMD.info "Give 1000 TON to user0-user9 from giver";



    ]
    ~doc: "Manage local nodes"
