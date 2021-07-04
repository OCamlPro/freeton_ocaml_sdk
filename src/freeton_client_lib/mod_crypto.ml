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

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               TYPES                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

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

(**************************************************************************)
(*                                                                        *)
(*                                                                        *)
(*                               FUNCTIONS                                *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

module Factorize = struct
  type params = {
    composite: string
  }
  [@@deriving json_encoding]

  type result = {
    factors: string list ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "factorize" ~params_enc ~result_enc
end

module ModularPower = struct

  type params = {
    base: string ;
    exponent: string ;
    modulus: string ;
  }
  [@@deriving json_encoding]

  type result = {
    modular_power: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "modular_power" ~params_enc ~result_enc
end


module TonCrc16 = struct

  type params = {
    data: string
  }
  [@@deriving json_encoding]

  type result = {
    crc: number
  }
  [@@deriving json_encoding]

  let f = Tc.f "ton_crc16" ~params_enc ~result_enc
end

module GenerateRandomBytes = struct

  type params = {
    length: number
  }
  [@@deriving json_encoding]

  type result = {
    bytes: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "generate_random_bytes" ~params_enc ~result_enc
end

module ConvertPublicKeyToTonSafeFormat = struct

  type params = {
    public_key: string
  }
  [@@deriving json_encoding]

  type result = {
    ton_public_key: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "convert_public_key_to_ton_safe_format" ~params_enc ~result_enc
end

module GenerateRandomSignKeys = struct

  type params = unit
  [@@deriving json_encoding]

  type result = KeyPair.t
  [@@deriving json_encoding]

  let f = Tc.f "generate_random_sign_keys" ~params_enc ~result_enc

end

module Sign = struct

  type params = {
    unsigned: string ;
    keys: KeyPair.t ;
  }
  [@@deriving json_encoding]

  type result = {
    signed: string ;
    signature: string ;
  }
  [@@deriving json_encoding]

  let f = Tc.f "sign" ~params_enc ~result_enc

end

module VerifySignature = struct

  type params = {
    signed: string ;
    public: string ;
  }
  [@@deriving json_encoding]

  type result = {
    unsigned: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "verify_signature" ~params_enc ~result_enc

end

module TypesOfHash = struct
  type params = {
    data: string
  }
  [@@deriving json_encoding]

  type result = {
    hash: string
  }
  [@@deriving json_encoding]
end

module Sha256 = struct
  include TypesOfHash
  let f = Tc.f "sha256" ~params_enc ~result_enc
end

module Sha512 = struct
  include TypesOfHash
  let f = Tc.f "sha512" ~params_enc ~result_enc
end

module Scrypt = struct

  type params = {
    password: string ;
    salt: string ;
    log_n: number ;
    r: number ;
    p: number ;
    dk_len: number ;
  }
  [@@deriving json_encoding]

  type result = {
    key: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "scrypt" ~params_enc ~result_enc
end

module NaclSignKeyPairFromSecret = struct
  type params = {
    secret: string
  }
  [@@deriving json_encoding]

  type result = KeyPair.t
  [@@deriving json_encoding]


  let f = Tc.f "nacl_sign_keypair_from_secret_key" ~params_enc ~result_enc
end

module NaclSign = struct

  type params = {
    unsigned: string ;
    secret: string ;
  }
  [@@deriving json_encoding]

  type result = {
    signed: string
  }
  [@@deriving json_encoding]


  let f = Tc.f "nacl_sign" ~params_enc ~result_enc
end

module NaclSignOpen = struct

  type params = {
    signed: string ;
    public: string ;
  }
  [@@deriving json_encoding]

  type result = {
    unsigned: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_sign_open" ~params_enc ~result_enc
end

module NaclSignDetached = struct
  type params = {
    unsigned: string ;
    secret: string ;
  }
  [@@deriving json_encoding]

  type result = {
    signature: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_sign_detached" ~params_enc ~result_enc
end

module NaclSignDetachedVerify = struct

  type params = {
    unsigned: string ;
    signature: string ;
    public: string ;
  }
  [@@deriving json_encoding]

  type result = {
    succeeded: bool
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_sign_detached_verify" ~params_enc ~result_enc
end

module NaclBoxKeyPair = struct

  type params = unit
  [@@deriving json_encoding]

  type result = KeyPair.t
  [@@deriving json_encoding]

  let f = Tc.f "nacl_box_keypair" ~params_enc ~result_enc
end

module NaclBoxKeyPairFromSecret = struct
  type params = {
    secret: string
  }
  [@@deriving json_encoding]

  type result = KeyPair.t
  [@@deriving json_encoding]

  let f = Tc.f "nacl_box_keypair_from_secret_key" ~params_enc ~result_enc
end

module NaclBox = struct
  type params = {
    decrypted: string ;
    nonce: string ;
    their_public: string ;
    secret: string ;
  }
  [@@deriving json_encoding]

  type result = {
    encrypted: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_box" ~params_enc ~result_enc
end

module NaclBoxOpen = struct

  type params = {
    encrypted: string ;
    nonce: string ;
    their_public: string ;
    secret: string ;
  }
  [@@deriving json_encoding]

  type result = {
    decrypted: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_box_open" ~params_enc ~result_enc
end

module NaclSecretBox = struct
  type params = {
    decrypted: string ;
    nonce: string ;
    key: string ;
  }
  [@@deriving json_encoding]

  type result = {
    encrypted: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_box_open" ~params_enc ~result_enc
end

module NaclSecretBoxOpen = struct

  type params = {
    encrypted: string ;
    nonce: string ;
    key: string ;
  }
  [@@deriving json_encoding]

  type result = {
    decrypted: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "nacl_secret_box_open" ~params_enc ~result_enc
end

module MnemonicWords = struct
  type params = {
    dictionary: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    words: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "mnemonic_words" ~params_enc ~result_enc
end

module MnemonicFromRandom = struct

  type params = {
    dictionary: number option ; [@opt None]
    word_count: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    phrase: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "mnemonic_from_random" ~params_enc ~result_enc
end

module MnemonicFromEntropy = struct

  type params = {
    entropy: string ;
    dictionary: number option ; [@opt None]
    word_count: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    phrase: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "mnemonic_from_entropy" ~params_enc ~result_enc
end

module MnemonicVerify = struct

  type params = {
    phrase: string ;
    dictionary: number option ; [@opt None]
    word_count: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    valid: bool
  }
  [@@deriving json_encoding]

  let f = Tc.f "mnemonic_verify" ~params_enc ~result_enc
end

module MnemonicDeriveSignKeys = struct

  type params = {
    phrase: string ;
    path: string option ; [@opt None]
    dictionary: number option ; [@opt None]
    word_count: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = KeyPair.t
  [@@deriving json_encoding]

  let f = Tc.f "mnemonic_derive_sign_keys" ~params_enc ~result_enc
end

module HDKeyXPrvFromMnemonic = struct

  type params = {
    phrase: string ;
    dictionary: number option ; [@opt None]
    word_count: number option ; [@opt None]
  }
  [@@deriving json_encoding]

  type result = {
    xprv: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "hdkey_xprv_from_mnemonic" ~params_enc ~result_enc
end

module HDKeyDeriveFromXPrv = struct

  type params = {
    xprv: string ;
    child_index: number ;
    hardened: bool ;
  }
  [@@deriving json_encoding]

  type result = {
    xprv: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "hdkey_derive_from_xprv" ~params_enc ~result_enc
end

module HDKeyDeriveFromXPrvPath = struct

  type params = {
    xprv: string ;
    path: string ;
  }
  [@@deriving json_encoding]

  type result = {
    xprv: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "hdkey_derive_from_xprv_path" ~params_enc ~result_enc
end

module HDKeySecretFromXPrv = struct

  type params = {
    xprv: string
  }
  [@@deriving json_encoding]

  type result = {
    secret: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "hdkey_secret_from_xprv" ~params_enc ~result_enc
end

module HDKeyPublicFromXPrv = struct

  type params = {
    xprv: string
  }
  [@@deriving json_encoding]

  type result = {
    public: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "hdkey_public_from_xprv" ~params_enc ~result_enc
end

module Chacha20 = struct
  type params = {
    data: string ;
    key: string ;
    nonce: string ;
  }
  [@@deriving json_encoding]

  type result = {
    data: string
  }
  [@@deriving json_encoding]

  let f = Tc.f "chacha20" ~params_enc ~result_enc
end

(* TODO:

register_signing_box – Register an application implemented signing box.

get_signing_box – Creates a default signing box implementation.

signing_box_get_public_key – Returns public key of signing key pair.

signing_box_sign – Returns signed user data.

remove_signing_box – Removes signing box from SDK.

register_encryption_box – Register an application implemented encryption box.

remove_encryption_box – Removes encryption box from SDK

encryption_box_get_info – Queries info from the given encryption box

encryption_box_encrypt – Encrypts data using given encryption box

encryption_box_decrypt – Decrypts data using given encryption box
*)

let factorize = Tc.request Factorize.f
let modular_power = Tc.request ModularPower.f
let ton_crc16 = Tc.request TonCrc16.f
let generate_random_bytes = Tc.request GenerateRandomBytes.f
let convert_public_key_to_ton_safe_format =
  Tc.request ConvertPublicKeyToTonSafeFormat.f
let generate_random_sign_keys =
  Tc.request GenerateRandomSignKeys.f
let sign = Tc.request Sign.f
let verify_signature = Tc.request VerifySignature.f
let sha256 = Tc.request Sha256.f
let sha512 = Tc.request Sha512.f
let scrypt = Tc.request Scrypt.f
let nacl_sign_keypair_from_secret_key =
  Tc.request NaclSignKeyPairFromSecret.f
let nacl_sign = Tc.request NaclSign.f
let nacl_sign_open = Tc.request NaclSignOpen.f
let nacl_sign_detached = Tc.request NaclSignDetached.f
let nacl_sign_detached_verify = Tc.request NaclSignDetachedVerify.f
let nacl_box_keypair = Tc.request NaclBoxKeyPair.f
let nacl_box_keypair_from_secret_key =
  Tc.request NaclBoxKeyPairFromSecret.f
let nacl_box =  Tc.request NaclBox.f
let nacl_box_open =  Tc.request NaclBoxOpen.f
let nacl_secret_box =  Tc.request NaclSecretBox.f
let nacl_secret_box_open =  Tc.request NaclSecretBoxOpen.f
let mnemonic_words =  Tc.request MnemonicWords.f
let mnemonic_from_random =  Tc.request MnemonicFromRandom.f
let mnemonic_from_entropy =  Tc.request MnemonicFromEntropy.f
let mnemonic_verify =  Tc.request MnemonicVerify.f
let mnemonic_derive_sign_keys =  Tc.request MnemonicDeriveSignKeys.f
let hdkey_xprv_from_mnemonic = Tc.request HDKeyXPrvFromMnemonic.f
let hdkey_derive_from_xprv = Tc.request HDKeyDeriveFromXPrv.f
let hdkey_derive_from_xprv_path = Tc.request HDKeyDeriveFromXPrvPath.f
let hdkey_secret_from_xprv = Tc.request HDKeySecretFromXPrv.f
let hdkey_public_from_xprv = Tc.request HDKeyPublicFromXPrv.f
let chacha20 = Tc.request Chacha20.f
