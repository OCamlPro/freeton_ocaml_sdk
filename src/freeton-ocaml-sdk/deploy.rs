/*
 * Copyright 2018-2020 TON DEV SOLUTIONS LTD.
 *
 * Licensed under the SOFTWARE EVALUATION License (the "License"); you may not use
 * this file except in compliance with the License.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific TON DEV software governing permissions and
 * limitations under the License.
 */

/*
use crate::helpers::{create_client_verbose, load_abi, calc_acc_address};
use crate::config::Config;
use crate::crypto::load_keypair;
 */
//use ton_client::{ClientConfig, ClientContext};
use ton_client::abi::{Abi, AbiContract};
use crate::client::{create_client, create_client_local, ocaml_error};
use ton_client::processing::{ParamsOfProcessMessage};
use ton_client::abi::{Signer, CallSet, DeploySet, ParamsOfEncodeMessage};
use ton_client::crypto::KeyPair;

pub fn load_abi(abi: &str) -> Result<Abi, String> {
    Ok(Abi::Contract(
        serde_json::from_str::<AbiContract>(abi)
            .map_err(|e| format!("ABI is not a valid json: {}", e))?,
    ))
}

pub fn read_keys(filename: &str) -> Result<KeyPair, String> {
    let keys_str = std::fs::read_to_string(filename)
        .map_err(|e| format!("failed to read keypair file: {}", e.to_string()))?;
    let keys: KeyPair = serde_json::from_str(&keys_str).unwrap();
    Ok(keys)
}
pub async fn calc_acc_address(
    tvc: &[u8],
    wc: i32,
    pubkey: String,
    init_data: Option<&str>,
    abi: Abi,
) -> Result<String, String> {
    let ton = create_client_local()?;

    let init_data_json = init_data
        .map(|d| serde_json::from_str(d))
        .transpose()
        .map_err(|e| format!("initial data is not in json: {}", e))?;

    let dset = DeploySet {
        tvc: base64::encode(tvc),
        workchain_id: Some(wc),
        initial_data: init_data_json,
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
    .map_err(|e| format!("cannot generate address: {}", e))?;
    Ok(result.address)
}

pub async fn deploy_contract(
    server_url: String,
    tvc: &str,
    abi: &str,
    params: &str,
    keys_file: &str,
    wc: i32) -> Result<String, String> {
    let ton = create_client(server_url)?;

    let abi = std::fs::read_to_string(abi)
        .map_err(|e| format!("failed to read ABI file: {}", e))?;
    let abi = load_abi(&abi)?;

    let keys = read_keys(&keys_file)?;

    let tvc_bytes = &std::fs::read(tvc)
        .map_err(|e| format!("failed to read smart contract file: {}", e))?;

    let tvc_base64 = base64::encode(&tvc_bytes);

    let addr = calc_acc_address(
        &tvc_bytes,
        wc,
        keys.public.clone(),
        None,
        abi.clone()
    ).await?;

    println!("Deploying...");
    let dset = DeploySet {
        tvc: tvc_base64,
        workchain_id: Some(wc),
        initial_data: None,
        initial_pubkey: None,
    };
    let params = serde_json::from_str(&params)
        .map_err(|e| format!("function arguments is not a json: {}", e))?;

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
    .map_err(|e| format!("deploy failed: {:#}", e))?;

    println!("Transaction succeeded.");
    println!("Contract deployed at address: {}", addr);
    Ok(addr)
}

use futures::executor::block_on;
#[ocaml::func]
pub fn deploy_contract_ml(
    args: Vec<String>,
    wc: i16) -> Result<String, ocaml::Error> {

    ocaml_error(block_on(
        deploy_contract(args[0].clone(),
                        &args[1],
                        &args[2],
                        &args[3],
                        &args[4], wc as i32)))
}
