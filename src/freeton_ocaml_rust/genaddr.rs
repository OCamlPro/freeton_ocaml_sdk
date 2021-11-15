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
//use crate::client::{create_client, create_client_local};
use crate::deploy::{calc_acc_address, load_abi};

/*
use ton_client::config::Config;
use ton_clientcrate::helpers::{calc_acc_address};
use ed25519_dalek::PublicKey;
use std::fs::OpenOptions;
use ton_sdk;
use ton_client::crypto::{gen_seed_phrase, generate_keypair_from_mnemonic};
use ton_client::utils::{convert_address, ParamsOfConvertAddress, AddressStringFormat};
 */

pub async fn generate_address_rs(
    tvc: &str,
    abi: &str,
    wc: i32,
    pubkey: String,
    initial_data: String,
    initial_pubkey: String,
) -> Result<String, ocp::Error> {

    let contract = std::fs::read(tvc)
        .map_err(|e|
                 ocp::error(ocp::ERROR_READ_TVC_FAILED,
                     format!("{:#}", e)))?;

    let abi = load_abi(&abi)?;

    let initial_data =
        if initial_data == "" { None } else { Some (&*initial_data) };

    let initial_data_json = initial_data
        .map(|d| serde_json::from_str(d))
        .transpose()
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_INVALID_JSON_INITIAL_DATA,
                     format!("{:#}", e)))?;

    let initial_pubkey =
        if initial_pubkey == "" { None } else { Some (initial_pubkey) };
    
    let result = calc_acc_address(
        &contract,
        wc,
        pubkey,
        initial_data_json.clone(),
        initial_pubkey.clone(),
        abi.clone()
    ).await?;

    Ok(result)

    /*
    eprintln!();
    if let Some(phr) = phrase {
        eprintln!(r#"Seed phrase: "{}""#, phr);
        eprintln!();
    }
    eprintln!("Raw address: {}", addr);
    if update_tvc {
        let initial_data = initial_data.map(|s| s.to_string());
        let key_bytes = hex::decode(&keys.public).unwrap();
        update_contract_state(tvc, &key_bytes, initial_data, &abi_str)?;
    }
    
    if new_keys && keys_file.is_some() {
        let keys_json = serde_json::to_string_pretty(&keys).unwrap();
        std::fs::write(keys_file.unwrap(), &keys_json).unwrap();
    }
    
    
    eprintln!("testnet:");
    eprintln!("Non-bounceable address (for init): {}", calc_userfriendly_address(&addr, false, true)?);
    eprintln!("Bounceable address (for later access): {}", calc_userfriendly_address(&addr, true, true)?);
    eprintln!("mainnet:");
    eprintln!("Non-bounceable address (for init): {}", calc_userfriendly_address(&addr, false, false)?);
    eprintln!("Bounceable address (for later access): {}", calc_userfriendly_address(&addr, true, false)?);

    eprintln!("Succeeded");
    Ok(())
      */  
}

/*
fn calc_userfriendly_address(address: &str, bounce: bool, test: bool) -> Result<String, String> {
    convert_address(
        create_client_local().unwrap(),
        ParamsOfConvertAddress {
            address: address.to_owned(),
            output_format: AddressStringFormat::Base64{ url: true, bounce, test },
        }
    )
    .map(|r| r.address)
    .map_err(|e| format!("failed to convert address to base64 form: {}", e))
}

*/


use ed25519_dalek::PublicKey;
use std::fs::OpenOptions;

pub fn update_contract_state_rs(tvc_file: &str,
                                pubkey: &str,
                                data: Option<String>,
                                abi: &str) -> Result<(), ocp::Error> {
    use std::io::{Seek, Write};
    let pubkey = hex::decode(&pubkey).unwrap();
    let mut state_init = OpenOptions::new().read(true).write(true).open(tvc_file)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_READ_TVC_FAILED,
                     format!("{:#}", e)))?;

    let pubkey_object = PublicKey::from_bytes(&pubkey)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_PARSE_PUBKEY_FAILED,
                     format!("{:#}", e)))?;

    let mut contract_image = ton_sdk::ContractImage::from_state_init_and_key(&mut state_init, &pubkey_object)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_LOAD_CONTRACT_IMAGE_FAILED,
                     format!("{:#}", e)))?;
    
    if data.is_some() {
        contract_image.update_data(&data.unwrap(), abi)
            .map_err(|e|
                     ocp::error(
                         ocp::ERROR_UPDATE_CONTRACT_IMAGE_FAILED,
                         format!("{:#}", e)))?;
    }

    let vec_bytes = contract_image.serialize()
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_WRITE_TVC_FILE,
                     format!("{:#}", e)))?;

    state_init.seek(std::io::SeekFrom::Start(0)).unwrap();
    state_init.write_all(&vec_bytes).unwrap();
    eprintln!("TVC file updated");

    Ok(())
}
