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

include Ton_client.CRYPTO

let factorize = Tc_lwt.request Factorize.f
let modular_power = Tc_lwt.request ModularPower.f
let ton_crc16 = Tc_lwt.request TonCrc16.f
let generate_random_bytes = Tc_lwt.request GenerateRandomBytes.f
let convert_public_key_to_ton_safe_format =
  Tc_lwt.request ConvertPublicKeyToTonSafeFormat.f
let generate_random_sign_keys =
  Tc_lwt.request GenerateRandomSignKeys.f
let sign = Tc_lwt.request Sign.f
let verify_signature = Tc_lwt.request VerifySignature.f
let sha256 = Tc_lwt.request Sha256.f
let sha512 = Tc_lwt.request Sha512.f
let scrypt = Tc_lwt.request Scrypt.f
let nacl_sign_keypair_from_secret_key =
  Tc_lwt.request NaclSignKeyPairFromSecret.f
let nacl_sign = Tc_lwt.request NaclSign.f
let nacl_sign_open = Tc_lwt.request NaclSignOpen.f
let nacl_sign_detached = Tc_lwt.request NaclSignDetached.f
let nacl_sign_detached_verify = Tc_lwt.request NaclSignDetachedVerify.f
let nacl_box_keypair = Tc_lwt.request NaclBoxKeyPair.f
let nacl_box_keypair_from_secret_key =
  Tc_lwt.request NaclBoxKeyPairFromSecret.f
let nacl_box =  Tc_lwt.request NaclBox.f
let nacl_box_open =  Tc_lwt.request NaclBoxOpen.f
let nacl_secret_box =  Tc_lwt.request NaclSecretBox.f
let nacl_secret_box_open =  Tc_lwt.request NaclSecretBoxOpen.f
let mnemonic_words =  Tc_lwt.request MnemonicWords.f
let mnemonic_from_random =  Tc_lwt.request MnemonicFromRandom.f
let mnemonic_from_entropy =  Tc_lwt.request MnemonicFromEntropy.f
let mnemonic_verify =  Tc_lwt.request MnemonicVerify.f
let mnemonic_derive_sign_keys =  Tc_lwt.request MnemonicDeriveSignKeys.f
let hdkey_xprv_from_mnemonic = Tc_lwt.request HDKeyXPrvFromMnemonic.f
let hdkey_derive_from_xprv = Tc_lwt.request HDKeyDeriveFromXPrv.f
let hdkey_derive_from_xprv_path = Tc_lwt.request HDKeyDeriveFromXPrvPath.f
let hdkey_secret_from_xprv = Tc_lwt.request HDKeySecretFromXPrv.f
let hdkey_public_from_xprv = Tc_lwt.request HDKeyPublicFromXPrv.f
let chacha20 = Tc_lwt.request Chacha20.f
