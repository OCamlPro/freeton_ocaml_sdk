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


use ocaml::{FromValue, Raw, Value};


/*********************************************************************

           OCaml pointer for TonClient

*********************************************************************/

use std::sync::Arc;
use ton_client::{ClientContext};

pub type TonClient = Arc<ClientContext>;

pub struct TonClientStruct {
    pub client : TonClient 
}

unsafe extern "C" fn client_finalizer(v: Raw) {
    let v = Value::new(v);
    let ptr = ocaml::Pointer::<TonClientStruct>::from_value(v);
    // eprintln!("drop_in_place on TonClient");
    ptr.drop_in_place()
}

ocaml::custom!(TonClientStruct {
    finalize: client_finalizer
});


pub fn ton_client_of_ocaml( mut ton: ocaml::Pointer<TonClientStruct> )
                            -> TonClient
{
    Arc::clone(&ton.as_mut().client)
}

pub fn ocaml_of_ton_client( client: TonClient ) ->
    TonClientStruct
{
    TonClientStruct { client: client } 
}

/*********************************************************************

           OCaml pointer for StateInit

*********************************************************************/

pub struct StateInitStruct {
    pub state_init : ton_block::StateInit 
}

unsafe extern "C" fn state_init_finalizer(v: Raw) {
    let v = Value::new(v);
    let ptr = ocaml::Pointer::<StateInitStruct>::from_value(v);
    // eprintln!("drop_in_place on StateInit");
    ptr.drop_in_place()
}

ocaml::custom!(StateInitStruct {
    finalize: state_init_finalizer
});


pub fn state_init_of_ocaml( st: ocaml::Pointer<StateInitStruct> )
                            -> ton_block::StateInit
{
    st.as_ref().state_init.clone()
}

pub fn ocaml_of_ton_state_init( state_init: ton_block::StateInit ) ->
    StateInitStruct
{
    StateInitStruct { state_init: state_init } 
}

/*********************************************************************

           OCaml pointer for ton_client::crypto::KeyPair

*********************************************************************/

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct KeyPair {
    pub public: String,
    pub secret: Option<String>,
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

/*********************************************************************

           OCaml pointer for ton_sdk::ShardDescr

*********************************************************************/

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct ShardDescr {
    pub workchain_id: i32,
    pub shard: u64,
}

pub fn ocaml_of_shard_descr( s : ton_sdk::ShardDescr ) -> ShardDescr
{
    ShardDescr {
        workchain_id : s.workchain_id,
        shard : s.shard
    }
}

/*********************************************************************

           OCaml pointer for ton_sdk::MsgDescr

*********************************************************************/

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct MsgDescr {
    pub msg_id: Option<String>,  // MessageId
    pub transaction_id: Option<String>, // TransactionId
}

pub fn ocaml_of_msg_descr( m : &ton_sdk::MsgDescr ) -> MsgDescr
{
    MsgDescr {
        msg_id: m.msg_id.as_ref().map(|id| id.to_string() ),
        transaction_id: m.transaction_id.as_ref().map(|id| id.to_string() )
    }
}

/*********************************************************************

           OCaml pointer for ton_sdk::Block

*********************************************************************/

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct Block {
    pub id: String,
    pub gen_utime: u64,
    pub after_split: bool,
    pub shard_descr: ShardDescr,
    pub in_msg_descr: Vec<MsgDescr>,
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



/*********************************************************************

           OCaml pointer for ton_client::abi::DecodedMessageBody

*********************************************************************/

// pub enum MessageBodyType {
    /// Message contains the input of the ABI function.
//    Input => 0

    /// Message contains the output of the ABI function.
//    Output => 1

    /// Message contains the input of the imported ABI function.
    ///
    /// Occurs when contract sends an internal message to other
    /// contract.
//    InternalOutput => 2

    /// Message contains the input of the ABI event.
//    Event => 3
//}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct DecodedMessageBody {
    /// Type of the message body content.
    pub body_type: u8,

    /// Function or event name.
    pub name: String,

    /// Parameters or result value.
    pub value: Option<String>,

    // Function header.
    // pub header: Option<FunctionHeader>,
}

use ton_client::abi::MessageBodyType;

pub fn ocaml_of_decoded_message_body( m : ton_client::abi::DecodedMessageBody ) -> DecodedMessageBody
{
    let body_type = match m.body_type {
        MessageBodyType::Input => 0,
        MessageBodyType::Output => 1,
        MessageBodyType::InternalOutput => 2,
        MessageBodyType::Event => 3,
    };
    DecodedMessageBody {
        body_type,
        name: m.name,
        value: m.value.map(|v| v.to_string() )
    }
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct EncodedMessage {
    pub message_id: String,
    pub message: String,
    pub expire: Option<u64>,
//    address: String,
}
