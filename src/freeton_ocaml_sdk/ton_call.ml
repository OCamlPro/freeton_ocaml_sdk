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

let call_lwt
    ?client ~server_url ~address ~abi ~meth ~params ?keypair ~local () =
  Lwt.bind
    (TON.REQUEST.post_lwt server_url
       (TON.REQUEST.account ~level:2 address) )
    (function
      | Error err -> Lwt.return (Error err)
      | Ok [] ->
          Lwt.return
            (Error
               (Failure
                  (Printf.sprintf "Account %s does not exist" address)))
      | Ok (_ :: _ :: _) -> assert false
      | Ok [ acc ] ->
          match acc.acc_boc with
          | None ->
              Lwt.return
                (Error
                   (Failure
                      (Printf.sprintf "Account %s is not initialized" address)))
          | Some boc ->
              let client =
                match client with
                | Some client -> client
                | None -> Sdk_client.create server_url
              in
              Sdk_action.call_lwt ~client ~address ~abi
                ~meth ~params ?keypair ~boc
                ~local ()
    )

let call ?client ~server_url ~address ~abi ~meth ~params ?keypair ~local () =
  match
    TON.REQUEST.post_run server_url
      (TON.REQUEST.account ~level:2 address)
  with
  | Error exn -> raise exn
  | Ok [] -> Printf.kprintf failwith "Account %s does not exist" address
  | Ok ( _ :: _ :: _ ) -> assert false
  | Ok [ acc ] ->
      match acc.acc_boc with
      | None ->
          Printf.kprintf failwith "Account %s is not initialized" address
      | Some boc ->
          let client =
            match client with
            | Some client -> client
            | None -> Sdk_client.create server_url
          in
          Sdk_action.call ~client ~address ~abi ~meth ~params ?keypair ~boc
            ~local ()
