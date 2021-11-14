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


use std::str::FromStr;

use crate::ocp;

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct EncodeFunctionCall {
    abi : String ,
    function : String ,
    header : Option < String > ,
    parameters : String ,
    internal : bool ,
    key_pair : Option < crate::types::KeyPair >,
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct SdkMessage {
    pub id: String, // hex-encoded string
    pub serialized_message: String,
//    pub message: ton_block::Message,
    pub address: String ,
}


#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct EncodeInternalMessage {
    pub address : String ,
    pub src_address : Option < String > ,
    pub ihr_disabled : bool ,
    pub bounce : bool ,
    pub value : u64 ,
    pub payload1 : Option < EncodeFunctionCall > ,
    pub payload2 : Option < String > ,
}

//use ed25519_dalek::{PublicKey, SecretKey};

pub fn parse_key(s: &String) -> Result<Vec<u8>, ocp::Error> {
    hex::decode(s)
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_HEXA_FAILED,
                                format!("{:#}",e))
        )
}

pub fn decode_public_key(string: &String)
                         -> Result<ed25519_dalek::PublicKey, ocp::Error> {
    ed25519_dalek::PublicKey::from_bytes(parse_key(string)?.as_slice())
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_PUBKEY_FAILED,
                                format!("{:#}",e))
        )
}

pub fn decode_secret_key(string: &String)
                         -> Result<ed25519_dalek::SecretKey, ocp::Error> {
    ed25519_dalek::SecretKey::from_bytes(parse_key(string)?.as_slice())
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_SECRET_FAILED,
                                format!("{:#}",e))
        )
}

/*
pub fn ed25519_pair_of ( pair : crate::types::KeyPair ) ->
    Result< ed25519_dalek::Keypair, ocp::Error>
{
    let secret = if
        let Some(secret) = pair.secret { secret }
    else { String::from("") };
    Ok( ed25519_dalek::Keypair {
        public: decode_public_key( &pair.public )?,
        secret: decode_secret_key( &secret )?,
    })

}
 */

pub fn encode_function_call ( p: EncodeFunctionCall ) ->
    Result< ton_types::SliceData, ocp::Error>
{
    if
        let Some( pair ) = p.key_pair {
            let secret = if
                let Some(secret) = pair.secret { secret }
            else { String::from("") };
            let key_pair =
                &ed25519_dalek::Keypair {
                    public: decode_public_key( &pair.public )?,
                    secret: decode_secret_key( &secret )?,
                };

            let builder = ton_abi::encode_function_call(
                p.abi,
                p.function,
                p.header,
                p.parameters,
                p.internal,
                Some ( key_pair )
            ).map_err(|e| ocp::error(ocp::ERROR_ENCODE_BODY_FAILED,
                                     format!("{:#}",e))
            )?;
            Ok ( builder.into() )

        } else {

            let builder = ton_abi::encode_function_call(
                p.abi,
                p.function,
                p.header,
                p.parameters,
                p.internal,
                None
            ).map_err(|e| ocp::error(ocp::ERROR_ENCODE_BODY_FAILED,
                                     format!("{:#}",e))
            )?;
            Ok ( builder.into() )

        }
}

pub fn encode_internal_message ( p: EncodeInternalMessage ) ->
    Result< SdkMessage, ocp::Error>
{
    let address = ton_block::MsgAddressInt::from_str( &p.address )
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_ADDRESS_FAILED,
                                format!("{:#}",e))
        )?;
    let src_address =
        if
        let Some ( src_address ) = p.src_address {
            Some (
                ton_block::MsgAddressInt::from_str( &src_address )
                    .map_err(|e| ocp::error(ocp::ERROR_DECODE_ADDRESS_FAILED,
                                            format!("{:#}",e))
                    )?
            )
        } else { None };

    let value = ton_block::CurrencyCollection::with_grams( p.value );

    let payload =
        if
        let Some ( payload ) = p.payload1 {

            Some ( encode_function_call( payload ) ? )

        } else {
            if
                let Some ( payload ) = p.payload2 {

                    let payload_u8vec = base64::decode( payload )
                        .map_err(|e| ocp::error(ocp::ERROR_DECODE_BASE64_FAILED,
                                        format!("{:#}",e))
                        )?;
                    let slicedata : ton_types::SliceData = payload_u8vec.into();
                    Some ( slicedata )

                } else {
                    None
                }
        };

    let res = ton_sdk::Contract::construct_int_message_with_body(
        address,
        src_address,
        p.ihr_disabled,
        p.bounce,
        value,
        payload
    ).map_err(|e| ocp::error(ocp::ERROR_ENCODE_MESSAGE_FAILED,
                                format!("{:#}",e))
    )?;
    Ok ( SdkMessage {
        id : res.id.to_string(),
        address : res.address.to_string() ,
        serialized_message : base64::encode( res.serialized_message ) ,
    } )
}

/*

use ton_sdk;
use ton_types::SliceData;


pub fn test() -> Result<ton_sdk::SdkMessage, ocp::Error>
{

    let abi = String::from("xxx");
    let function = String::from("meth");
    let header = Some (String::from("{}"));
    let parameters = String::from("{}");
    let internal = true ;
    let pair = None ;
    let payload_builderdata = ton_abi::encode_function_call(
        abi,
        function,
        header,
        parameters,
        internal,
        pair //: Option<&ed25519_dalek::Keypair>,
    ).map_err(|e| ocp::error(ocp::ERROR_ENCODE_BODY_FAILED,
                                format!("{:#}",e))
    )?;

    let payload_slicedata : SliceData = payload_builderdata.into();
    let payload_u8vec = base64::decode("hello")
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_BASE64_FAILED,
                                format!("{:#}",e))
        )?;
    let payload_slicedata : SliceData = payload_u8vec.into();

    let payload = Some ( payload_slicedata );




    let address = ton_block::MsgAddressInt::from_str("0:48447974297")
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_ADDRESS_FAILED,
                                format!("{:#}",e))
            )?;
    let src_address = ton_block::MsgAddressInt::from_str("0:48447974297")
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_ADDRESS_FAILED,
                                format!("{:#}",e))
            )?;
    let src_address = Some(src_address);
    let ihr_disabled = false ;
    let bounce = false ;
    let value = ton_block::CurrencyCollection::with_grams(10_000000000);

    let res = ton_sdk::Contract::construct_int_message_with_body(
        address,
        src_address,
        ihr_disabled,
        bounce,
        value,
        payload
    ).map_err(|e| ocp::error(ocp::ERROR_ENCODE_MESSAGE_FAILED,
                                format!("{:#}",e))
    )?;
    
    Ok ( res )
}
 */
