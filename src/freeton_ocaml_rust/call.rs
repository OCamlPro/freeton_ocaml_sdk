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
use crate::types::{TonClient, EncodedMessage};
use crate::client::{create_client_local};
use crate::deploy::{load_abi};

use ton_client::crypto::KeyPair;

use chrono::{TimeZone,Local};
use ton_client::abi::{
    encode_message,
    ParamsOfEncodeMessage,
    ParamsOfEncodeMessageBody,
    Abi,
    CallSet,
    FunctionHeader,
    Signer
};
use ton_client::processing::{
    ParamsOfSendMessage,
    ParamsOfWaitForTransaction,
    wait_for_transaction,
    send_message,
};
use ton_client::tvm::{
//    run_tvm,
    ParamsOfRunTvm,
//    run_get,
    //    ParamsOfRunGet
};

async fn prepare_message(
    ton: TonClient,
    addr: &str,
    abi: Abi,
    method: &str,
    params: &str,
    header: Option<FunctionHeader>,
    keys: Option<KeyPair>,
) -> Result<EncodedMessage, ocp::Error> {
    // eprintln!("Generating external inbound message...");

    let params = serde_json::from_str(&params)
        .map_err(|e|
                 ocp::error(ocp::ERROR_INVALID_JSON_PARAMS,
                            format!("{:#}", e)))?;


    let call_set = Some(CallSet {
        function_name: method.into(),
        input: Some(params),
        header: header.clone(),
    });

    let msg = encode_message(
        ton,
        ParamsOfEncodeMessage {
            abi,
            address: Some(addr.to_owned()),
            deploy_set: None,
            call_set,
            signer: if keys.is_some() {
                Signer::Keys { keys: keys.unwrap() }
            } else {
                Signer::None
            },
            processing_try_index: None,
        },
    ).await
        .map_err(|e|
                 ocp::error(ocp::ERROR_ENCODE_MESSAGE_FAILED,
                            format!("{:#}", e)))?;

    let expire = header.and_then(|h| h.expire);
    let expire = if let Some(expire) = expire {
        Some (expire as u64)
    } else { None };
    Ok(EncodedMessage {
        message: msg.message,
        message_id: msg.message_id,
        expire: expire,
//        address: addr.to_owned(),
    })
}

fn print_encoded_message(msg: &EncodedMessage) {
    eprintln!("MessageId: {}", msg.message_id);
    if msg.expire.is_some() {
        let expire_at = Local.timestamp(msg.expire.unwrap() as i64 , 0);
        eprintln!("Expire at: {}", expire_at.to_rfc2822());
    } else {
    }
}



/*

fn pack_message(msg: &EncodedMessage, method: &str, is_raw: bool) -> Vec<u8> {
    if is_raw {
        base64::decode(&msg.message).unwrap()
    } else {
        let json_msg = serde_json::json!({
            "msg": {
                "message_id": msg.message_id,
                "message": msg.message,
                "expire": msg.expire,
                "address": msg.address,
            },
            "method": method,
        });
        serde_json::to_string(&json_msg).unwrap().into_bytes()
    }
}

fn unpack_message(str_msg: &str) -> Result<(EncodedMessage, String), String> {
    let bytes = hex::decode(str_msg)
        .map_err(|e| format!("couldn't unpack message: {}", e))?;

    let str_msg = std::str::from_utf8(&bytes)
        .map_err(|e| format!("message is corrupted: {}", e))?;

    let json_msg: serde_json::Value = serde_json::from_str(str_msg)
        .map_err(|e| format!("couldn't decode message: {}", e))?;

    let method = json_msg["method"].as_str()
        .ok_or(r#"couldn't find "method" key in message"#)?
        .to_owned();
    let message_id = json_msg["msg"]["message_id"].as_str()
        .ok_or(r#"couldn't find "message_id" key in message"#)?
        .to_owned();
    let message = json_msg["msg"]["message"].as_str()
        .ok_or(r#"couldn't find "message" key in message"#)?
        .to_owned();
    let expire = json_msg["msg"]["expire"].as_u64().map(|x| x as u32);
    let address = json_msg["msg"]["address"].as_str()
        .ok_or(r#"couldn't find "address" key in message"#)?
        .to_owned();

    let msg = EncodedMessage {
        message_id, message, expire, address
    };
    Ok((msg, method))
}

async fn decode_call_parameters(ton: TonClient, msg: &EncodedMessage, abi: Abi) -> Result<(String, String), String> {
    let result = decode_message(
        ton,
        ParamsOfDecodeMessage {
            abi,
            message: msg.message.clone(),
        },
    )
    .await
    .map_err(|e| format!("couldn't decode message: {}", e))?;

    Ok((
        result.name,
        serde_json::to_string_pretty(
            &result.value.unwrap_or(serde_json::json!({}))
        ).unwrap()
    ))
}

fn parse_integer_param(value: &str) -> Result<String, String> {
    let value = value.trim_matches('\"');

    if value.ends_with('T') {
        convert::convert_token(value.trim_end_matches('T'))
    } else {
        Ok(value.to_owned())
    }
}

fn build_json_from_params(params_vec: Vec<&str>, abi: &str, method: &str) -> Result<String, String> {
    let abi_obj = Contract::load(abi.as_bytes()).map_err(|e| format!("failed to parse ABI: {}", e))?;
    let functions = abi_obj.functions();

    let func_obj = functions.get(method).unwrap();
    let inputs = func_obj.input_params();

    let mut params_json = serde_json::json!({ });
    for input in inputs {
        let mut iter = params_vec.iter();
        let _param = iter.find(|x| x.trim_start_matches('-') == input.name)
            .ok_or(format!(r#"argument "{}" of type "{}" not found"#, input.name, input.kind))?;

        let value = iter.next()
            .ok_or(format!(r#"argument "{}" of type "{}" has no value"#, input.name, input.kind))?
            .to_string();

        let value = match input.kind {
            ParamType::Uint(_) | ParamType::Int(_) => {
                serde_json::json!(parse_integer_param(&value)?)
            },
            ParamType::Array(ref x) => {
                if let ParamType::Uint(_) = **x {
                    let mut result_vec: Vec<String> = vec![];
                    for i in value.split(|c| c == ',' || c == '[' || c == ']') {
                        if i != "" {
                            result_vec.push(parse_integer_param(i)?)
                        }
                    }
                    serde_json::json!(result_vec)
                } else {
                    serde_json::json!(value)
                }
            },
            _ => {
                serde_json::json!(value)
            }
        };
        params_json[input.name.clone()] = value;
    }

    serde_json::to_string(&params_json).map_err(|e| format!("{}", e))
}


async fn query_account_boc(ton: TonClient, addr: &str) -> Result<String, String> {
    let accounts = query(
        ton,
        "accounts",
        serde_json::json!({ "id": { "eq": addr } }),
        "boc",
        None,
    ).await
    .map_err(|e| format!("failed to query account: {}", e))?;

    if accounts.len() == 0 {
        return Err(format!("account not found"));
    }
    let boc = accounts[0]["boc"].as_str();
    if boc.is_none() {
        return Err(format!("account doesn't contain data"));
    }
    Ok(boc.unwrap().to_owned())
}
 */


pub async fn call_contract_local_rs(
    ton: TonClient,
    abi: String,
    msg: String,
    boc: String,
) -> Result<String, ocp::Error> {
    let abi = load_abi(&abi)?;
    let result = ton_client::tvm::run_tvm(
        ton,
        ParamsOfRunTvm {
            message: msg,
            account: boc,
            execution_options: None,
            abi: Some(abi.clone()),
            return_updated_account: Some(true),
            boc_cache: None,
        },
    ).await
        .map_err(|e|
                 ocp::error(ocp::ERROR_RUN_TVM_FAILED,
                            format!("{:#}", e)))?;
    let result =
        result.decoded.and_then(|d| d.output).unwrap_or(serde_json::json!({}));
    if !result.is_null() {
        Ok(serde_json::to_string_pretty(&result).unwrap())
    } else {
        Ok("".to_string())
    }
}

async fn send_message_and_wait(
    ton: TonClient,
    abi: Abi,
    msg: String,
    acc_boc: String,
    local: bool,
) -> Result<serde_json::Value, ocp::Error> {
    if local {
        eprintln!("Running get-method...");
//        let acc_boc = query_account_boc(ton.clone(), addr).await?;

        let result = ton_client::tvm::run_tvm(
            ton.clone(),
            ParamsOfRunTvm {
                message: msg,
                account: acc_boc,
                execution_options: None,
                abi: Some(abi.clone()),
                return_updated_account: Some(true),
                boc_cache: None,
            },
        ).await
            .map_err(|e|
                     ocp::error(ocp::ERROR_RUN_TVM_FAILED,
                                   format!("{:#}", e)))?;
        Ok(result.decoded.and_then(|d| d.output).unwrap_or(serde_json::json!({})))
    } else {
  //      eprintln!("Processing... ");
        let callback = |_| {
            //println!("Callback... ");
            async move {}
        };

        let result = send_message(
            ton.clone(),
            ParamsOfSendMessage {
                message: msg.clone(),
                abi: Some(abi.clone()),
                send_events: false,
            },
            callback,
        ).await
            .map_err(|e|
                     ocp::error(ocp::ERROR_SEND_MESSAGE_FAILED,
                                format!("{:#}", e)))?;

//        eprintln!("wait for transaction");
        
        let result = wait_for_transaction(
            ton.clone(),
            ParamsOfWaitForTransaction {
                abi: Some(abi.clone()),
                message: msg.clone(),
                shard_block_id: result.shard_block_id,
                send_events: true,
                sending_endpoints: Some ( result.sending_endpoints )
            },
            callback.clone(),
        ).await
            .map_err(|e|
                     ocp::error(
                         ocp::ERROR_WAIT_FOR_TRANSACTION_FAILED,
                         format!("{:#}", e)))?;

        //println!("done");
        Ok(result.decoded.and_then(|d| d.output).unwrap_or(serde_json::json!({})))
    }
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
pub struct SendMessageResult {
    shard_block_id: String ,
    sending_endpoints: Vec<String>
        
}

pub async fn wait_for_transaction_rs(
    ton: TonClient ,
    abi: String ,
    msg: String ,
    send: SendMessageResult ,
) -> Result<String, ocp::Error>
{
    let abi = load_abi(&abi)?;

    let callback = |_| {
        async move {}
    };
    let result = wait_for_transaction(
        ton,
        ParamsOfWaitForTransaction {
            abi: Some(abi),
            message: msg,
            shard_block_id: send.shard_block_id,
            send_events: true,
            sending_endpoints: Some ( send.sending_endpoints )
        },
        callback.clone(),
    ).await
        .map_err(|e|
                 ocp::error(
                     ocp::ERROR_WAIT_FOR_TRANSACTION_FAILED,
                     format!("{:#}", e)))?;

    let result =
        result.decoded.and_then(|d| d.output).unwrap_or(serde_json::json!({}));
    if !result.is_null() {
        Ok(serde_json::to_string_pretty(&result).unwrap())
    } else {
        Ok("".to_string())
    }
}

pub async fn send_message_rs(
    ton: TonClient ,
    abi: String ,
    msg: String ,
) -> Result<SendMessageResult, ocp::Error>
{
    let abi = load_abi(&abi)?;

    let callback = |_| {
        async move {}
    };

    let result = send_message(
        ton ,
        ParamsOfSendMessage {
            message: msg,
            abi: Some(abi),
            send_events: false,
        },
        callback,
    ).await
        .map_err(|e|
                 ocp::error(ocp::ERROR_SEND_MESSAGE_FAILED,
                            format!("{:#}", e)))?;
    Ok(
        SendMessageResult {
            shard_block_id : result.shard_block_id ,
            sending_endpoints : result.sending_endpoints
        }
        )
}

pub async fn prepare_message_rs(
    ton: TonClient,
    addr: &str,
    abi: &str,
    method: &str,
    params: &str,
    keys: Option<KeyPair>
) -> Result<EncodedMessage, ocp::Error> {
    let abi = load_abi(abi)?;
    let msg = prepare_message(
        ton.clone(),
        addr,
        abi.clone(),
        method,
        params,
        None,
        keys,
    ).await?;
    Ok(msg)
}

pub async fn call_contract_with_result(
    ton: TonClient,
    addr: &str,
    abi: &str,
    method: &str,
    params: &str,
    keys: Option<KeyPair>,
    acc_boc: String,
    local: bool,
) -> Result<serde_json::Value, ocp::Error> {
    let abi = load_abi(abi)?;

    let msg = prepare_message(
        ton.clone(),
        addr,
        abi.clone(),
        method,
        params,
        None,
        keys,
    ).await?;

    print_encoded_message(&msg);

    send_message_and_wait(ton.clone(), abi,
                          msg.message, acc_boc, local).await
}

pub async fn call_contract_rs(
    ton: TonClient,
    addr: &str,
    abi: &str,
    method: &str,
    params: &str,
    keys: Option<KeyPair>,
    acc_boc: String,
    local: bool
) -> Result<String, ocp::Error> {
    let result = call_contract_with_result(ton, addr, abi,
                                           method, params, keys,
                                           acc_boc, local).await?;
//    eprintln!("Succeeded.");
    if !result.is_null() {
        Ok(serde_json::to_string_pretty(&result).unwrap())
    } else {
        Ok("".to_string())
    }
}


/*

pub async fn generate_message(
    _conf: Config,
    addr: &str,
    abi: String,
    method: &str,
    params: &str,
    keys: Option<String>,
    lifetime: u32,
    is_raw: bool,
    output: Option<&str>,
) -> Result<(), String> {
    let ton = create_client_local()?;

    let ton_addr = load_ton_address(addr, &_conf)
        .map_err(|e| format!("failed to parse address: {}", e.to_string()))?;

    let abi = load_abi(&abi)?;

    let now = now();
    let expire_at = lifetime + now;
    let header = FunctionHeader {
        expire: Some(expire_at),
        time: None,
        pubkey: None,
    };

    let msg = prepare_message(
        ton.clone(),
        &ton_addr,
        abi,
        method,
        params,
        Some(header),
        keys,
    ).await?;
    print_encoded_message(&msg);

    let msg_bytes = pack_message(&msg, method, is_raw);
    if output.is_some() {
        let out_file = output.unwrap();
        std::fs::write(out_file, msg_bytes)
            .map_err(|e| format!("cannot write message to file: {}", e))?;
        eprintln!("Message saved to file {}", out_file);
    } else {
        let msg_hex = hex::encode(&msg_bytes);
        eprintln!("Message: {}", msg_hex);
        eprintln!();
        qr2term::print_qr(msg_hex).unwrap();
        eprintln!();
    }
    Ok(())
}

pub async fn call_contract_with_msg(conf: Config, str_msg: String, abi: String) -> Result<(), String> {
    let ton = create_client_verbose(&conf)?;
    let abi = load_abi(&abi)?;

    let (msg, _) = unpack_message(&str_msg)?;
    print_encoded_message(&msg);

    let params = decode_call_parameters(ton.clone(), &msg, abi.clone()).await?;

    eprintln!("Calling method {} with parameters:", params.0);
    eprintln!("{}", params.1);
    eprintln!("Processing... ");

    let result = send_message_and_wait(ton, &msg.address, abi, msg.message, false).await?;

    eprintln!("Succeded.");
    if !result.is_null() {
        eprintln!("Result: {}", serde_json::to_string_pretty(&result).unwrap());
    }
    Ok(())
}

pub fn parse_params(params_vec: Vec<&str>, abi: &str, method: &str) -> Result<String, String> {
    if params_vec.len() == 1 {
        // if there is only 1 parameter it must be a json string with arguments
        Ok(params_vec[0].to_owned())
    } else {
        build_json_from_params(params_vec, abi, method)
    }
}

pub async fn run_get_method(conf: Config, addr: &str, method: &str, params: Option<String>) -> Result<(), String> {
    let ton = create_client_verbose(&conf)?;

    let addr = load_ton_address(addr, &conf)
        .map_err(|e| format!("failed to parse address: {}", e.to_string()))?;

    let acc_boc = query_account_boc(ton.clone(), addr.as_str()).await?;

    let params = params.map(|p| serde_json::from_str(&p))
        .transpose()
        .map_err(|e| format!("arguments are not in json format: {}", e))?;

    eprintln!("Running get-method...");
    let result = run_get(
        ton,
        ParamsOfRunGet {
            account: acc_boc,
            function_name: method.to_owned(),
            input: params,
            execution_options: None,
        },
    ).await
    .map_err(|e| format!("run failed: {}", e.to_string()))?
    .output;

    eprintln!("Succeded.");
    eprintln!("Result: {}", result);
    Ok(())
}

*/

pub async fn encode_body_rs(abi: &str, func: &str, params: &str) -> Result<String, ocp::Error> {
    let abi = load_abi(&abi)?;
    let params = serde_json::from_str(&params)
        .map_err(|e|
                 ocp::error(ocp::ERROR_INVALID_JSON_PARAMS,
                     format!("{:#}", e)))?;
    let client = create_client_local()?;
    ton_client::abi::encode_message_body(
        client.clone(),
        ParamsOfEncodeMessageBody {
            abi: abi,
            call_set: CallSet::some_with_function_and_input(func, params).unwrap(),
            is_internal: true,
            signer: Signer::None,
            processing_try_index: None,
        },
    ).await
        .map_err(|e| ocp::error(
            ocp::ERROR_ENCODE_MESSAGE_FAILED,
            format!("{:#}", e)))
    .map(|r| r.body)
}
