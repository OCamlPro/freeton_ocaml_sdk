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
use crate::types::{TonClient};
use crate::client::{create_client_local};

use ton_client::abi::{Abi, AbiContract};
use ton_client::processing::{ParamsOfProcessMessage};
use ton_client::abi::{Signer, CallSet, DeploySet, ParamsOfEncodeMessage};

pub fn load_abi(abi: &str) -> Result<Abi, ocp::Error> {
//    eprintln!("load_abi({})", abi);
    Ok(Abi::Contract(
        serde_json::from_str::<AbiContract>(abi)
            .map_err(|e| ocp::error(
                ocp::ERROR_INVALID_JSON_ABI,
                format!("{:#}", e)))?,
    ))
}

/*
pub fn read_keys(filename: &str) -> Result<KeyPair, ocp::Error> {
    let keys_str = std::fs::read_to_string(filename)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_CANNOT_READ_KEYPAIR_FILE,
                     format!("{:#}", e.to_string())))?;
    let keys: KeyPair = serde_json::from_str(&keys_str).unwrap();
    Ok(keys)
}
 */

pub async fn calc_acc_address(
    tvc: &[u8],
    wc: i32,
    pubkey: String,
    init_data_json: Option<serde_json::Value>,
    initial_pubkey: Option<String>,
    abi: Abi,
) -> Result<String, ocp::Error> {
    let ton = create_client_local()?;

    let dset = DeploySet {
        tvc: base64::encode(tvc),
        workchain_id: Some(wc),
        initial_data: init_data_json,
        initial_pubkey: initial_pubkey,
        ..Default::default()
    };
    let result = ton_client::abi::encode_message(
        ton.clone(),
        ParamsOfEncodeMessage {
            abi,
            address: None,
            deploy_set: Some(dset),
            call_set: None,
            signer: Signer::External {
                public_key: pubkey,
            },
            processing_try_index: None,
        },
    )
    .await
        .map_err(|e|
                 ocp::error(ocp::ERROR_GENERATE_ADDRESS_FAILED,
                            format!("{:#}", e)))?;
    Ok(result.address)
}

pub async fn deploy_contract_rs(
    ton: TonClient,
    tvc: &str,
    abi: &str,
    params: &str,
    keys: ton_client::crypto::KeyPair,
    initial_data: String,
    initial_pubkey: String,
    wc: i32) -> Result<String, ocp::Error> {
    let abi = load_abi(&abi)?;

    let tvc_bytes = &std::fs::read(tvc)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_READ_TVC_FAILED,
                     format!("{:#}", e)))?;

    let tvc_base64 = base64::encode(&tvc_bytes);

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

    let params = serde_json::from_str(&params)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_INVALID_JSON_PARAMS,
                     format!("{:#}", e)))?;
    
    let addr = calc_acc_address(
        &tvc_bytes,
        wc,
        keys.public.clone(),
        initial_data_json.clone(),
        initial_pubkey.clone(),
        abi.clone()
    ).await?;

    let dset = DeploySet {
        tvc: tvc_base64,
        workchain_id: Some(wc),
        initial_data: initial_data_json,
        initial_pubkey: initial_pubkey
    };

    let callback = |_event| { async move { } };
    ton_client::processing::process_message(
        ton.clone(),
        ParamsOfProcessMessage {
            message_encode_params: ParamsOfEncodeMessage {
                abi,
                address: Some(addr.clone()),
                deploy_set: Some(dset),
                call_set: CallSet::some_with_function_and_input("constructor", params),
                signer: Signer::Keys{ keys },
                processing_try_index: None,
            },
            send_events: true,
        },
        callback,
    ).await
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_DEPLOY_FAILED,
                     format!("{:#}", e)))?;
    Ok(addr)
}

