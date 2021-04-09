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

type arg = [
  | `string of string
  | `int of int
  | `float of float
  | `bool of bool
  | `raw of string
  | `obj of (string * arg) list ]

type query =
  | Scalar of string * (string * arg) list
  | Fields of string * (string * arg) list * query list
  | Root of query list

let rec string_of_arg ?(compact=true) (o : arg) = match o with
  | `string s -> Format.sprintf "%S" s
  | `raw s -> s
  | `int i -> string_of_int i
  | `float f -> string_of_float f
  | `bool b -> string_of_bool b
  | `obj l ->
    let sep = if compact then " " else "\n" in
    Format.sprintf "{%s%s%s}" sep (
      String.concat sep @@
      List.map (fun (s, o) ->
          Format.sprintf "%s: %s" s (string_of_arg o)) l) sep

let string_of_args ?(compact=true) args =
  let sep = if compact then " " else "\n" in
  match args with
  | [] -> ""
  | _ ->
    Format.sprintf "(%s)" @@
    String.concat sep @@
    List.map (fun (s, o) -> Format.sprintf "%s: %s" s (string_of_arg ~compact o)) args

let rec string_of_query ?(compact=true) q =
  let sep = if compact then " " else "\n" in
  match q with
  | Scalar (id, args) -> id ^ string_of_args ~compact args
  | Fields (id, args, fields) ->
    Format.sprintf "%s%s {%s%s%s}"
      id (string_of_args ~compact args)
      sep (String.concat sep (List.map (string_of_query ~compact) fields)) sep
  | Root fields ->
    Format.sprintf "{%s%s%s}"
      sep (String.concat sep (List.map (string_of_query ~compact) fields)) sep

let query_encoding = Json_encoding.(
    conv
      (fun q -> string_of_query (Root [q]))
      (fun _ -> failwith "destruct of query not handled") string)

let request_encoding = Json_encoding.(obj1 (req "query" query_encoding))

let scalar ?(args=[]) id = Scalar (id, args)
let fields ?(args=[]) id l = Fields (id, args, l)

let astring s : [< arg] = `string s
let araw s : [< arg] = `raw s
let aint i : [< arg] = `int i
let afloat f : [< arg] = `float f
let abool b : [< arg] = `bool b
let aobj l : [< arg] = `obj l
