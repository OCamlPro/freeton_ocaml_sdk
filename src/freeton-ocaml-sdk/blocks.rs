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
        .map_err(|e| ocp::failwith(format!("{}",e)))?;

    let string_id = ton_client::processing::blocks_walking::
    find_last_shard_block(&context, &address).await
        .map_err(|e| ocp::failwith(format!("{}",e)))?;

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
        .map_err(|e| ocp::failwith(format!("{}",e)))?;

    let block = ton_client::processing::blocks_walking::
    wait_next_block(&context, &blockid, &address, timeout).await
        .map_err(|e| ocp::failwith(format!("{}",e)))?;

    Ok( crate::types::ocaml_of_block( block ) )
}

