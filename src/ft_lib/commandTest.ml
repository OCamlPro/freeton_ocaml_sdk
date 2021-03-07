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

let test1 file =
  let abi = Misc.read_json_file Ton_lib.Types.ABI.contract_enc file in
  Misc.write_json_file Ton_lib.Types.ABI.contract_enc (file ^ ".enc") abi

let test2 () =
  let s = Ton_sdk.Rpc.sync "net.ton.dev" "contracts.find.shard"
{|{
  "address":  "0:2222222222222222222222222222222222222222222222222222222222222222",
  "shards":
[
        {
          "workchain_id": 0,
          "shard": "0800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "1800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "2800000000000000",
          "hello": "my shard"
        },
        {
          "workchain_id": 0,
          "shard": "3800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "4800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "5800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "6800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "7800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "8800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "9800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "a800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "b800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "c800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "d800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "e800000000000000"
        },
        {
          "workchain_id": 0,
          "shard": "f800000000000000"
        }
      ]
}|} in
  Printf.eprintf "%s\n%!" s

    (*
List last 10 transactions:
{ transactions(limit: 10) { id tr_type status block_id account_addr total_fees(format: DEC) balance_delta(format: DEC) in_message { id msg_type status block_id src dst value(format: DEC) } } }
*)

let test3 () =
  let open Ton in
  let open Lwt.Infix in
  let network = "http://localhost:80" in
  let request () =
    let input = Request.transactions ~limit:10 [] in
    Printf.eprintf "input: %s\n%!" ( Graphql.string_of_query input);
    let output = Encoding.transactions_enc in
    EzCohttp_lwt.post0 (EzAPI.TYPES.BASE network) (Request.service output)
      ~input >|= function
    | Error e ->
        Format.printf "%s@."
          (EzRequest_lwt.string_of_error (fun exn -> Some (Printexc.to_string exn)) e)
    | Ok l ->
        Format.printf "%s@."(EzEncoding.construct ~compact:false output l)
  in
  (* Cohttp_lwt_unix.Debug.activate_debug (); *)
  Lwt_main.run (request ())


let action test files =
  match test with
  | 1 ->
      List.iter test1 files
  | 2 -> test2 ()
  | 3 -> test3 ()
  | _ -> failwith "no such test"

let cmd =
  let files = ref [] in
  let test = ref 1 in
  EZCMD.sub
    "test"
    (fun () -> action !test !files)
    ~args:
      [
        [], Arg.Anons (fun list -> files := list),
        EZCMD.info "args";

        [ "test" ], Arg.Int (fun s -> test := s),
        EZCMD.info "NUM Run test NUM";
      ]
    ~doc: "For testing only"
