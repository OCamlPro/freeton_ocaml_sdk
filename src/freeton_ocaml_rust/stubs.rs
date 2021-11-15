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
use crate::types::{TonClientStruct, StateInitStruct};

#[ocaml::func]
pub fn generate_mnemonic_ml() -> ocp::Reply<String> {
    ocp::reply(crate::crypto::generate_mnemonic_rs())
}


#[ocaml::func]
pub fn ton_client_request_ml(
    network: String,
    function: String,
    parameters: String)
    -> ocp::Reply<String>
{
    ocp::reply(
        crate::client::ton_client_request_rs( network, function, parameters) )
}


#[ocaml::func]
pub fn deploy_contract_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    args: Vec<String>,
    keys: types::KeyPair,
    wc: i16) -> ocp::Reply<String> {
    
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::deploy::deploy_contract_rs(
            ton,
            &args[0],        // tvc
            &args[1],        // abi
            &args[2],        // params
            types::keypair_of_ocaml(keys),
            args[3].clone(),  // initial_data
            args[4].clone(),  // initial_pubkey
            wc as i32)
    )
}

#[ocaml::func]
pub fn generate_keypair_from_mnemonic_ml
    (mnemonic: String, path: Option<String>) -> ocp::Reply<types::KeyPair> {
    
    ocp::reply(
        crate::crypto::generate_keypair_from_mnemonic_rs(&mnemonic, path))
}

#[ocaml::func]
pub fn generate_address_ml(
    args: Vec<String>,
    wc: i16,
) -> ocp::Reply<String> {
    ocp::reply_async(
        crate::genaddr::generate_address_rs(
            &args[0], //   tvc
            &args[1], //   abi
            wc as i32,
            args[3].clone(), // pubkey
            args[2].clone(), //   initial_data 
            args[4].clone(), //   initial_pubkey
            ))
}

#[ocaml::func]
pub fn update_contract_state_ml( args: Vec<String> ) -> ocp::Reply<()> {
    let data = args[2].clone();
    let data =
        if data == "" { None } else { Some (data) };

    ocp::reply(
        crate::genaddr::update_contract_state_rs(
            &args[0], //   tvc_file
            &args[1], //   pubkey
            data, //   data
            &args[3], //   abi
            ))
}

#[ocaml::func]
pub fn parse_message_ml( msg : String ) -> ocp::Reply< String >
{
    ocp::reply_async(
        crate::boc::parse_message_rs( msg ) )
}


#[ocaml::func]
pub fn encode_body_ml( args: Vec<String> ) -> ocp::Reply<String> {
    ocp::reply_async(
        crate::call::encode_body_rs(
            &args[0], //   abi
            &args[1], //   meth
            &args[2], //   params
            ))
}

#[ocaml::func]
pub fn call_contract_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    args: Vec<String>,
    keys: Option<types::KeyPair>,
    local: bool) -> ocp::Reply<String> {
    let ton = crate::types::ton_client_of_ocaml(ton);
    let keys = keys.map(|keys| types::keypair_of_ocaml(keys));
    ocp::reply_async(
        crate::call::call_contract_rs(
            ton,
            &args[0],         // addr
            &args[1],         // abi
            &args[2],         // method
            &args[3],         // params
            keys,
            args[4].clone(),  // acc_boc
            local)
    )
}

#[ocaml::func]
pub fn call_contract_local_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    abi: String,
    msg: String,
    boc: String,
) -> ocp::Reply<String> {
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::call::call_contract_local_rs(
            ton,
            abi,
            msg,
            boc
            )
    )
}

#[ocaml::func]
pub fn send_message_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    abi: String,
    msg: String,
) -> ocp::Reply<crate::call::SendMessageResult> {
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::call::send_message_rs(
            ton,
            abi,
            msg,
            )
    )
}

#[ocaml::func]
pub fn wait_for_transaction_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    abi: String,
    msg: String,
    send: crate::call::SendMessageResult
) -> ocp::Reply<String> {
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::call::wait_for_transaction_rs(
            ton,
            abi,
            msg,
            send
            )
    )
}

#[ocaml::func]
pub fn prepare_message_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    args: Vec<String>,
    keys: Option<types::KeyPair>
) -> ocp::Reply<types::EncodedMessage> {
    let ton = crate::types::ton_client_of_ocaml(ton);
    let keys = keys.map(|keys| types::keypair_of_ocaml(keys));
    ocp::reply_async(
        crate::call::prepare_message_rs(
            ton,
            &args[0],         // addr
            &args[1],         // abi
            &args[2],         // method
            &args[3],         // params
            keys
        )
    )
}



#[ocaml::func]
pub fn create_client_ml( server_url : &str )
                           -> ocp::Reply< TonClientStruct >
{
    let client = crate::client::create_client_rs ( server_url )
        .map(|client| crate::types::ocaml_of_ton_client( client));
    ocp::reply( client )
}

#[ocaml::func]
pub fn find_last_shard_block_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    address: &str )
    -> ocp::Reply< String>
{
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::blocks::find_last_shard_block_rs( ton, address) )
}

#[ocaml::func]
pub fn wait_next_block_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    blockid: &str,
    address: &str,
    timeout: Option<u64>
)
    -> ocp::Reply<crate::types::Block>
{
    let timeout =
        if let Some(timeout) = timeout {
            Some(timeout as u32)
        } else {
            None
        };
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::blocks::wait_next_block_rs( ton, blockid, address, timeout ) )
}

#[ocaml::func]
pub fn decode_message_boc_ml(
    ton: ocaml::Pointer<TonClientStruct>,
    message_boc: String,
    abi: &str
)
    -> ocp::Reply<crate::types::DecodedMessageBody>
{
    let ton = crate::types::ton_client_of_ocaml(ton);
    ocp::reply_async(
        crate::blocks::decode_message_boc_rs( ton, message_boc, abi ) )
}


#[ocaml::func]
pub fn tvc_load_ml( contract_file: String )
                    -> ocp::Reply<StateInitStruct>
{
    ocp::reply(
        Ok( crate::types::ocaml_of_ton_state_init
            (crate::tvc::load_from_file( &contract_file ) ))
    )
}


#[ocaml::func]
pub fn tvc_data_ml( state:  ocaml::Pointer<StateInitStruct> )
                    -> ocp::Reply<String>
{
    ocp::reply(
        Ok( crate::tvc::state_init_data(
            &crate::types::state_init_of_ocaml ( state ))))
}

#[ocaml::func]
pub fn tvc_code_ml( state:  ocaml::Pointer<StateInitStruct> )
                    -> ocp::Reply<String>
{
    ocp::reply(
        Ok( crate::tvc::state_init_code(
            &crate::types::state_init_of_ocaml ( state ))))
}

#[ocaml::func]
pub fn tvc_code_hash_ml( state:  ocaml::Pointer<StateInitStruct> )
                    -> ocp::Reply<String>
{
    ocp::reply(
        Ok( crate::tvc::state_init_code_hash(
            &crate::types::state_init_of_ocaml ( state ))))
}

#[ocaml::func]
pub fn tvc_code_depth_ml( state:  ocaml::Pointer<StateInitStruct> )
                    -> ocp::Reply<u64>
{
    ocp::reply(
        Ok( crate::tvc::state_init_code_depth(
            &crate::types::state_init_of_ocaml ( state )) as u64))
}

#[ocaml::func]
pub fn tvc_data_hash_ml( state:  ocaml::Pointer<StateInitStruct> )
                    -> ocp::Reply<String>
{
    ocp::reply(
        Ok( crate::tvc::state_init_data_hash(
            &crate::types::state_init_of_ocaml ( state ))))
}

#[ocaml::func]
pub fn tvc_data_depth_ml( state:  ocaml::Pointer<StateInitStruct> )
                    -> ocp::Reply<u64>
{
    ocp::reply(
        Ok( crate::tvc::state_init_data_depth(
            &crate::types::state_init_of_ocaml ( state )) as u64))
}

#[ocaml::func]
pub fn encode_internal_message_ml( p:  crate::sdk::EncodeInternalMessage )
                    -> ocp::Reply< crate::sdk::SdkMessage >
{
    ocp::reply(
        crate::sdk::encode_internal_message
            ( p ))
}

