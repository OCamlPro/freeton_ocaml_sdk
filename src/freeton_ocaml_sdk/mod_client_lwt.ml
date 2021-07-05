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

open Ton_client_lwt

include Ton_client.CLIENT

let get_api_reference = Tc.request GetApiReference.f
let version = Tc.request Version.f
let build_info = Tc.request BuildInfo.f
let resolve_app_request = Tc.request ResolveAppRequest.f
