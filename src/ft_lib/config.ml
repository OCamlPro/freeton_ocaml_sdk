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

open Types

let set_config = ref
    (try
       Some ( Sys.getenv "FT_SWITCH")
     with _ -> None)

let ton_mainnet_node = {
  node_name = "ton" ;
  node_url = "https://main.ton.dev";
}

let ton_testnet_node = {
  node_name = "ton" ;
  node_url = "https://net.ton.dev";
}

let mainnet_network = {
  net_name = "mainnet" ;
  current_node = "ton" ;
  current_account = None ;
  net_nodes = [ ton_mainnet_node ] ;
  net_keys = [ ];
}

let testnet_network = {
  net_name = "testnet" ;
  current_node = "ton" ;
  current_account = None ;
  net_nodes = [ ton_testnet_node ] ;
  net_keys = [ ];
}

let default_config = {
  modified = true ;
  current_network = "testnet" ;
  networks = [ testnet_network ; mainnet_network ] ;
}

let save_config config =

  if Sys.file_exists Globals.config_file then begin
    Sys.rename Globals.config_file (Globals.config_file ^ "~")
  end;
  Misc.write_json_file Encoding.config Globals.config_file config

let find_network config name =
  let rec iter networks =
    match networks with
    | [] -> Error.raise "Network %S does not exist" name
    | net :: tail ->
        if net.net_name = name then net else iter tail
  in
  iter config.networks

let find_node net name =
  let rec iter nodes =
    match nodes with
    | [] -> None
    | node :: tail ->
        if node.node_name = name then Some node else iter tail
  in
  iter net.net_nodes

let find_key net name =
  let rec iter keys =
    match keys with
    | [] -> None
    | key :: tail ->
        if key.key_name = name then Some key else iter tail
  in
  iter net.net_keys



let load_config () =
  let config =
    if Sys.file_exists Globals.config_file then
      Misc.read_json_file Encoding.config Globals.config_file
    else
      let config = default_config in
      EzFile.make_dir ~p:true Globals.ft_dir;
      save_config config;
      config
  in
  config.modified <- false;
  match !set_config with
  | None -> config
  | Some switch ->
      let list = EzString.split switch '.' in
      let rec set_node net list =
        match list with
        | [] -> ()
        | name :: tail ->
            begin
              match find_node net name, find_key net name with
              | Some _, Some _ -> assert false
              | Some _node, _ ->
                  net.current_node <- name
              | None, Some _key ->
                  net.current_account <- Some name
              | None, None ->
                  Error.raise "Unknown node or account %S" name
            end;
            set_node net tail
      in
      let set_network list =
        match list with
        | [] -> ()
        | name :: tail ->
            match find_network config name with
            | net ->
                config.current_network <- name;
                set_node net tail
            | exception ( Error.Error _ ) ->
                let net = find_network config config.current_network in
                set_node net list
      in
      set_network list ;
      config

let config = lazy (load_config ())
let config () = Lazy.force config

let print () =
  let config = config () in
  List.iter (fun net ->
      let current = net.net_name = config.current_network in
      Printf.eprintf "* %s%s\n%!" net.net_name
        (if current then " (current)" else "");
      List.iter (fun node ->
          let current_node = node.node_name = net.current_node in
          Printf.eprintf "  - %s%s\n%!" node.node_name
            (if current_node then
               if current then " (current)"
               else " (current if network was selected)"
             else "");
          Printf.eprintf "    url: %s\n%!" node.node_url
        ) net.net_nodes
    ) config.networks

let current_network config =
  find_network config config.current_network

let current_node config =
  let net = find_network config config.current_network in
  match find_node net net.current_node with
  | None ->
      Error.raise "Unknown node %S in network %S"
        net.current_node net.net_name
  | Some node -> node
