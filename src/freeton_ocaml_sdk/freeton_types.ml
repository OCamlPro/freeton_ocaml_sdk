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
  | ERROR_ENCODE_MESSAGE_FAILED
  | ERROR_GENERATE_ADDRESS_FAILED
  | ERROR_RUN_TVM_FAILED
  | ERROR_READ_TVC_FAILED
  | ERROR_INVALID_JSON_INITIAL_DATA
  | ERROR_INVALID_JSON_PARAMS
  | ERROR_DEPLOY_FAILED
  | ERROR_TOKIO_RUNTIME_NEW
  | ERROR_DECODE_ADDRESS_FAILED
  | ERROR_FIND_LAST_SHARD_FAILED
  | ERROR_WAIT_NEXT_BLOCK_FAILED
  | ERROR_DECODE_MESSAGE_FAILED
  | ERROR_PARSE_MESSAGE_FAILED
  | ERROR_ENCODE_JSON_FAILED
  | ERROR_SEND_MESSAGE_FAILED
  | ERROR_WAIT_FOR_TRANSACTION_FAILED
  | ERROR_REPLY_IS_ERROR
  | ERROR_PARSE_REPLY_FAILED
  | ERROR_HDKEY_FROM_MNEMONIC_FAILED
  | ERROR_DERIVE_KEY_FAILED
  | ERROR_SECRET_KEY_FAILED
  | ERROR_KEYPAIR_OF_SECRET_FAILED
  | ERROR_PARSE_PUBKEY_FAILED
  | ERROR_LOAD_CONTRACT_IMAGE_FAILED
  | ERROR_UPDATE_CONTRACT_IMAGE_FAILED
  | ERROR_WRITE_TVC_FILE
  | ERROR_ENCODE_BODY_FAILED
  | ERROR_DECODE_BASE64_FAILED
  | ERROR_DECODE_PUBKEY_FAILED
  | ERROR_DECODE_SECRET_FAILED
  | ERROR_DECODE_HEXA_FAILED

exception TonError of error * string

let error_of_code = function
  | 0 -> ERROR_FAILWITH
  | 1 -> ERROR_TONCLIENT_CREATE
  | 2 -> ERROR_MNEMONIC_FROM_RANDOM
  | 3 -> ERROR_INVALID_JSON_ABI
  | 4 -> ERROR_ENCODE_MESSAGE_FAILED
  | 5 -> ERROR_GENERATE_ADDRESS_FAILED
  | 6 -> ERROR_RUN_TVM_FAILED
  | 7 -> ERROR_READ_TVC_FAILED
  | 8 -> ERROR_INVALID_JSON_INITIAL_DATA
  | 9 -> ERROR_INVALID_JSON_PARAMS
  | 10 -> ERROR_DEPLOY_FAILED
  | 11 -> ERROR_TOKIO_RUNTIME_NEW
  | 12 -> ERROR_DECODE_ADDRESS_FAILED
  | 13 -> ERROR_FIND_LAST_SHARD_FAILED
  | 14 -> ERROR_WAIT_NEXT_BLOCK_FAILED
  | 15 -> ERROR_DECODE_MESSAGE_FAILED
  | 16 -> ERROR_PARSE_MESSAGE_FAILED
  | 17 -> ERROR_ENCODE_JSON_FAILED
  | 18 -> ERROR_SEND_MESSAGE_FAILED
  | 19 -> ERROR_WAIT_FOR_TRANSACTION_FAILED
  | 20 -> ERROR_REPLY_IS_ERROR
  | 21 -> ERROR_PARSE_REPLY_FAILED
  | 22 -> ERROR_HDKEY_FROM_MNEMONIC_FAILED
  | 23 -> ERROR_DERIVE_KEY_FAILED
  | 24 -> ERROR_SECRET_KEY_FAILED
  | 25 -> ERROR_KEYPAIR_OF_SECRET_FAILED
  | 26 -> ERROR_PARSE_PUBKEY_FAILED
  | 27 -> ERROR_LOAD_CONTRACT_IMAGE_FAILED
  | 28 -> ERROR_UPDATE_CONTRACT_IMAGE_FAILED
  | 29 -> ERROR_WRITE_TVC_FILE
  | 30 -> ERROR_ENCODE_BODY_FAILED
  | 31 -> ERROR_DECODE_BASE64_FAILED
  | 32 -> ERROR_DECODE_PUBKEY_FAILED
  | 33 -> ERROR_DECODE_SECRET_FAILED
  | 34 -> ERROR_DECODE_HEXA_FAILED
  | _ -> assert false

let string_of_error = function
  | ERROR_FAILWITH -> "Failure"
  | ERROR_TONCLIENT_CREATE -> "Ton_client.create failed"
  | ERROR_MNEMONIC_FROM_RANDOM -> "Mnemonic_from_random failed"
  | ERROR_INVALID_JSON_ABI -> "Invalid json ABI"
  | ERROR_ENCODE_MESSAGE_FAILED -> "Encode message failed"
  | ERROR_GENERATE_ADDRESS_FAILED -> "Generate address failed"
  | ERROR_RUN_TVM_FAILED -> "Run TVM failed"
  | ERROR_READ_TVC_FAILED -> "Read TVC file failed"
  | ERROR_INVALID_JSON_INITIAL_DATA -> "Invalid JSON initial data"
  | ERROR_INVALID_JSON_PARAMS -> "Invalid JSON params"
  | ERROR_DEPLOY_FAILED -> "Deploy failed"
  | ERROR_TOKIO_RUNTIME_NEW -> "Tokio runtime new failed"
  | ERROR_DECODE_ADDRESS_FAILED -> "Decode address failed"
  | ERROR_FIND_LAST_SHARD_FAILED -> "Find_last_shard failed"
  | ERROR_WAIT_NEXT_BLOCK_FAILED -> "Wait_next_block failed"
  | ERROR_DECODE_MESSAGE_FAILED -> "Decode message failed"
  | ERROR_PARSE_MESSAGE_FAILED -> "Parse message failed"
  | ERROR_ENCODE_JSON_FAILED -> "Encode JSON failed"
  | ERROR_SEND_MESSAGE_FAILED -> "Send message failed"
  | ERROR_WAIT_FOR_TRANSACTION_FAILED -> "Wait for transaction failed"
  | ERROR_REPLY_IS_ERROR -> "Reply is an error"
  | ERROR_PARSE_REPLY_FAILED -> "Parse reply failed"
  | ERROR_HDKEY_FROM_MNEMONIC_FAILED -> "Gen HDkey from mnemonic failed"
  | ERROR_DERIVE_KEY_FAILED -> "Derive key for path failed"
  | ERROR_SECRET_KEY_FAILED -> "Secret key of derivation failed"
  | ERROR_KEYPAIR_OF_SECRET_FAILED -> "Keypair of secret key failed"
  | ERROR_PARSE_PUBKEY_FAILED -> "Parse pubkey failed"
  | ERROR_LOAD_CONTRACT_IMAGE_FAILED -> "Load contract image failed"
  | ERROR_UPDATE_CONTRACT_IMAGE_FAILED -> "Update contract image failed"
  | ERROR_WRITE_TVC_FILE -> "Write TVC file"
  | ERROR_ENCODE_BODY_FAILED -> "Encode body failed"
  | ERROR_DECODE_BASE64_FAILED -> "Decode base64 string failed"
  | ERROR_DECODE_PUBKEY_FAILED -> "Decode public key failed"
  | ERROR_DECODE_SECRET_FAILED -> "Decode secret key failed"
  | ERROR_DECODE_HEXA_FAILED -> "Decode hexa string failed"

let () =
  Printexc.register_printer (function
      | TonError (error, msg) ->
          let msg = try
              let json = Ezjsonm.from_string msg in
              let b = Buffer.create 10000 in
              let rec iter indent json =
                begin
                  match json with
                    `O list ->
                      Printf.bprintf b "{\n";
                      List.iter (fun (s,v) ->
                          Printf.bprintf b "%s  %s:" indent s;
                          iter (indent ^ "  ") v
                        ) list;
                      Printf.bprintf b "%s}" indent
                  | `A list ->
                      Printf.bprintf b "[\n";
                      List.iteri (fun i v ->
                          Printf.bprintf b "%s  %d:" indent i;
                          iter (indent ^ "  ") v;
                        ) list;
                      Printf.bprintf b "%s]" indent
                  | `Bool bool -> Printf.bprintf b "%b" bool
                  | `Null -> Printf.bprintf b "null"
                  | `Float f -> Printf.bprintf b "%f" f
                  | `String s -> Printf.bprintf b "%s" s
                end;
                Printf.bprintf b "\n"
              in
              iter "  " json;
              Buffer.contents b
            with _ -> msg
          in
          let s = Printf.sprintf "%s: %s" (string_of_error error) msg in
          Some s
      | _ -> None)



let reply r =
  match r.result, r.error with
  | Some r, None -> r
  | None, Some e ->
      if e.code = 0 then
        failwith e.msg
      else
        raise (TonError (error_of_code e.code, e.msg))
  | None, None -> assert false
  | Some _, Some _ -> assert false

let reply_lwt r =
  match r.result, r.error with
  | Some r, None -> Lwt.return (Ok r)
  | None, Some e ->
      if e.code = 0 then
        Lwt.return (Error (Failure e.msg))
      else
        Lwt.return (Error (TonError (error_of_code e.code, e.msg)))
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

type state_init

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

type decoded_message_body = {
  body_type : int ; (* 0:Input, 1:Output, 2:InternalOutput, 3:Event *)
  body_name : string ;
  body_args : string option ;
} [@@deriving json_encoding {option="option"}]


let string_of_decoded_message_body tr =
  EzEncoding.construct ~compact:false decoded_message_body_enc tr

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
