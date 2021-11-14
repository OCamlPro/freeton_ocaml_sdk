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
    abi_version : string option ;
    version : string option ;    [@dft None]
    header : string list ;       [@dft []]
    functions : fonction list ;
    events : event list ;        [@dft []]
    data : data list ;           [@dft []]
    fields : param list ;        [@dft []]
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

(*
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
    input : any option; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module DeploySet = struct
  type t = {
    tvc: string ;
    workchain_id : int option ; [@opt None]
    initial_data : any option ; [@opt None]
    initial_pubkey : string option ; [@opt None]
  }
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
    value: any option ; [@opt None]
    header: FunctionHeader.t option ; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

module DecodedOutput = struct
  type t = {
    out_messages: DecodedMessageBody.t list ; (*  | null[], *)
    output: any option ; [@opt None]
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end


module StateInitParams = struct
  type t = {
    abi: Abi.t ;
    value: any ;
  }
  [@@deriving json_encoding ]

  let t_enc = enc
end

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               FUNCTIONS                                *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module EncodeMessageBody = struct

  type params = {
    abi: Abi.t ;
    call_set: CallSet.t ;
    is_internal: bool ;
    signer: Signer.t ;
    processing_try_index: int option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    body: string ;
    data_to_sign : string option ; [@opt None]
  }
  [@@deriving json_encoding]

  let f = Tc.f "encode_message_body" ~params_enc ~result_enc

end

module AttachSignatureToMessageBody = struct

  type params  = {
    abi: Abi.t ;
    public_key: string ;
    message: string ;
    signature: string ;
  }
  [@@deriving json_encoding]

  type result = {
    body: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "attach_signature_to_message_body" ~params_enc ~result_enc

end


module EncodeMessage = struct
  type params = {
    abi: Abi.t ;
    address: string option ; [@opt None]
    deploy_set: DeploySet.t option ; [@opt None]
    call_set: CallSet.t option ; [@opt None]
    signer: Signer.t ;
    processing_try_index: int option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    message: string ;
    data_to_sign: string option ; [@opt None]
    address: string ;
    message_id: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "encode_message" ~params_enc ~result_enc

end

module EncodeInternalMessage = struct
  type params = {
    abi: Abi.t option ; [@opt None]
    address: string option ; [@opt None]
    src_address: string option ; [@opt None]
    deploy_set: DeploySet.t option ; [@opt None]
    call_set: CallSet.t option ; [@opt None]
    value: string ;
    bounce: bool option ; [@opt None]
    enable_ihr: bool option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    message: string ;
    address: string ;
    message_id: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "encode_internal_message" ~params_enc ~result_enc

end

module AttachSignature = struct

  type params = {
    abi: Abi.t ;
    public_key: string ;
    message: string ;
    signature: string ;
  }
  [@@deriving json_encoding]

  type result = {
    message: string ;
    message_id: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "attach_signature" ~params_enc ~result_enc

end


module DecodeMessage = struct

  type params = {
    abi: Abi.t ;
    message: string ;
  }
  [@@deriving json_encoding]

  type result = DecodedMessageBody.t
  [@@deriving json_encoding]

  let f = Tc.f "decode_message" ~params_enc ~result_enc

end

module DecodeMessageBody = struct

  type params = {
    abi: Abi.t ;
    body: string ;
    is_internal: bool ;
  }
  [@@deriving json_encoding]

  type result = DecodedMessageBody.t
  [@@deriving json_encoding]

  let f = Tc.f "decode_message_body" ~params_enc ~result_enc

end

module MessageSource = struct
  type t =
    | Encoded of {
        message: string ;
        abi: Abi.t option ;
      }
        [@kind "Encoded" ] [@kind_label "type"]
    | EncodingParams of EncodeMessage.params
                        [@kind "EncodingParams" ] [@kind_label "type"]
  [@@deriving json_encoding ]

  let t_enc = enc

end

module StateInitSource = struct

  type t =
      Message of { source : MessageSource.t }
                 [@kind "Message" ] [@kind_label "type"]
    | StateInit of {
        code: string ;
        data: string ;
        library : string option ; [@opt None]
      }
        [@kind "StateInit" ] [@kind_label "type"]
    | Tvc of {
        tvc: string ;
        public_key: string option ; [@opt None]
        init_params: StateInitParams.t option ; [@opt None]
      }
        [@kind "Tvc" ] [@kind_label "type"]
  [@@deriving json_encoding ]

  let t_enc = enc

end

module EncodeAccount = struct

  type params = {
    state_init: StateInitSource.t ;
    balance: string option ; [@opt None] (* bigint *)
    last_trans_lt : string option ; [@opt None] (* bigint *)
    last_paid: int option ; [@opt None]
    boc_cache: BocCacheType.t option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    account: string ;
    id: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "encode_account" ~params_enc ~result_enc

end

let encode_message_body = Tc.request EncodeMessageBody.f
let attach_signature_to_message_body =
  Tc.request AttachSignatureToMessageBody.f
let encode_message = Tc.request EncodeMessage.f
let encode_internal_message = Tc.request EncodeInternalMessage.f
let attach_signature =
  Tc.request AttachSignature.f
let decode_message = Tc.request DecodeMessage.f
let decode_message_body = Tc.request DecodeMessageBody.f
let encode_account = Tc.request EncodeAccount.f
*)
