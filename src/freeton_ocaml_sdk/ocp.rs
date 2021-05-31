/**************************************************************************/
/*                                                                        */
/*  Copyright (c) 2021 OCamlPro SAS                                       */
/*                                                                        */
/*  All rights reserved.                                                  */
/*  This file is distributed under the terms of the GNU Lesser General    */
/*  Public License version 2.1, with the special exception on linking     */
/*  described in the LICENSE.md file in the root directory.               */
/*                                                                        */
/*                                                                        */
/**************************************************************************/


// pub const ERROR_FAILWITH : u16 = 0 ;
pub const ERROR_TONCLIENT_CREATE : u16 = 1 ;
pub const ERROR_MNEMONIC_FROM_RANDOM : u16 = 2 ;
pub const ERROR_INVALID_JSON_ABI : u16 = 3 ;
pub const ERROR_ENCODE_MESSAGE_FAILED : u16 = 4 ;
pub const ERROR_GENERATE_ADDRESS_FAILED : u16 = 5 ;
pub const ERROR_RUN_TVM_FAILED : u16 = 6 ;
pub const ERROR_READ_TVC_FAILED : u16 = 7 ;
pub const ERROR_INVALID_JSON_INITIAL_DATA : u16 = 8 ;
pub const ERROR_INVALID_JSON_PARAMS : u16 = 9 ;
pub const ERROR_DEPLOY_FAILED : u16 = 10 ;
pub const ERROR_TOKIO_RUNTIME_NEW : u16 = 11 ;
pub const ERROR_DECODE_ADDRESS_FAILED : u16 = 12 ;
pub const ERROR_FIND_LAST_SHARD_FAILED : u16 = 13 ;
pub const ERROR_WAIT_NEXT_BLOCK_FAILED : u16 = 14 ;
pub const ERROR_DECODE_MESSAGE_FAILED : u16 = 15 ;
pub const ERROR_PARSE_MESSAGE_FAILED : u16 = 16 ;
pub const ERROR_ENCODE_JSON_FAILED : u16 = 17 ;
pub const ERROR_SEND_MESSAGE_FAILED : u16 = 18 ;
pub const ERROR_WAIT_FOR_TRANSACTION_FAILED : u16 = 19 ;
pub const ERROR_REPLY_IS_ERROR : u16 = 20 ;
pub const ERROR_PARSE_REPLY_FAILED : u16 = 21 ;
pub const ERROR_HDKEY_FROM_MNEMONIC_FAILED : u16 = 22 ;
pub const ERROR_DERIVE_KEY_FAILED : u16 = 23 ;
pub const ERROR_SECRET_KEY_FAILED : u16 = 24 ;
pub const ERROR_KEYPAIR_OF_SECRET_FAILED : u16 = 25 ;
pub const ERROR_PARSE_PUBKEY_FAILED : u16 = 26 ;
pub const ERROR_LOAD_CONTRACT_IMAGE_FAILED : u16 = 27 ;
pub const ERROR_UPDATE_CONTRACT_IMAGE_FAILED : u16 = 28 ;
pub const ERROR_WRITE_TVC_FILE : u16 = 29 ;
pub const ERROR_ENCODE_BODY_FAILED : u16 = 30 ;
pub const ERROR_DECODE_BASE64_FAILED : u16 = 31 ;
pub const ERROR_DECODE_PUBKEY_FAILED : u16 = 32 ;
pub const ERROR_DECODE_SECRET_FAILED : u16 = 33 ;
pub const ERROR_DECODE_HEXA_FAILED : u16 = 34 ;

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct Error {
    code: u16,
    msg: String,
}

pub fn error(code: u16, msg: String) -> Error {
    Error { code: code, msg: msg }
}

/*pub fn failwith(msg: String) -> Error {
    Error { code: ERROR_FAILWITH, msg: msg }
}*/

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct Reply<A> {
    result: Option<A>,
    error: Option<Error>
}

pub fn reply<A>(r : Result<A, Error > ) -> Reply<A> {
    match r {
        Ok(x) =>
            Reply { result: Some(x),
                     error: None },
        Err ( error ) =>
            Reply { result: None,
                     error: Some(error) }
    }
}

use tokio::runtime::Runtime;

pub fn reply_async<A,
                   F: core::future::Future<Output = Result<A, Error>>
                   >(f : F ) -> Reply<A> {
    let rt  = Runtime::new();
    match rt {
        Ok(rt) => {
            let mut rt = rt;
            reply ( rt.block_on(f) )
        }
        Err(e) => Reply { result: None,
                          error:
                          Some (error(
                              ERROR_TOKIO_RUNTIME_NEW,
                              format!("{}", e))
                                )
                          }
    }
}

