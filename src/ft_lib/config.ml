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

let mainnet_node = {
  node_name = "tonlabs" ;
  node_url = "https://main.ton.dev";
}

let testnet_node = {
  node_name = "tonlabs" ;
  node_url = "https://net.ton.dev";
}

let rustnet_node = {
  node_name = "tonlabs" ;
  node_url = "https://rustnet.ton.dev";
}

let fldnet_node = {
  node_name = "tonlabs" ;
  node_url = "https://fld.ton.dev";
}

let mainnet_network = {
  net_name = "mainnet" ;
  current_node = "tonlabs" ;
  current_account = None ;
  net_nodes = [ mainnet_node ] ;
  net_keys = [ ];
}

let testnet_network = {
  net_name = "testnet" ;
  current_node = "tonlabs" ;
  current_account = None ;
  net_nodes = [ testnet_node ] ;
  net_keys = [ ];
}

let fldnet_network = {
  net_name = "fldnet" ;
  current_node = "tonlabs" ;
  current_account = None ;
  net_nodes = [ fldnet_node ] ;
  net_keys = [ ];
}

let rustnet_network = {
  net_name = "rustnet" ;
  current_node = "tonlabs" ;
  current_account = None ;
  net_nodes = [ rustnet_node ] ;
  net_keys = [ ];
}

let default_config = {
  modified = true ;
  current_network = "testnet" ;
  networks = [ testnet_network ;
               mainnet_network ;
               rustnet_network ;
               fldnet_network ;
             ] ;
}

let save_config config =

  if Sys.file_exists Globals.config_file then begin
    Sys.rename Globals.config_file (Globals.config_file ^ "~")
  end;
  Misc.write_json_file Encoding.config Globals.config_file config

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
  let config =
    match !set_config with
    | None -> config
    | Some switch ->
        let list = EzString.split switch '.' in
        let rec set_node net list =
          match list with
          | [] -> ()
          | name :: tail ->
              begin
                match Misc.find_node net name, Misc.find_key net name with
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
              match Misc.find_network config name with
              | Some net ->
                  config.current_network <- name;
                  set_node net tail
              | None ->
                  let net =
                    Misc.find_network_exn config config.current_network in
                  set_node net list
        in
        set_network list ;
        config
  in
  let net = Misc.current_network config in
  Printf.eprintf "Network: %s\n%!" net.net_name;
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
