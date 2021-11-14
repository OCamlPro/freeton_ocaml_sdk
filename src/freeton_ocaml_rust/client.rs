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

use std::sync::Arc;
use ton_client::abi::{AbiConfig};
use ton_client::crypto::{
    CryptoConfig,
};
use ton_client::{ClientConfig, ClientContext};

use ton_client::{
    tc_create_context,
    tc_destroy_context,
    tc_destroy_string,
    tc_read_string,
    tc_request_sync,
    ContextHandle,
    StringData,
};
use serde::de::DeserializeOwned;
use serde_json::{Value};

pub fn create_client_local() -> Result<TonClient, ocp::Error> {
    let cli = ClientContext::new(ClientConfig::default())
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_TONCLIENT_CREATE,
                     format!("{:#}", e)))?;
    Ok(Arc::new(cli))
}

pub const HD_PATH: &str = "m/44'/396'/0'/0/0";
pub const WORD_COUNT: u8 = 12;

pub fn create_client_rs(server_url: &str) -> Result<TonClient, ocp::Error> {
    let cli_conf = ClientConfig {
        abi: AbiConfig {
            workchain: 0,
            message_expiration_timeout: 60000,
            message_expiration_timeout_grow_factor: 1.3,
        },
        crypto: CryptoConfig {
            mnemonic_dictionary: 1,
            mnemonic_word_count: WORD_COUNT,
            hdkey_derivation_path: HD_PATH.to_string(),
        },
        network: ton_client::net::NetworkConfig {
            server_address: Some(server_url.to_owned()),
            network_retries_count: 3,
            message_retries_count: 5 as i8,
            message_processing_timeout: 30000,
            wait_for_timeout: 30000,
            out_of_sync_threshold: (60000 / 2), // timeout / 2
            max_reconnect_timeout: 1000,
            ..Default::default()
        },
        boc: Default::default(),
    };
    let cli =
        ClientContext::new(cli_conf)
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_TONCLIENT_CREATE,
                     format!("{:#}", e)))?;
    Ok(Arc::new(cli))
}



pub fn parse_sync_response<R: DeserializeOwned>(response: *const String)
                                                -> Result<R, ocp::Error> {
    let response = unsafe {
        let result = tc_read_string(response).to_string();
        tc_destroy_string(response);
        result
    };
    match serde_json::from_str::<Value>(&response) {
        Ok(value) => {
            if value["error"].is_object() {
                Err(
                    ocp::error( ocp::ERROR_REPLY_IS_ERROR,
                                format!("{:#}", value) )
                )
            } else {
                Ok(serde_json::from_value(value["result"].clone()).unwrap())
            }
        }
        Err(err) => {
            Err(
                ocp::error(ocp::ERROR_PARSE_REPLY_FAILED,
                    format!("{:#}", err) ))
        }
    }
}

pub fn ton_client_request_rs(
    network: String,
    function: String,
    parameters: String)
    -> Result<String, ocp::Error>
{
   let config = serde_json::json!({
        "network": {
            "server_address": network
        }
    });
    let context = unsafe {
        parse_sync_response::<ContextHandle>(tc_create_context(StringData::new(
            &config.to_string(),
        )))
    }?;

    let response = unsafe {
        parse_sync_response::<Value>(tc_request_sync(
            context,
            StringData::new(&function),
            StringData::new(&parameters),
        ))
    };
    unsafe { tc_destroy_context(context) };
    let result = match response {
        Ok(value) => {
            Ok(value.to_string())
        }
        Err(err) => Err(err)
    };
    result
}
