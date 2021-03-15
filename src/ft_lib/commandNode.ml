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

let for_all_users config f =
  let net = Misc.current_network config in
  List.iter (fun key ->
      match EzString.chop_prefix ~prefix:"user" key.key_name with
      | None -> ()
      | Some _ ->
          f key
    ) net.net_keys

let z1000 = Z.of_string "1_000_000_000_000"

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
          let to_give = ref [] in
          let to_deploy = ref [] in
          for_all_users config (fun key ->
              match key.key_account with
              | None -> ()
              | Some { acc_address ; acc_contract ; _ } ->
                  let give, deploy =
                    match
                      Misc.post config
                        (Ton_sdk.REQUEST.account acc_address)
                        Ton_sdk.ENCODING.accounts_enc
                    with
                      [] -> true, true
                  | [ acc ] ->
                      let give =
                        match acc.acc_balance with
                        | None -> true
                        | Some z ->
                            z < z1000
                      in
                      let deploy =
                        match acc.acc_type with
                        | 0 -> true
                        | _ -> false
                      in
                      give, deploy
                  | _ -> assert false
                  in
                  if give then
                    to_give := (acc_address, key) :: !to_give ;
                  if deploy then
                    to_deploy := (acc_contract, key) :: !to_deploy
            );
          List.iter (fun (addr, key) ->
              CommandClient.action
                ~exec:false
                [
                  "call" ; "%{account:addr:giver}"; "sendGrams" ;
                  Printf.sprintf
                    {|{ "dest": "%s", "amount": "%%{1000:ton}" }|} addr;
                  "--abi"; "%{abi:Giver}" ;
                  "--sign" ; Printf.sprintf "%%{account:keyfile:%s}"
                    key.key_name;
                ]
            ) !to_give;

          List.iter (fun (contract, key) ->
              CommandMultisig.create_multisig key.key_name ?contract
            ) !to_deploy;

          ()

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
      EZCMD.info "Give 1000 TON to all user0-user9 from giver";



    ]
    ~doc: "Manage local nodes"
