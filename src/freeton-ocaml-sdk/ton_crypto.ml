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


module Cli = struct (* fonctions from tonos-cli *)

  external gen_seed_phrase_ml: unit -> string Ton_types.reply =
    "gen_seed_phrase_ml"
  let gen_seed_phrase () = Ton_types.reply (gen_seed_phrase_ml ())

end
