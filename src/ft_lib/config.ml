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

open EzFile.OP

open Types

let set_config = ref
    (try
       Some ( Sys.getenv "FT_SWITCH")
     with _ -> None)

let mainnet_keys = [
  { key_name = "debot-multisig" ;
    key_passphrase = None ;
    key_pair = None ;
    key_account = Some
        { acc_address = "0:9ce35b55a00da91cfc70f649b2a2a58414d3e21ee8d1eb80dab834d442f33606" ;
          acc_contract = None ;
          acc_workchain = None } ;
  }
]

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
  net_keys = [] ;
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
  version = 0;
  current_network = "testnet" ;
  networks = [ testnet_network ;
               mainnet_network ;
               rustnet_network ;
               fldnet_network ;
             ] ;
}

let save_config config =
  EzFile.make_dir ~p:true Globals.ft_dir;
  if Sys.file_exists Globals.config_file then begin
    Sys.rename Globals.config_file (Globals.config_file ^ "~")
  end;
  List.iter (fun net ->
      match net.net_keys with
      | [] -> ()
      | keys ->
          let wallet_dir = Globals.ft_dir // net.net_name in
          let wallet_file = wallet_dir // "wallet.json" in
          EzFile.make_dir ~p:true wallet_dir ;
          Misc.write_json_file Encoding.wallet wallet_file keys;
          Printf.eprintf "Saving wallet file %s\n%!" wallet_file ;
          net.net_keys <- []
    ) config.networks ;
  Printf.eprintf "Saving config file %s\n%!" Globals.config_file ;
  Misc.write_json_file Encoding.config Globals.config_file config ;
  ()

let load_wallet net =
  match net.net_keys with
  | [] ->
      let wallet_file = Globals.ft_dir // net.net_name // "wallet.json" in
      if Sys.file_exists wallet_file then begin
        Printf.eprintf "Loading wallet file %s\n%!" wallet_file ;
        net.net_keys <- Misc.read_json_file Encoding.wallet wallet_file
      end
  | _ -> ()

let load_config () =
  let config =
    if Sys.file_exists Globals.config_file then begin
      let config = Misc.read_json_file Encoding.config Globals.config_file in
      Printf.eprintf "Config loaded from %s\n%!" Globals.config_file;
      config.modified <- false ;
      config
    end else begin
      Printf.eprintf "File %s does not exist\n%!" Globals.config_file ;
      default_config
    end
  in
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
  List.iter (fun net ->
      match net.net_keys with
      | [] -> ()
      | _keys ->
          Printf.eprintf "Keys present. Need saving\n%!";
          config.modified <- true (* force save to save keys in wallet *)
    ) config.networks;

  let net = Misc.current_network config in
  Printf.eprintf "Network: %s\n%!" net.net_name;
  load_wallet net ;

  if config.version < 1 then begin
    config.version <- 1 ;
    config.modified <- true ;
    List.iter (fun net ->
        load_wallet net ;
        if net.net_name = "mainnet" then
          net.net_keys <-
            net.net_keys @
            List.filter (fun key ->
                List.for_all
                  (fun k -> k.key_name <> key.key_name ) net.net_keys
              ) mainnet_keys
      ) config.networks
  end;

  EzFile.make_dir ~p:true Misc.temp_dir;
  if config.modified then begin
    save_config config;
    config.modified <- false;
  end;
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
