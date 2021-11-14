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

include Ton_client.PROCESSING

let send_message = Tc_lwt.request SendMessage.f
let wait_for_transaction = Tc_lwt.request WaitForTransaction.f
let process_message = Tc_lwt.request ProcessMessage.f
