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
open EzFile.OP

(*
Input arguments:
 address: 0:2e87845a4b04137d59931198006e3dd4ef49a63b62299aea5425dcf222afa02c
Connecting to https://net.ton.dev
Processing...
Succeeded.
acc_type:      Uninit
balance:       100000000000000
last_paid:     1613037693
last_trans_lt: 0x1232be65b04
data(boc): null

*)

type account_type = Uninit

type account_info = {
  mutable acc_type : account_type option ;
  mutable acc_balance : int64 option ;
  mutable acc_last_paid : int64 option ;
  mutable acc_trans_lt : string option ;
  mutable acc_data : string option ;
}

let get_account_info config address =

  let stdout = Misc.call_stdout_lines @@
    Misc.tonoscli config ["account" ; address ] in
  let account = {
    acc_type = None ;
    acc_balance = None ;
    acc_last_paid = None ;
    acc_trans_lt = None ;
    acc_data = None ;
  } in
  let success = ref false in
  let not_found = ref false in
  List.iter (fun s ->
      match EzString.cut_at s ':' with
      | "Succeeded.", "" -> success := true
      | "Account not found.", "" -> not_found := true
      | "balance", balance ->
          account.acc_balance <-
            Some ( Int64.of_string (String.trim balance ))
      | _ -> ()
    ) stdout;
  if not !success then
    Error.raise "Could not parse output of tonos-cli: %s"
      (String.concat "\n" stdout );
  if !not_found then None else Some account

let cut v =
  let rem = Int64.rem v 1_000L in
  let v = Int64.div v 1_000L in
  v, rem

let string_of_nanoton v =
  let v, nanotons = cut v in
  let v, mutons = cut v in
  let v, millitons = cut v in
  let v, tons = cut v in
  let v, thousandtons = cut v in
  let v, milliontons = cut v in
  let v, billiontons = cut v in
  assert (v = 0L);
  let tons =
    match billiontons, milliontons, thousandtons with
    | 0L, 0L, 0L -> Int64.to_string tons
    | 0L, 0L, _ -> Printf.sprintf "%Ld_%03Ld" thousandtons tons
    | 0L, _, _ -> Printf.sprintf "%Ld_%03Ld_%03Ld" milliontons thousandtons tons
    | _, _, _ -> Printf.sprintf "%Ld_%03Ld_%03Ld_%03Ld"
                   billiontons milliontons thousandtons tons
  in
  let nanotons = match nanotons, mutons, millitons with
    | 0L, 0L, 0L -> ""
    | 0L, 0L, _ -> Int64.to_string millitons
    | 0L, _, _ -> Printf.sprintf "%03Ld_%03Ld" millitons mutons
    | _, _, _ -> Printf.sprintf "%03Ld_%03Ld_%03Ld" millitons mutons nanotons
  in
  let s = Printf.sprintf "%s.%s" tons nanotons in
  s

let get_key_info config key ~info =
  if info then
    let json = EzEncoding.construct ~compact:false Encoding.key key in
    Printf.printf "%s\n%!" json
  else
    let address = match key.key_account with
      | None ->
          Error.raise "Address %s has no address (use genaddr before)"
            key.key_name
      | Some account -> account.acc_address
    in

    match get_account_info config address with
    | None ->
        Printf.eprintf "Account %S: not yet created\n%!" key.key_name
    | Some account ->
        Printf.eprintf "Account %S: %s\n%!" key.key_name
          (match account.acc_balance with
           | None -> "no balance"
           | Some n ->
               Printf.sprintf "%s TONs" (string_of_nanoton n))

let get_account_info accounts ~list ~info =

  let config = Config.config () in
  let net = Config.current_network config in
  if list then
    List.iter (fun key ->
        Printf.printf "* %S%s%s\n"
          key.key_name
          (match key.key_passphrase with
           | Some _ -> " P"
           | None ->
               match key.key_pair with
               | None -> ""
               | Some _ -> " S")
          (match key.key_account with
           | None -> ""
           | Some acc ->
               Printf.sprintf " %s%s" acc.acc_address
                 (match acc.acc_contract with
                  | None -> ""
                  | Some s -> Printf.sprintf " (%s)" s)
          )
      ) net.net_keys
  else
    match accounts with
    | [] -> List.iter (fun key ->
        match key.key_account with
        | None -> ()
        | Some _ ->
            get_key_info config key ~info) net.net_keys
    | names ->
        List.iter (fun name ->
            match Config.find_key net name with
            | None ->
                Error.raise "No key %S in network %S" name net.net_name
            | Some key ->
                get_key_info config key ~info
          ) names

let gen_passphrase config =
  let stdout = Misc.call_stdout_lines @@ Misc.tonoscli config ["genphrase"] in
  match stdout with
  | [ _ ; "Succeeded." ; seed ] ->
      begin match EzString.split seed '"' with
        | [ "Seed phrase: " ; seed_phrase ; "" ] ->
            seed_phrase
        | _ ->
            Error.raise "Could not parse seed phrase of tonos-cli genphrase"
      end
  | _ -> Error.raise "Could not parse output of tonos-cli genphrase: [%s]"
           (String.concat "|" stdout)

let gen_keypair config passphrase =
  let tmpfile = Misc.tmpfile () in
  Misc.call @@ Misc.tonoscli config
    [ "getkeypair" ; tmpfile; passphrase ];
  let keypair = Misc.read_json_file Encoding.keypair tmpfile in
  Sys.remove tmpfile;
  keypair

let genkey config maybe_name =
  let net = Config.current_network config in
  begin
    match maybe_name with
    | None -> ()
    | Some name ->
        Misc.check_new_key net name
  end;
  let seed_phrase = gen_passphrase config in

  (*
  let stdout = Misc.call_stdout_lines
    @@ Misc.tonoscli config [ "genpubkey" ; seed_phrase  ] in
  let pubkey =
    match stdout with
    | _ :: "Succeeded." :: pubkey :: _ ->
        begin match EzString.split pubkey ' ' with
          | [ "Public"; "key:" ; pubkey ] -> pubkey
          | stdout ->
              Error.raise "Could not parse pubkey of tonos-cli genpubkey: [%s]"
                (String.concat "|" stdout)
        end
    | _ -> Error.raise "Could not parse output of tonos-cli genpubkey: [%s]"
             (String.concat "|" stdout)
  in
*)
  let keypair = gen_keypair config seed_phrase in
  Printf.eprintf "{ \"public\": \"%s\",\n%!" keypair.public;
  Printf.eprintf "  \"secret\": \"%s\" }\n%!"
    (match keypair.secret with None -> assert false | Some s -> s);
  match maybe_name with
  | None -> ()
  | Some name ->
      let net = Config.current_network config in
      net.net_keys <- {
        key_name = name ;
        key_pair = Some keypair;
        key_passphrase = Some seed_phrase;
        key_account = None ;
      } :: net.net_keys;
      config.modified <- true;
      Printf.eprintf "Key for user %S generated\n%!" name


let gen_address config key_pair contract =

  let tvc_name = Printf.sprintf "contracts/%s.tvc" contract in
  let tvc_content =
    match Files.read tvc_name with
    | None ->
        Error.raise "Unknown contract %S" contract
    | Some tvc_content -> tvc_content
  in
  let contract_tvc = Globals.ft_dir // tvc_name in
  Misc.write_file contract_tvc tvc_content;

  let abi_name = Printf.sprintf "contracts/%s.abi.json" contract in
  let abi_content = match Files.read abi_name with
    | None -> assert false
    | Some abi_content -> abi_content
  in
  let contract_abi = Globals.ft_dir // abi_name in
  Misc.write_file contract_abi abi_content;

  let keypair_file = Misc.tmpfile () in
  Misc.write_json_file Encoding.keypair keypair_file key_pair;

  let stdout = Misc.call_stdout_lines @@
    Misc.tonoscli config ["genaddr" ;
                          contract_tvc ;
                          contract_abi ;
                          "--setkey" ; keypair_file ;
                          "--wc" ; "0"
                         ] in
  let raw_address = ref None in
  List.iter (fun s ->
      match EzString.split s ' ' with
      | [ "Raw" ; "address:" ; s ] -> raw_address := Some s
      | _ -> ()
    ) stdout;
  match !raw_address with
  | None -> Error.raise "Could not parse output of tonos-cli: %s"
              (String.concat "\n" stdout )
  | Some addr ->
      addr

let genaddr config contract key =

  let key_pair =
    match key.key_pair with
    | None ->
        Error.raise "Cannot genaddr without  keypair for %S" key.key_name
    | Some key_pair -> key_pair
  in
  let addr = gen_address config key_pair contract in
  Printf.eprintf "Address (%s for %s=%s...): %s\n%!"
    contract key.key_name
    (String.sub key_pair.public 0 10) addr;
  key.key_account <- Some {
      acc_address = addr ;
      acc_contract = Some contract ;
    };
  config.modified <- true

let add_account config
    ~name ~passphrase ~address ~contract ~pubkey ~seckey ~keyfile =
  let net = Config.current_network config in
  let key_name = name in
  Misc.check_new_key net name;
  let key_passphrase = passphrase in
  let key_pair =
    match keyfile with
    | Some file -> Some ( Misc.read_json_file Encoding.keypair file )
    | None ->
        match pubkey, seckey, passphrase with
        | Some public, Some _, _ ->
            Some { public ; secret = seckey }
        | _, _, Some passphrase ->
            Some ( gen_keypair config passphrase )
        | Some public, None, None ->
            Some { public; secret = None }
        | None, Some _, None ->
            Printf.eprintf "Warnign: unused --seckey SECKEY argument, because pubkey is missing\n%!";
            None
        | None, None, None -> None
  in

  let key_account = match address, contract, key_pair with
    | Some acc_address, _ , _ ->
        Some { acc_address ; acc_contract = contract }
    | None, Some contract, Some keypair ->
        let acc_address = gen_address config keypair contract in
        Some { acc_address ; acc_contract = Some contract }
    | None, Some _, None ->
        Printf.eprintf "Warning: unused --contract CONTRACT argument, because keypair is missing\n%!";
        None
    | None, None, None -> None
    | None, None, Some _ -> None
  in
  let key = { key_name ; key_account ; key_passphrase ; key_pair } in
  net.net_keys <- key :: net.net_keys ;
  config.modified <- true;
  Printf.eprintf "Account created.\n%!";
  get_key_info config key ~info:true;
  ()

let change_account config
    ~name ~passphrase ~address ~contract ~pubkey ~seckey ~keyfile =
  let net = Config.current_network config in
  let key = match Config.find_key net name with
    | None -> Error.raise "Unknown account %S cannot be modified\n%!" name
    | Some key -> key
  in

  begin
    match passphrase, key.key_passphrase with
    | None, _ -> ()
    | Some s, None -> key.key_passphrase <- Some s; config.modified <- true
    | Some _, Some _ ->
        Printf.eprintf "Warning: unused --passphrase PASSPHRASE argument, because passphrase already known\n%!"
  end;

  begin
    match key.key_pair with
    | Some { secret = Some _ ; _ } ->
        if keyfile <> None then
          Printf.eprintf
            "Warning: unused --keyfile FILE argument, because seckey already known\n%!";
        if seckey <> None then
          Printf.eprintf
            "Warning: unused --seckey SECKEY argument, because seckey already known\n%!";
    | _ ->
        let key_pair =
          match keyfile with
          | Some file -> Some ( Misc.read_json_file Encoding.keypair file )
          | None ->
              match pubkey, seckey, passphrase with
              | Some public, Some _, _ ->
                  Some { public ; secret = seckey }
              | _, _, Some passphrase ->
                  Some ( gen_keypair config passphrase )
              | Some public, None, None ->
                  Some { public; secret = None }
              | None, Some _, None ->
                  Printf.eprintf "Warning: unused --seckey SECKEY argument, because pubkey is missing\n%!";
                  None
              | None, None, None -> None
        in

        match key_pair with
        | None -> ()
        | Some p -> key.key_pair <- Some p; config.modified <- true
  end;

  let acc_contract, contract = match contract with
    | Some contract -> Some contract, Some contract
    | None ->
        match key.key_account with
        | Some { acc_contract ; _ } -> acc_contract, None
        | _ -> None, None
  in
  let key_account = match address, contract, key.key_pair with
    | Some acc_address, _ , _ ->
        Some { acc_address ; acc_contract }
    | None, Some contract, Some keypair ->
        let acc_address = gen_address config keypair contract in
        Some { acc_address ; acc_contract }
    | None, Some _, None ->
        Printf.eprintf
          "Warning: unused --contract CONTRACT argument, because keypair is missing\n%!";
        None
    | None, None, None -> None
    | None, None, Some _ -> None
  in

  begin
    match key_account with
    | None -> ()
    | Some a -> key.key_account <- Some a; config.modified <- true
  end;

  if config.modified then begin
    Printf.eprintf "Account modified.\n%!";
    get_key_info config key ~info:true
  end

let delete_account config net name =
  let found = ref false in
  net.net_keys <- List.filter (fun key ->
      if key.key_name = name then begin
        found := true;
        false
      end else true) net.net_keys;
  if !found then
    config.modified <- true
  else
    Error.raise "No account %S to delete. Aborting.\n%!" name

let action accounts ~list ~info
    ~create ~delete ~passphrase ~address ~contract ~pubkey ~seckey ~keyfile =
  let config = Config.config () in
  match passphrase, address, contract, pubkey, seckey, keyfile with
  | None, None, None, None, None, None ->
      if create then
        match accounts with
          [] -> genkey config None
        | _ ->
            List.iter (fun arg ->
                genkey config (Some arg)
              ) accounts;
      else
      if delete then
        let net = Config.current_network config in
        List.iter (fun name ->
            delete_account config net name
          ) accounts;
        Printf.eprintf "All provided accounts deleted.\n%!"
      else
        get_account_info accounts ~list ~info
  | _ ->
      match accounts with
      | _ :: _ :: _ ->
          Error.raise
            "Only one account can be created/specified with advanced options"
      | [] -> Error.raise "A new key name must be provided"
      | [ name ] ->
          if create then
            add_account config
              ~name ~passphrase ~address ~contract ~pubkey ~seckey ~keyfile
          else
            change_account config
              ~name ~passphrase ~address ~contract ~pubkey ~seckey ~keyfile

let cmd =
  let passphrase = ref None in
  let address = ref None in
  let contract = ref None in
  let pubkey = ref None in
  let seckey = ref None in
  let keyfile = ref None in
  let accounts = ref [] in
  let list = ref false in
  let info = ref false in
  let create = ref false in
  let delete = ref false in
  EZCMD.sub
    "account"
    (fun () -> action
        !accounts
        ~list:!list
        ~info:!info
        ~create:!create
        ~delete:!delete
        ~passphrase:!passphrase
        ~address:!address
        ~contract:!contract
        ~pubkey:!pubkey
        ~seckey:!seckey
        ~keyfile:!keyfile
    )
    ~args:
      [ [],
        Arg.Anons (fun args -> accounts := args),
        EZCMD.info "Name of account" ;

        [ "list" ] ,
        Arg.Set list,
        EZCMD.info "List all accounts" ;

        [ "info" ] ,
        Arg.Set info,
        EZCMD.info "Display account parameters" ;

        [ "create" ] ,
        Arg.Set create,
        EZCMD.info "Create new account" ;

        [ "delete" ] ,
        Arg.Set delete,
        EZCMD.info "Delete old accounts" ;

        [ "passphrase"],
        Arg.String (fun s -> passphrase := Some s),
        EZCMD.info "Passphrase for account";

        [ "address"],
        Arg.String (fun s -> address := Some s),
        EZCMD.info "Address for account";

        [ "contract"],
        Arg.String (fun s -> contract := Some s),
        EZCMD.info "Contract for account";

        [ "pubkey"],
        Arg.String (fun s -> pubkey := Some s),
        EZCMD.info "Public Key for account";

        [ "seckey"],
        Arg.String (fun s -> seckey := Some s),
        EZCMD.info "Secret Key for account";

        [ "keyfile"],
        Arg.String (fun s -> pubkey := Some s),
        EZCMD.info "Key file for account";

      ]
    ~man:[
      `S "DESCRIPTION";
      `Blocks [
        `P "This command can perform the following actions:";
        `I ("-", "Display information on given accounts, either locally or from the blockchain");
        `I ("-.", "Create new accounts");
        `I ("-.", "Add information to existing accounts");
        `I ("-.", "Delete existing accounts");
      ];
      `S "DISPLAY LOCAL INFORMATION";
      `Blocks [
        `P "Examples:";
        `Pre {|ft account --list|};
        `Pre {|ft account my-account --info|}
      ];
      `S "DISPLAY BLOCKCHAIN INFORMATION";
      `Blocks [
        `P "Accounts must have an address on the blockchain.";
        `P "Examples:";
        `Pre {|ft account my-account|}
      ];
      `S "CREATE NEW ACCOUNTS";
      `Blocks [
        `P "Examples:";
        `Pre {|ft account --create account1 account2 account3|};
        `Pre {|ft account --create new-account --passphrase "some known passphrase"|};
        `Pre {|ft account --create new-account --contract SafeMultisigWallet|};
        `P "Only the last one will compute an address on the blockchain, since the contract must be known.";
      ];
      `S "COMPLETE EXISTING ACCOUNTS";
      `Blocks [
        `P "Examples:";
        `Pre {|ft account old-account --contract SafeMultisigWallet|};
      ];
      `S "DELETE EXISTING ACCOUNTS";
      `Blocks [
        `P "Examples:";
        `Pre {|ft account --delete account1 account2|};
      ];

    ]
    ~doc:
      "Get account info (local or from blockchain), or create/modify/delete accounts."
