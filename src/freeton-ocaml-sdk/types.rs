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


use ocaml::FromValue;

use std::sync::Arc;
use ton_client::{ClientContext};

pub type TonClient = Arc<ClientContext>;

pub struct TonClientStruct {
    pub client : TonClient 
}

unsafe extern "C" fn client_finalizer(v: ocaml::Value) {
    let ptr: ocaml::Pointer<TonClientStruct> = ocaml::Pointer::from_value(v);
    eprintln!("drop_in_place on TonClient");
    ptr.drop_in_place()
}

ocaml::custom_finalize!(TonClientStruct, client_finalizer);

pub fn ton_client_of_ocaml( mut ton: ocaml::Pointer<TonClientStruct> )
                            -> TonClient
{
    Arc::clone(&ton.as_mut().client)
}

pub fn ocaml_of_ton_client( gc : & ocaml::Runtime, client: TonClient ) ->
    ocaml::Pointer<TonClientStruct>
{
    ocaml::Pointer::alloc_custom(gc,
                                 TonClientStruct { client: client })
        
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct KeyPair {
    public: String,
    secret: Option<String>,
}

pub fn keypair_of_ocaml(keys: KeyPair) -> ton_client::crypto::KeyPair
{
    if let Some(secret) = keys.secret {
        ton_client::crypto::KeyPair {
            public : keys.public,
            secret : secret,
        }
    } else {
        ton_client::crypto::KeyPair {
            public : keys.public,
            secret : "".to_string(),
        }
    }
}

pub fn ocaml_of_keypair(keys: ton_client::crypto::KeyPair) -> KeyPair
{
    KeyPair {
        public : keys.public,
        secret : Some(keys.secret)
    }
}
