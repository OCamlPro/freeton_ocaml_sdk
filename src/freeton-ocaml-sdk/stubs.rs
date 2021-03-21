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
    args: Vec<String>,
    keys: ocp::KeyPair,
    wc: i16) -> ocp::Reply<String> {
    
    ocp::reply_async(
        crate::deploy::deploy_contract_rs(args[0].clone(), // server_url
                           &args[1],        // tvc
                           &args[2],        // abi
                           &args[3],        // params
                           ocp::keypair_of_ocaml(keys),
                           args[4].clone(),  // initial_data
                           args[5].clone(),  // initial_pubkey
                           wc as i32)
    )
}

#[ocaml::func]
pub fn generate_keypair_from_mnemonic_ml
    (mnemonic: String) -> ocp::Reply<ocp::KeyPair> {
    
    ocp::reply(
        crate::crypto::generate_keypair_from_mnemonic_rs(&mnemonic))
}

#[ocaml::func]
pub fn generate_address_ml(
    args: Vec<String>,
    keys: ocp::KeyPair,
    wc: i16,
) -> ocp::Reply<String> {
    ocp::reply_async(
        crate::genaddr::generate_address_rs(
            &args[0], //   tvc
            &args[1], //   abi
            wc as i32,
            ocp::keypair_of_ocaml(keys),
            args[2].clone(), //   initial_data 
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
            &args[3], //   params
            ))
}
