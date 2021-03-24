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

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct ShardDescr {
    pub workchain_id: i32,
    pub shard: u64,
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct MsgDescr {
    pub msg_id: Option<String>,  // MessageId
    pub transaction_id: Option<String>, // TransactionId
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct Block {
    pub id: String,
    pub gen_utime: u64,
    pub after_split: bool,
    pub shard_descr: ShardDescr,
    pub in_msg_descr: Vec<MsgDescr>,
}

pub fn ocaml_of_shard_descr( s : ton_sdk::ShardDescr ) -> ShardDescr
{
    ShardDescr {
        workchain_id : s.workchain_id,
        shard : s.shard
    }
}

pub fn ocaml_of_msg_descr( m : &ton_sdk::MsgDescr ) -> MsgDescr
{
    MsgDescr {
        msg_id: m.msg_id.as_ref().map(|id| id.to_string() ),
        transaction_id: m.transaction_id.as_ref().map(|id| id.to_string() )
    }
}

pub fn ocaml_of_block( b : ton_sdk::Block ) -> Block
{
    Block {
        id: b.id.to_string(),
        gen_utime: b.gen_utime as u64,
        after_split: b.after_split,
        shard_descr: ocaml_of_shard_descr( b.shard_descr ),
        in_msg_descr: b.in_msg_descr.
            iter().map(|m| ocaml_of_msg_descr(m)).collect()
    }
}
