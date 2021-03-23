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

type error_rs = {
  code : int ;
  msg : string ;
}

type 'a reply = {
  result : 'a option ;
  error : error_rs option ;
}

type error =
  | ERROR_FAILWITH
  | ERROR_TONCLIENT_CREATE
  | ERROR_MNEMONIC_FROM_RANDOM
  | ERROR_INVALID_JSON_ABI
  | ERROR_CANNOT_READ_KEYPAIR_FILE
  | ERROR_CANNOT_GENERATE_ADDRESS
  | ERROR_CANNOT_READ_ABI_FILE
  | ERROR_CANNOT_READ_TVC_FILE
  | ERROR_INVALID_JSON_INITIAL_DATA
  | ERROR_INVALID_JSON_PARAMS
  | ERROR_DEPLOY_FAILED
  | ERROR_TOKIO_RUNTIME_NEW

exception Error of error * string

let error_of_code = function
  | 0 -> ERROR_FAILWITH
  | 1 ->  ERROR_TONCLIENT_CREATE
  | 2 ->  ERROR_MNEMONIC_FROM_RANDOM
  | 3 ->  ERROR_INVALID_JSON_ABI
  | 4 -> ERROR_CANNOT_READ_KEYPAIR_FILE
  | 5 -> ERROR_CANNOT_GENERATE_ADDRESS
  | 6 ->  ERROR_CANNOT_READ_ABI_FILE
  | 7 ->  ERROR_CANNOT_READ_TVC_FILE
  | 8 ->  ERROR_INVALID_JSON_INITIAL_DATA
  | 9 ->  ERROR_INVALID_JSON_PARAMS
  | 10 ->  ERROR_DEPLOY_FAILED
  | 11 ->  ERROR_TOKIO_RUNTIME_NEW
  | _ -> assert false

let reply r =
  match r.result, r.error with
  | Some r, None -> r
  | None, Some e ->
      if e.code = 0 then
        failwith e.msg
      else
        raise (Error (error_of_code e.code, e.msg))
  | None, None -> assert false
  | Some _, Some _ -> assert false

type keypair = {
  public : string ;
  mutable secret : string option ;
} [@@deriving json_encoding]


(* abstract OCaml type for Rust
   ocaml::Pointer<crate::types::TonClientStruct>
 *)
type client

type shard_descr = {
  workchain_id: int32 ;
  shard: int64 ;
}

type msg_descr = {
    msg_id: string option ;
    transaction_id : string option ;
}

type block = {
    id: string ;
    gen_utime: int64 ;
    after_split: bool ;
    shard_descr: shard_descr ;
    in_msg_descr: msg_descr array ;
}

let string_of_msg_descr m =
  Printf.sprintf {|{ msg_id = %s ; transaction_id = %s }|}
    (match m.msg_id with
     | None -> "None"
     | Some s -> Printf.sprintf "Some %S" s)
    (match m.transaction_id with
     | None -> "None"
     | Some s -> Printf.sprintf "Some %S" s)

let string_of_block b =
  Printf.sprintf {|{
  id = %S ;
  gen_utime = %LdL ;
  after_split = %b ;
  shard_descr = {
    workchain_id = %ldl ;
    shard = %LdL ;
 } ;
 in_msg_descr = [|
    %s
    |];
}
|}
    b.id
    b.gen_utime
    b.after_split
    b.shard_descr.workchain_id
    b.shard_descr.shard
    (String.concat " ;\n      "
       (Array.map string_of_msg_descr b.in_msg_descr |> Array.to_list))
