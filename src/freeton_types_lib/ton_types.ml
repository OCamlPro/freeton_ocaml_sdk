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

module AbiContract = struct
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


  type t = {
    obsolete_abi_version : int option ; [@ key "ABI version"]
    abi_version : int option ;
    header : string list ;       [@dft []]
    functions : fonction list ;
    events : event list ;        [@dft []]
    data : data list ;           [@dft []]
  } [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end


module Abi = struct
  type t =
    | Contract of ( AbiContract.t [@obj1 "value"] ) [@kind "Contract" ]
                  [@kind_label "type"]
    | Json of ( string [@obj1 "value"] ) [@kind "Json" ]
              [@kind_label "type"]
    | AbiHandle of ( int [@obj1 "value"] ) [@kind "AbiHandle" ]
                   [@kind_label "type"]
    | Serialized of ( AbiContract.t [@obj1 "value"] ) [@kind "AbiContract" ]
                    [@kind_label "type"]

      [@@deriving json_encoding ]

  let t_enc = enc
end

module FunctionHeader = struct
  type t = {
    expire : int option ; [@opt None]
    time: string option ; [@opt None] (* bigint, *)
    pubkey: string option ; [@opt None]
  }
  [@@deriving json_encoding ]

   let t_enc = enc
end

module CallSet = struct
  type t = {
    function_name : string ;
    header : FunctionHeader.t option ; [@opt None]
    input : Json_repr.ezjsonm option; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module DeploySet = struct
  type t = {
    tvc: string ;
    workchain_id : int option ; [@opt None]
    initial_data : Json_repr.ezjsonm option ; [@opt None]
    initial_pubkey : string option ; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module KeyPair = struct
  type t = {
    public: string ;
    secret: string ;
  }
  [@@deriving json_encoding ]

   let t_enc = enc
end

module SigningBoxHandle = struct
  type t = int
  [@@deriving json_encoding ]

  let t_enc = enc
end

module Signer = struct
  type t =
    | None [@kind "None" ] [@kind_label "type"]
    | External of ( string  [@obj1 "public_key"] )
                  [@kind "External" ] [@kind_label "type"]
    | Keys of ( KeyPair.t  [@obj1 "keys"] )
              [@kind "Keys" ] [@kind_label "type"]
    | SigningBox of ( SigningBoxHandle.t [@obj1 "handle"] )
                    [@kind "SigningBox" ] [@kind_label "type"]
  [@@deriving json_encoding ]

   let t_enc = enc
 end

module MessageBodyType = struct
  type t = string
  [@@deriving json_encoding ]

(*
enum MessageBodyType {
    Input = "Input",
    Output = "Output",
    InternalOutput = "InternalOutput",
    Event = "Event"
}
*)
  let t_enc = enc
end

module DecodedMessageBody = struct
  type t = {
    body_type: MessageBodyType.t ;
    name: string ;
    value: Json_repr.ezjsonm option ; [@opt None]
    header: FunctionHeader.t option ; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module DecodedOutput = struct
  type t = {
    out_messages: DecodedMessageBody.t list ; (*  | null[], *)
    output: Json_repr.ezjsonm option ; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module TransactionFees = struct
  type t = {
    in_msg_fwd_fee: string ; (* bigint in fact *)
    storage_fee: string ;
    gas_fee: string ;
    out_msgs_fwd_fee: string ;
    total_account_fees: string ;
    total_output: string ;
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end
