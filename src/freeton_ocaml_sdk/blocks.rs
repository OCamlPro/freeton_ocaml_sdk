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
use crate::types::{TonClient};

pub async fn find_last_shard_block_rs(
    context: TonClient,
    address: &str
) -> Result<String, ocp::Error>
{
    let address = ton_client::encoding::account_decode(address)
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_ADDRESS_FAILED,
                                format!("{:#}",e)))?;

    let string_id = ton_client::processing::blocks_walking::
    find_last_shard_block_pub(&context, &address).await
        .map_err(|e| ocp::error(ocp::ERROR_FIND_LAST_SHARD_FAILED,
                                format!("{:#}",e)))?;

    Ok( string_id.to_string() )
}

/* 
pub struct Block {
    pub id: BlockId,
    pub gen_utime: u32,
    pub after_split: bool,
    #[serde(flatten)]
    pub shard_descr: ShardDescr,
    pub in_msg_descr: Vec<MsgDescr>,
}
 */

pub async fn wait_next_block_rs(
    context: TonClient,
    blockid: &str,
    address: &str,
    timeout: Option<u32>,
) -> Result<crate::types::Block, ocp::Error> {

    let address = ton_client::encoding::account_decode(address)
        .map_err(|e| ocp::error(ocp::ERROR_DECODE_ADDRESS_FAILED,
                                format!("{:#}",e)))?;

    let block = ton_client::processing::blocks_walking::
    wait_next_block(&context, &blockid, &address, timeout).await
        .map_err(|e| ocp::error(ocp::ERROR_WAIT_NEXT_BLOCK_FAILED,
                                format!("{:#}",e)))?;

    Ok( crate::types::ocaml_of_block( block ) )
}






//use ton_client::boc::internal::deserialize_object_from_base64;
//use ton_client::processing::parsing::{
//    decode_output,
//    parse_transaction_boc
//};
use ton_client::abi::{
    decode_message,
//    Abi,
//    MessageBodyType,
    ParamsOfDecodeMessage,
//    DecodedMessageBody
};


pub async fn decode_message_boc_rs(
    context: TonClient,
    message_boc: String,
    abi: &str
) -> Result<crate::types::DecodedMessageBody, ocp::Error>
{
    let abi = crate::deploy::load_abi(abi)?;

    let decode_result = decode_message(
            context.clone(),
            ParamsOfDecodeMessage {
                message: message_boc,
                abi: abi.clone(),
            },
    ).await.map_err(|e| ocp::error(ocp::ERROR_DECODE_MESSAGE_FAILED,
                                   format!("{:#}",e)))?;

    Ok( crate::types::ocaml_of_decoded_message_body(decode_result) )
}



/*
pub async fn decode_transaction_boc_rs(
    context: TonClient,
//    transaction_boc : &str,
    out_messages: Vec<String>,
    abi: &str
) -> Result<String, ocp::Error>
{
    let abi = crate::deploy::load_abi(abi)?;
//    let transaction_object =
//        deserialize_object_from_base64(&transaction_boc, "transaction")?;
//    let (transaction, out_messages) = parse_transaction_boc(context.clone(), transaction_boc).await?;
    let abi_decoded = decode_output(&context, &abi, out_messages.clone()).await.map_err(|e| ocp::failwith(format!("{}",e)))?;

    Ok( abi_decoded )
}
*/
