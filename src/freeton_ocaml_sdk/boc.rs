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

use ton_client::boc::{ParamsOfParse, parse_message};
use crate::client::{create_client_local};


pub async fn parse_message_rs(msg : String) -> Result<String, ocp::Error>
{
    let ton = create_client_local()?;
    let parsed = parse_message(
        ton,
        ParamsOfParse { boc: msg.clone() },
    )
        .await
        .map_err(|e|
                 ocp::error(ocp::ERROR_PARSE_MESSAGE_FAILED,
                            format!("{:#}", e)))?;
    let json = serde_json::to_string_pretty(& parsed.parsed)
        .map_err(|e|
                 ocp::error(ocp::ERROR_ENCODE_JSON_FAILED,
                            format!("{:#}", e)))?;
    Ok(json)

}
