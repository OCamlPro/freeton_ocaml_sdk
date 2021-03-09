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


pub const ERROR_FAILWITH : u16 = 0 ;
pub const ERROR_TONCLIENT_CREATE : u16 = 1 ;
pub const ERROR_MNEMONIC_FROM_RANDOM : u16 = 2 ;
pub const ERROR_INVALID_JSON_ABI : u16 = 3 ;
pub const ERROR_CANNOT_READ_KEYPAIR_FILE : u16 = 4 ;
pub const ERROR_CANNOT_GENERATE_ADDRESS : u16 = 5 ;
pub const ERROR_CANNOT_READ_ABI_FILE : u16 = 6 ;
pub const ERROR_CANNOT_READ_TVC_FILE : u16 = 7 ;
pub const ERROR_INVALID_JSON_INITIAL_DATA : u16 = 8 ;
pub const ERROR_INVALID_JSON_PARAMS : u16 = 9 ;
pub const ERROR_DEPLOY_FAILED : u16 = 10 ;
pub const ERROR_TOKIO_RUNTIME_NEW : u16 = 11 ;

#[derive(ocaml::ToValue, ocaml::FromValue)]
pub struct Error {
    code: u16,
    msg: String,
}

pub fn error(code: u16, msg: String) -> Error {
    Error { code: code, msg: msg }
}

pub fn failwith(msg: String) -> Error {
    Error { code: ERROR_FAILWITH, msg: msg }
}

#[derive(ocaml::ToValue, ocaml::FromValue)]
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
