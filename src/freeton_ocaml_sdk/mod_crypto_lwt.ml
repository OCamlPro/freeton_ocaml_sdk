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
include Ton_client.CRYPTO

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
