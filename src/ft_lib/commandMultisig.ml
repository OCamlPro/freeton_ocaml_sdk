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

open EzCompat
open Ezcmd.V2
open EZCMD.TYPES

open Types

(*
─➤ ft multisig --create validator validator validator2
Calling /home/lefessan/.ft/testnet/bin/tonos-cli --config /home/lefessan/.ft/testnet/tonos-cli.config deploy /home/lefessan/.ft/contracts/SafeMultisigWallet.tvc {"owners":[ "0x422c6c4f9ab510a8e8622c09c31babffe91af6e496cffd144d1e041d8b6c34ff", "0xf5bfbf398959566b6b538c151e1644ffb188dbdec8bd0acdc136c74422b18400" ],"reqConfirms":1} --abi /home/lefessan/.ft/contracts/SafeMultisigWallet.abi.json --sign /home/lefessan/.ft/tmpfile8dc1f8.tmp --wc 0
output:
 Config: /home/lefessan/.ft/testnet/tonos-cli.config
Input arguments:
     tvc: /home/lefessan/.ft/contracts/SafeMultisigWallet.tvc
  params: {"owners":[ "0x422c6c4f9ab510a8e8622c09c31babffe91af6e496cffd144d1e041d8b6c34ff", "0xf5bfbf398959566b6b538c151e1644ffb188dbdec8bd0acdc136c74422b18400" ],"reqConfirms":1}
     abi: /home/lefessan/.ft/contracts/SafeMultisigWallet.abi.json
    keys: /home/lefessan/.ft/tmpfile8dc1f8.tmp
      wc: 0
Connecting to https://net.ton.dev
Deploying...
Transaction succeeded.
Contract deployed at address: 0:2e87845a4b04137d59931198006e3dd4ef49a63b62299aea5425dcf222afa02cw
*)


let contract = "SafeMultisigWallet"

let check_key_contract key contract =
  match key.key_account with
  | Some { acc_contract = Some acc_contract ; _ }
    when acc_contract <> contract ->
      Error.raise "Account's contract is not %s" contract;
  | _ -> ()

let get_custodians account =
  let config = Config.config () in
  let net = Misc.current_network config in
  let key = Misc.find_key_exn net account in
  check_key_contract key contract ;
  let address = Misc.get_key_address_exn key in
  Utils.with_contract contract
    (fun ~contract_tvc:_ ~contract_abi ->
       Misc.call @@
       Misc.tonoscli config
         [ "run" ; address ; "getCustodians"; "{}" ;
           "--abi" ; contract_abi ]
    )

let get_waiting account =
 let config = Config.config () in
  let net = Misc.current_network config in
  let key = Misc.find_key_exn net account in
  check_key_contract key contract ;
  let address = Misc.get_key_address_exn key in
  Utils.with_contract contract
    (fun ~contract_tvc:_ ~contract_abi ->
       Misc.call @@
       Misc.tonoscli config
         [ "run" ; address ; "getTransactions"; "{}" ;
           "--abi" ; contract_abi ]
    )

let create_multisig account accounts ~not_owner ~req ~wc =
  let config = Config.config () in
  let net = Misc.current_network config in
  let owners = StringSet.of_list accounts in
  let owners =
    if not_owner then owners else
      StringSet.add account owners in

  let owners = StringSet.to_list owners in

  let owners = List.map (fun name ->
      match Misc.find_key net name with
      | None ->
          Error.raise "Key %S does not exist" name
      | Some key ->
          match key.key_pair with
          | None -> Error.raise "Key %S has no key pair" name
          | Some pair ->
              match pair.secret with
              | None ->
                  (* We should add an option to allow this *)
                  Error.raise "Key %S has no secret" name
              | Some _ -> pair.public
    ) owners in

  let nowners = List.length owners in
  if req < 1 || req > nowners then
    Error.raise "Invalid --req %d, should be 0 < REQ <= %d (nbr owners)"
      req nowners;

  let argument =
    Printf.sprintf "{\"owners\":[ \"0x%s\" ],\"reqConfirms\":%d}"
      ( String.concat "\", \"0x" owners )
      req
  in
  let key = Misc.find_key_exn net account in
  check_key_contract key contract ;

  begin
    match key.key_account with
    | None -> ()
    | Some acc ->
        begin
          match acc.acc_contract with
          | None -> ()
          | Some c ->
              if c <> contract then
                Error.raise {|Account address uses a different contract. Clear it with 'ft account ACCOUNT --contract ""|}
        end;
        match wc with
        | None -> ()
        | Some _ ->
            if Misc.string_of_workchain wc <>
               Misc.string_of_workchain  acc.acc_workchain then
              Error.raise {|Account addres uses a different workchain. Clear it with  'ft account ACCOUNT --contract ""|}
  end;

  let wc = match wc with
    | Some _ -> wc
    | None ->
        match key.key_account with
        | None -> None
        | Some acc ->
            acc.acc_workchain
  in

  Utils.with_key_keypair key
    (fun ~keypair_file ->
       Utils.with_contract contract
         (fun ~contract_tvc ~contract_abi ->
            let lines = Misc.call_stdout_lines
              @@ Misc.tonoscli config
                [ "deploy" ; contract_tvc ;
                  argument ;
                  "--abi" ; contract_abi ;
                  "--sign" ; keypair_file ;
                  "--wc" ; Misc.string_of_workchain wc
                ]
            in
            Printf.eprintf "output:\n %s\n%!"
              (String.concat "\n" lines);
            let acc_address = Misc.find_line_exn (function
                | [ "Contract" ; "deployed" ; "at" ; "address:"; address ] -> Some address
                | _ -> None) lines in
            key.key_account <- Some { acc_address ;
                                      acc_contract = Some contract ;
                                      acc_workchain = wc ;
                                    };
            config.modified <- true
         ))

let nanotokens_of_string s =
  let s = String.map (function
      '0'..'9' as c -> c
      | ',' | '_' -> '_'
      | '.' -> '.'
      | _ -> Error.raise "Invalid amount %S" s
    ) s in
  let tons, decimals = EzString.cut_at s '.' in
  let decimals = float_of_string ("0." ^ decimals) in
  let decimals = decimals *. 1_000_000_000. in
  let decimals = Int64.of_float decimals in
  let tons = Int64.of_string tons in
  let tons = Int64.mul tons 1_000_000_000L in
  Int64.add tons decimals

let () =
  assert (nanotokens_of_string "1" = 1_000_000_000L );
  assert (nanotokens_of_string "1_000" = 1_000_000_000_000L );
  assert (nanotokens_of_string "1." = 1_000_000_000L );
  assert (nanotokens_of_string "1.000" = 1_000_000_000L );
  assert (nanotokens_of_string "1.256" = 1_256_000_000L );
  assert (nanotokens_of_string "0.000_001" = 1_000L );

  ()

let send_transfer ~src ~dst ~bounce ~amount =
  let config = Config.config () in
  let net = Misc.current_network config in
  let src_key = Misc.find_key_exn net src in
  let src_addr = Misc.get_key_address_exn src_key in
  check_key_contract src_key contract ;
  let dst_key = Misc.find_key_exn net dst in
  let dst_addr = Misc.get_key_address_exn dst_key in


  let argument =

    let nanotokens, allBalance =
      if amount = "all" then
        0L, true
      else
        nanotokens_of_string amount, false
    in
    Printf.sprintf
      {|{"dest":"%s","value":%Ld,"bounce":%b,"allBalance":%b,"payload":""}|}
      dst_addr
      nanotokens
      bounce
      allBalance
  in

  Utils.with_key_keypair src_key
    (fun ~keypair_file ->
       Utils.with_contract contract
         (fun ~contract_tvc:_ ~contract_abi ->
            Misc.call @@
            Misc.tonoscli config [
              "call" ; src_addr ;
              "submitTransaction" ; argument ;
              "--abi" ; contract_abi ;
              "--sign" ; keypair_file
            ]
         ))

let send_confirm account ~tx_id =
  let config = Config.config () in
  let net = Misc.current_network config in
  let src_key = Misc.find_key_exn net account in
  let src_addr = Misc.get_key_address_exn src_key in
  check_key_contract src_key contract ;

  let argument =
    Printf.sprintf
      {|{"transactionId":"%s"}|} tx_id
  in

  Utils.with_key_keypair src_key
    (fun ~keypair_file ->
       Utils.with_contract contract
         (fun ~contract_tvc:_ ~contract_abi ->
            Misc.call @@
            Misc.tonoscli config [
              "call" ; src_addr ;
              "confirmTransaction" ; argument ;
              "--abi" ; contract_abi ;
              "--sign" ; keypair_file
            ]
         ))

let action account accounts ~create ~req ~not_owner ~custodians ~waiting
    ~transfer ~dst ~bounce ~confirm ~wc
  =
  if create then
    create_multisig account accounts ~not_owner ~req ~wc  ;
  if custodians then
    get_custodians account ;
  begin
    match transfer, dst with
    | Some amount, Some dst ->
        send_transfer ~src:account ~dst ~bounce ~amount
    | None, None ->
        ()
    | _ ->
        Error.raise "--transfer AMOUNT --to DEST"
  end;
  if waiting then
    get_waiting account ;
  begin
    match confirm with
    | None -> ()
    | Some tx_id ->
        send_confirm account ~tx_id
  end;
  ()

let cmd =
  let accounts = ref [] in

  let account = ref None in

  let create = ref false in
  let not_owner = ref false in
  let req = ref 1 in
  let custodians = ref false in
  let waiting = ref false in

  let wc = ref None in

  let transfer = ref None in
  let dst = ref None in
  let bounce = ref true in
  let confirm = ref None in
  EZCMD.sub
    "multisig"
    (fun () ->
       match !account with
       | None -> Error.raise "The argument --account ACCOUNT is mandatory"
       | Some account ->
           action account !accounts
             ~create:!create
             ~req:!req
             ~not_owner:!not_owner
             ~custodians:!custodians
             ~waiting:!waiting
             ~transfer:!transfer
             ~dst:!dst
             ~bounce:!bounce
             ~confirm:!confirm
             ~wc:!wc
    )
    ~args:
      [
        [], Arg.Anons (fun list -> accounts := list),
        EZCMD.info "Owners of contract for --create" ;

        [ "a" ; "account" ], Arg.String (fun s -> account := Some s),
        EZCMD.info "ACCOUNT The multisig account";

        [ "wc" ], Arg.Int (fun s -> wc := Some s),
        EZCMD.info "WORKCHAIN The workchain (default is 0)";

        [ "create" ], Arg.Set create,
        EZCMD.info "Deploy multisig wallet on account";

        [ "not-owner" ], Arg.Set not_owner,
        EZCMD.info " Initial account should not be an owner";

        [ "parrain" ], Arg.Clear bounce,
        EZCMD.info " Transfer to inactive account";

        [ "custodians" ], Arg.Set custodians,
        EZCMD.info "List custodians";

        [ "waiting" ], Arg.Set waiting,
        EZCMD.info " List waiting transactions";

        [ "confirm" ], Arg.String (fun s -> confirm := Some s),
        EZCMD.info "TX_ID Confirm transaction";

        [ "req" ], Arg.Int (fun s -> req := s),
        EZCMD.info "REQ Number of confirmations required";

        [ "transfer" ], Arg.String (fun s -> transfer := Some s),
        EZCMD.info "AMOUNT Transfer this amount";

        [ "to" ], Arg.String (fun s -> dst := Some s),
        EZCMD.info "ACCOUNT Target of a transfer";


      ]
    ~doc: "Manage a multisig-wallet (create, confirm, send)"
    ~man:[
      `S "DESCRIPTION";
      `P "This command is used to manage a multisig wallet, i.e. create the wallet, send tokens and confirm transactions.";

      `S "CREATE MULTISIG";
      `P "Create an account and get its address:";
      `Pre {|# ft account --create my-account
# ft genaddr my-account|};
      `P "Backup the account info off-computer.";
      `P "The second command will give you an address in 0:XXX format. Send some tokens on the address to be able to deploy the multisig.";
      `P "Check its balance with:";
      `Pre {|# ft account my-account|};
      `P "Then, to create a single-owner multisig:";
      `Pre {|# ft multisig -a my-account --create|} ;
      `P "To create a multi-owners multisig:";
      `Pre {|# ft multisig -a my-account --create owner2 owner3 owner4|} ;
      `P "To create a multi-owners multisig with 2 signs required:";
      `Pre {|# ft multisig -a my-account --create owner2 owner3 --req 2|} ;
      `P "To create a multi-owners multisig not self-owning:";
      `Pre {|# ft multisig -a my-account --create owner1 owner2 owner3 --not-owner|} ;

      `P "Verify that it worked:";
      `Pre {|# ft account my-account -v|};

      `S "GET CUSTODIANS";
      `P "To get the list of signers:";
      `Pre {|# ft multisig -a my-account --custodians"|};

      `S "SEND TOKENS";
      `P "Should be like that:";
      `Pre {|# ft multisig -a my-account --transfer 100.000 --to other-account|};
      `P "If the target is not an active account:";
      `Pre {|# ft multisig -a my-account --transfer 100.000 --to other-account --parrain|};
      `P "To send all the balance:";
      `Pre {|# ft multisig -a my-account --transfer all --to other-account|};

      `S "LIST WAITING TRANSACTIONS";
      `P "Display transactions waiting for confirmations:";
      `Pre {|# ft multisig -a my-account --waiting|};

      `S "CONFIRM TRANSACTION";
      `P "Get the transaction ID from above, and use:";
      `Pre {|# ft multisig -a my-account --confirm TX_ID|};
    ]
