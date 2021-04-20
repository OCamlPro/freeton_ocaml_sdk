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

exception TonError of error * string

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





module ABI = struct
  (* inspired by TON-SDK/ton_client/src/abi/types.rs *)

  type param = {
    param_name : string ; [@key "name"]
    param_type : string ; [@key "type"]
    param_components : param list ; [@key "components"] [@dft []]
  }

  let param_enc =
    let open Json_encoding in
    mu "ABI.param" @@ fun self ->
    conv
      ( fun p ->
          (p.param_name, p.param_type, p.param_components) )
      ( fun ( param_name, param_type, param_components ) ->
          { param_name ; param_type ; param_components }
      )
      (obj3
         (req "name" string)
         (req "type" string)
         (dft "components" (list self) []))

  type fonction = {
    fun_name : string ; [@key "name" ]
    fun_inputs : param list ; [@key "inputs" ]
    fun_outputs : param list ; [@key "outputs" ]
    fun_id : string option ; [@key "id" ][@dft None]
  } [@@deriving json_encoding]

  type event = {
    ev_name : string ; [@key "name" ]
    ev_inputs : param list ; [@key "inputs" ]
    ev_outputs : param list ; [@key "outputs" ][@dft []]
    (* ev_outputs should always assert to empty, it appears in
       .abi.json files for some reason *)
    ev_id : string option ; [@key "id" ][@dft None]
  } [@@deriving json_encoding]

  type data = {
    data_key : int64 ;    [@key "key"]
    data_name : string ;  [@key "name" ]
    data_type : string ;  [@key "type" ]
    data_components : param list ; [@key "components"][@dft []]
  } [@@deriving json_encoding]


  type contract = {
    obsolete_abi_version : int option ; [@ key "ABI version"]
    abi_version : int option ;
    header : string list ;
    functions : fonction list ;
    events : event list ;
    data : data list ;
  } [@@deriving json_encoding]
end
