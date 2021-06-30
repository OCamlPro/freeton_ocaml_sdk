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

(* open Ton_types *)

(* TODO:

factorize – Integer factorization

modular_power – Modular exponentiation

ton_crc16 – Calculates CRC16 using TON algorithm.

generate_random_bytes – Generates random byte array of the specified length and returns it in base64 format

convert_public_key_to_ton_safe_format – Converts public key to ton safe_format

generate_random_sign_keys – Generates random ed25519 key pair.

sign – Signs a data using the provided keys.

verify_signature – Verifies signed data using the provided public key. Raises error if verification is failed.

sha256 – Calculates SHA256 hash of the specified data.

sha512 – Calculates SHA512 hash of the specified data.

scrypt – Perform scrypt encryption

nacl_sign_keypair_from_secret_key – Generates a key pair for signing from the secret key

nacl_sign – Signs data using the signer's secret key.

nacl_sign_open – Verifies the signature and returns the unsigned message

nacl_sign_detached – Signs the message using the secret key and returns a signature.

nacl_sign_detached_verify – Verifies the signature with public key and unsigned data.

nacl_box_keypair – Generates a random NaCl key pair

nacl_box_keypair_from_secret_key – Generates key pair from a secret key

nacl_box – Public key authenticated encryption

nacl_box_open – Decrypt and verify the cipher text using the receivers secret key, the senders public key, and the nonce.

nacl_secret_box – Encrypt and authenticate message using nonce and secret key.

nacl_secret_box_open – Decrypts and verifies cipher text using nonce and secret key.

mnemonic_words – Prints the list of words from the specified dictionary

mnemonic_from_random – Generates a random mnemonic

mnemonic_from_entropy – Generates mnemonic from pre-generated entropy

mnemonic_verify – Validates a mnemonic phrase

mnemonic_derive_sign_keys – Derives a key pair for signing from the seed phrase

hdkey_xprv_from_mnemonic – Generates an extended master private key that will be the root for all the derived keys

hdkey_derive_from_xprv – Returns extended private key derived from the specified extended private key and child index

hdkey_derive_from_xprv_path – Derives the extended private key from the specified key and path

hdkey_secret_from_xprv – Extracts the private key from the serialized extended private key

hdkey_public_from_xprv – Extracts the public key from the serialized extended private key

chacha20 – Performs symmetric chacha20 encryption.

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
