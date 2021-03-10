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

use crate::client::{create_client_local, WORD_COUNT};

use ton_client::crypto::{
    mnemonic_from_random,ParamsOfMnemonicFromRandom
};

pub fn gen_seed_phrase_rs() -> Result<String, ocp::Error > {
    let client = create_client_local()?;
    let r = mnemonic_from_random(
        client,
        ParamsOfMnemonicFromRandom {
            dictionary: Some(1),
            word_count: Some(WORD_COUNT),
        },
    )
        .map_err(|e|
                 ocp::error(ocp::ERROR_MNEMONIC_FROM_RANDOM,
                             format!("{}", e)))?;
    Ok(r.phrase)
}


#[ocaml::func]
pub fn gen_seed_phrase_ml() -> ocp::Reply<String> {
    ocp::reply(gen_seed_phrase_rs())
}


