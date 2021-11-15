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

include Ton_client.CLIENT

let get_api_reference = Tc_lwt.request GetApiReference.f
let version = Tc_lwt.request Version.f
let build_info = Tc_lwt.request BuildInfo.f
let resolve_app_request = Tc_lwt.request ResolveAppRequest.f
