/**************************************************************************/
/*                                                                        */
/*  Copyright (c) 2021 OCamlPro SAS & TON Labs                            */
/*                                                                        */
/*  All rights reserved.                                                  */
/*  This file is distributed under the terms of the GNU Lesser General    */
/*  Public License version 2.1, with the special exception on linking     */
/*  described in the LICENSE.md file in the root directory.               */
/*                                                                        */
/*                                                                        */
/**************************************************************************/

use crate::ocp;
use crate::types;

use crate::client::{create_client_local, WORD_COUNT, HD_PATH};

use ton_client::crypto::{
    KeyPair,
    mnemonic_from_random,
    hdkey_xprv_from_mnemonic,
    hdkey_secret_from_xprv,
    nacl_sign_keypair_from_secret_key,
    hdkey_derive_from_xprv_path,
    ParamsOfHDKeySecretFromXPrv,
    ParamsOfHDKeyDeriveFromXPrvPath,
    ParamsOfHDKeyXPrvFromMnemonic,
    ParamsOfNaclSignKeyPairFromSecret,
    ParamsOfMnemonicFromRandom
};

pub fn generate_mnemonic_rs() -> Result<String, ocp::Error > {
    let client = create_client_local()?;
    let r = mnemonic_from_random(
        client,
        ParamsOfMnemonicFromRandom {
            dictionary: Some(1),
            word_count: Some(WORD_COUNT),
        },
    )
        .map_err(|e|
                 ocp::error(ocp::ERROR_MNEMONIC_FROM_RANDOM,
                             format!("{:#}", e)))?;
    Ok(r.phrase)
}


// pub const HD_PATH: &str = "m/44'/396'/0'/0/0";

pub fn generate_keypair_from_mnemonic_rs
    (mnemonic: &str, hd_path: Option<String>) -> Result<types::KeyPair, ocp::Error> {
    let client = create_client_local()?;
    let hdk_master = hdkey_xprv_from_mnemonic(
        client.clone(),
        ParamsOfHDKeyXPrvFromMnemonic {
            dictionary: Some(1),
            word_count: Some(WORD_COUNT),
            phrase: mnemonic.to_string(),
        },
    ).map_err(|e|
              ocp::error(ocp::ERROR_HDKEY_FROM_MNEMONIC_FAILED,
                         format!("{:#}", e)))?;

    let hd_path =
       if let Some(hd_path) = hd_path { hd_path }
        else { HD_PATH.to_string() };
    let hdk_root = hdkey_derive_from_xprv_path(
        client.clone(),
        ParamsOfHDKeyDeriveFromXPrvPath {
            xprv: hdk_master.xprv,
            path: hd_path
        },
    ).map_err(|e|
              ocp::error(
                  ocp::ERROR_DERIVE_KEY_FAILED,
                  format!("{:#}", e)))?;

    let secret = hdkey_secret_from_xprv(
        client.clone(),
        ParamsOfHDKeySecretFromXPrv {
            xprv: hdk_root.xprv,
        },
    ).map_err(|e|
              ocp::error(
                  ocp::ERROR_SECRET_KEY_FAILED,
                  format!("{:#}", e)))?;

    let mut keypair: KeyPair = nacl_sign_keypair_from_secret_key(
        client.clone(),
        ParamsOfNaclSignKeyPairFromSecret {
            secret: secret.secret,
        },
    ).map_err(|e|
              ocp::error(
                  ocp::ERROR_KEYPAIR_OF_SECRET_FAILED,
                  format!("{:#}", e)))?;

    // special case if secret contains public key too.
    let secret = hex::decode(&keypair.secret).unwrap();
    if secret.len() > 32 {
        keypair.secret = hex::encode(&secret[..32]);
    }
    Ok(types::ocaml_of_keypair(keypair))
}

