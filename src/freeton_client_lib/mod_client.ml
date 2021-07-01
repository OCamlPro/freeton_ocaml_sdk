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

open Mod_boc

(*
enum ClientErrorCode {
    NotImplemented = 1,
    InvalidHex = 2,
    InvalidBase64 = 3,
    InvalidAddress = 4,
    CallbackParamsCantBeConvertedToJson = 5,
    WebsocketConnectError = 6,
    WebsocketReceiveError = 7,
    WebsocketSendError = 8,
    HttpClientCreateError = 9,
    HttpRequestCreateError = 10,
    HttpRequestSendError = 11,
    HttpRequestParseError = 12,
    CallbackNotRegistered = 13,
    NetModuleNotInit = 14,
    InvalidConfig = 15,
    CannotCreateRuntime = 16,
    InvalidContextHandle = 17,
    CannotSerializeResult = 18,
    CannotSerializeError = 19,
    CannotConvertJsValueToJson = 20,
    CannotReceiveSpawnedResult = 21,
    SetTimerError = 22,
    InvalidParams = 23,
    ContractsAddressConversionFailed = 24,
    UnknownFunction = 25,
    AppRequestError = 26,
    NoSuchRequest = 27,
    CanNotSendRequestResult = 28,
    CanNotReceiveRequestResult = 29,
    CanNotParseRequestResult = 30,
    UnexpectedCallbackResponse = 31,
    CanNotParseNumber = 32,
    InternalError = 33,
    InvalidHandle = 34
  }
*)

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               TYPES                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)


module CryptoConfig = struct

  type t = {
    mnemonic_dictionary : int option ; [@opt None]
    mnemonic_word_count : int option ; [@opt None]
    hdkey_derivation_path : string option ; [@opt None]
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

module AbiConfig = struct

  type t = {
    workchain : int option ; [@opt None]
    message_expiration_timeout : int option ; [@opt None]
    message_expiration_timeout_grow_factor : int option ; [@opt None]
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

module BocConfig = struct

  type t= {
    cache_max_size : int option ; [@opt None]
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

module NetworkConfig = struct

  type t = {
    server_address: string option ; [@opt None]
    endpoints : string list option ; [@opt None]
    network_retries_count : int option ; [@opt None]
    max_reconnect_timeout : int option ; [@opt None]
    reconnect_timeout : int option ; [@opt None]
    message_retries_count : int option ; [@opt None]
    message_processing_timeout : int option ; [@opt None]
    wait_for_timeout : int option ; [@opt None]
    out_of_sync_threshold : int option ; [@opt None]
    sending_endpoint_count : int option ; [@opt None]
    latency_detection_interval : int option ; [@opt None]
    max_latency : int option ; [@opt None]
    access_key : string option ; [@opt None]
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

module ClientConfig = struct
  type t = {
    network: NetworkConfig.t option ; [@opt None]
    crypto: CryptoConfig.t option ; [@opt None]
    abi: AbiConfig.t option ; [@opt None]
    boc: BocConfig.t option ; [@opt None]
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

module BuildInfoDependency = struct

  type t = {
    name: string ;
    git_commit: string ;
  }
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end

module AppRequestResult = struct

  type t =
      Error of { text: string }
               [@kind "Error" ] [@kind_label "type"]
    | Ok of { result: any }
            [@kind "Ok" ] [@kind_label "type"]
  [@@deriving json_encoding ] (* {debug} *)

  let t_enc = enc
end


(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               FUNCTIONS                                *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

(* TODO:
resolve_app_request – Resolves application request processing result
*)

module Client = struct
  type t = Tc.context

  let create config =
    Tc.create_context
      ( EzEncoding.construct ~compact:true ClientConfig.t_enc config )

  let destroy t = Tc.destroy_context t
end

module GetApiReference = struct

  type params = unit
  [@@deriving json_encoding]

  type result = {
    api: any
  }
  [@@deriving json_encoding]

  let f = Tc.f "get_api_reference" ~params_enc ~result_enc

end

module Version = struct

  type params = unit
  [@@deriving json_encoding]

  type result = {
    version: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "version" ~params_enc ~result_enc

end

module BuildInfo = struct

  type params = unit
  [@@deriving json_encoding]

  type result = {
    build_number: int ;
    dependencies: BuildInfoDependency.t list ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "build_info" ~params_enc ~result_enc

end

module ResolveAppRequest = struct

  type params = {
    app_request_id: int ;
    result: AppRequestResult.t ;
  }
  [@@deriving json_encoding]

  type result = unit
  [@@deriving json_encoding]

  let f = Tc.f "resolve_app_request" ~params_enc ~result_enc

end



let get_api_reference = Tc.request_sync GetApiReference.f
let version = Tc.request_sync Version.f
let build_info = Tc.request_sync BuildInfo.f
let resolve_app_request = Tc.request_sync ResolveAppRequest.f
