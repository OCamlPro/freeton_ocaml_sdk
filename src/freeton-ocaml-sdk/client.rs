/* BEGIN from tonos-cli */

/*
use crate::config::Config;
use log;
*/
use std::sync::Arc;
/*
use std::time::SystemTime;
use ton_client::abi::{
    Abi, AbiConfig, AbiContract, DecodedMessageBody,
    DeploySet, ParamsOfDecodeMessageBody,
    ParamsOfEncodeMessage, Signer,
};
 */
use ton_client::abi::{AbiConfig};
use ton_client::crypto::{CryptoConfig};

use ton_client::crypto::{
    mnemonic_from_random,ParamsOfMnemonicFromRandom,
    // CryptoConfig, KeyPair
};
// use ton_client::error::ClientError;
//use ton_client::net::{query_collection, OrderBy, ParamsOfQueryCollection};
use ton_client::{ClientConfig, ClientContext};
//use ocaml::Error::Caml;
//use ocaml::CamlError;
//use ocaml::Value;

pub type TonClient = Arc<ClientContext>;

// BEGIN ocaml utils
pub fn failwith(s: &'static str) -> ocaml::Error {
        ocaml::Error::Caml(ocaml::CamlError::Failure(s)).into()
    }
// END ocaml utils

pub fn create_client_local() -> Result<TonClient, String> {
    let cli = ClientContext::new(ClientConfig::default())
        .map_err(|_e|
                 "failed to create tonclient")?;
    Ok(Arc::new(cli))
}

pub const HD_PATH: &str = "m/44'/396'/0'/0/0";
pub const WORD_COUNT: u8 = 12;

pub fn create_client(server_url: String) -> Result<TonClient, String> {
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
        ClientContext::new(cli_conf).map_err(|e| format!("failed to create tonclient: {}", e))?;
    Ok(Arc::new(cli))
}

pub fn ocaml_error<E>(r : Result<E, String> ) -> Result<E, ocaml::Error> {
    match r {
        Ok(x) => Ok(x),
        Err (_) => Err(failwith("Error"))
    }
}

#[ocaml::func]
pub fn gen_seed_phrase() -> Result<String, ocaml::Error> {
    let client = ocaml_error ( create_client_local() )?;
    mnemonic_from_random(
        client,
        ParamsOfMnemonicFromRandom {
            dictionary: Some(1),
            word_count: Some(WORD_COUNT),
        },
    )
    .map_err(|_e| failwith("An error"))
    .map(|r| r.phrase)
}
/* END from tonos-cli::crypto */

#[ocaml::func]
pub fn hello_world() -> &'static str {
    "hello, world!"
}


/*
// Address of giver on TON OS SE
const giverAddress = '0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94';
// Giver ABI on TON OS SE
const giverAbi = {
    'ABI version': 1,
    functions: [{
            name: 'constructor',
            inputs: [],
            outputs: []
        }, {
            name: 'sendGrams',
            inputs: [
                { name: 'dest', type: 'address' },
                { name: 'amount', type: 'uint64' }
            ],
            outputs: []
        }],
    events: [],
    data: []
};
 */

use ton_client::{
    tc_create_context,
    tc_destroy_context,
    tc_destroy_string,
    tc_read_string,
    tc_request_sync,
    ContextHandle,
    StringData,
};
//use ton_client::serde_json;
use serde::de::DeserializeOwned;
use serde_json::{Value};

pub fn parse_sync_response<R: DeserializeOwned>(response: *const String) -> Result<R, ocaml::Error> {
    let response = unsafe {
        let result = tc_read_string(response).to_string();
        tc_destroy_string(response);
        result
    };
    match serde_json::from_str::<Value>(&response) {
        Ok(value) => {
            if value["error"].is_object() {
                println!("Error1");
                Err(failwith("Function failed"))
            } else {
                Ok(serde_json::from_value(value["result"].clone()).unwrap())
            }
        }
        Err(err) => {
            println!("Error2:{}", err);
            Err(failwith("Read core response failed"))
        }
    }
}

#[ocaml::func]
pub fn ton_client_request(
    network: String,
    function: String,
    parameters: String)
    -> Result<String, ocaml::Error>
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
        Err(_err) => {
            Err(failwith("Req failed"))
        }
    };
    result
}

/*
//use crate::encoding::{account_decode, account_encode_ex, AccountAddressType, Base64AddressParams};
use ton_client::serde_json::{json};
use ton_client::serde_json::{Value};
use ton_block::MsgAddressInt;
use std::str::FromStr;
//use crate::error::{ClientError};
//use crate::tests::TestClient;


#[ocaml::func]
pub fn test_wallet_deploy(
    WALLET_ABI: String) {
    let client = TestClient::new();
    let version = client.request_json("version", Value::Null).unwrap();
    println!("result: {}", version.to_string());

    let keys = client.request_json("crypto.ed25519.keypair", json!({})).unwrap();

    let abi: Value = serde_json::from_str(WALLET_ABI).unwrap();

    let address = client.request_json("contracts.deploy.message",
        json!({
                "abi": abi.clone(),
                "constructorParams": json!({}),
                "imageBase64": WALLET_CODE_BASE64,
                "keyPair": keys,
                "workchainId": 0,
            }),
    ).unwrap();

    let address = address["address"].clone();
    let address = MsgAddressInt::from_str(address.as_str().unwrap()).unwrap();

    let giver_abi: Value = serde_json::from_str(GIVER_ABI).unwrap();

    let _ = client.request_json("contracts.run",
        json!({
                "address": GIVER_ADDRESS,
                "abi": giver_abi,
                "functionName": "sendGrams",
                "input": &json!({
                                        "dest": address.to_string(),
                                        "amount": 10_000_000_000u64
                                        }),
            }),
    ).unwrap();

    let _ = client.request_json("net.wait.for",
        json!({
                "table": "accounts".to_owned(),
                "filter": json!({
                                        "id": { "eq": address.to_string() },
                                        "balance": { "gt": "0" }
                                }).to_string(),
                                "result": "id balance".to_owned()
            }),
    ).unwrap();

    let deployed = client.request_map("contracts.deploy",
        json!({
                "abi": abi.clone(),
                "constructorParams": json!({}),
                "imageBase64": WALLET_CODE_BASE64,
                "keyPair": keys,
                "workchainId": 0,
            }),
    );

    assert_eq!(deployed["address"], address.to_string());
    assert_eq!(deployed["alreadyDeployed"], false);

    let result = client.request_map("contracts.run",
        json!({
                "address": address.to_string(),
                "abi": abi.clone(),
                "functionName": "createOperationLimit",
                "input": json!({
                                        "value": 123
                                }),
                "keyPair": keys,
            }),
    );
    assert_eq!(result["output"]["value0"], "0x0");
}
*/

/*
pub fn play_with_ton(node_address: String) {
    println!("Network address {}", node_address);
    let ton_client = TonClient::new_with_base_url(&node_address).unwrap();

    let keys = ton_client.crypto.generate_ed25519_keys().expect("Couldn't create key pair");
    println!("Generated keys:\\n{}\\n{}", keys.secret, keys.public);

    let code = std::fs::read("hello.tvc").expect("Couldn't read code file");
    let abi = std::fs::read_to_string("hello.abi.json").expect("Couldn't read ABI file");

    let address = ton_client.contracts.get_deploy_address(
        abi.to_string().into(), &code, None, &keys.public, 0
    ).expect("Couldn't calculate address");

    println!("Hello contract was deployed at address: {}", address);
    let result = ton_client.contracts.deploy(
        abi.to_string().into(),
        &code,
        None, "{}".into(),
        None, 
        &keys,
        0)
        .expect("Couldn't deploy contract");
    println!("Hello contract was deployed at address: {}", result.address);

    let response = ton_client.contracts.run(
        &address,
        abi.to_string().into(),
        "sayHello",
        None,
        "{}".into(),
        Some(&keys)
    )
        .expect("Couldn't run contract");
    println!("Hello contract was responded to sayHello: {}", response.output);
}

*/
