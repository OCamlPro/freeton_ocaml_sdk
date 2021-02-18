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

pub fn create_client_local() -> Result<TonClient, ocaml::Error> {
    let cli = ClientContext::new(ClientConfig::default())
        .map_err(|_e|
                 failwith(
                     "failed to create tonclient"))?;
    Ok(Arc::new(cli))
}

pub const HD_PATH: &str = "m/44'/396'/0'/0/0";
pub const WORD_COUNT: u8 = 12;

#[ocaml::func]
pub fn gen_seed_phrase() -> Result<String, ocaml::Error> {
    let client = create_client_local()?;
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
