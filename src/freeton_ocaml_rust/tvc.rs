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

/* Inspired from ton_client/src/boc/tvc.rs */


use std::io::Cursor;
use ton_types::{//Cell, SliceData,
    BuilderData,
    //IBitstring
};
use ton_types::cells_serialization::{
    //BagOfCells,
    deserialize_cells_tree};

use ton_block::StateInit;
use ton_block::Deserializable;
use ton_types::cells_serialization::serialize_tree_of_cells;

// TODO: handle errors !!!
pub fn load_from_file(contract_file: &str) -> StateInit {
    let mut csor = Cursor::new(std::fs::read(contract_file).unwrap());
    let mut cell = deserialize_cells_tree(&mut csor).unwrap().remove(0);
    // try appending a dummy library cell if there is no such cell in the tvc file
    if cell.references_count() == 2 {
        let mut adjusted_cell = BuilderData::from(cell);
        adjusted_cell.append_reference(BuilderData::default());
        cell = adjusted_cell.into();
    }
    StateInit::construct_from_cell(cell).expect("StateInit construction failed")
}

fn tree_of_cells_into_base64(root_cell: Option<&ton_types::Cell>) -> String {
    match root_cell {
        Some(cell) => {
            let mut bytes = Vec::new();
            serialize_tree_of_cells(cell, &mut bytes).unwrap();
            base64::encode(&bytes)
        }
        None => "None".to_string()
    }
}

pub fn state_init_data( state : &StateInit ) -> String {
    tree_of_cells_into_base64 ( state.data.as_ref() )
}

pub fn state_init_code( state : &StateInit ) -> String {
    tree_of_cells_into_base64 ( state.code.as_ref() )
}

pub fn state_init_code_hash( state : &StateInit ) -> String {
    state.code.clone().unwrap().repr_hash().to_hex_string()
}

pub fn state_init_code_depth( state : &StateInit ) -> u32 {
    state.code.clone().unwrap().repr_depth() as u32
}

pub fn state_init_data_hash( state : &StateInit ) -> String {
    state.data.clone().unwrap().repr_hash().to_hex_string()
}

pub fn state_init_data_depth( state : &StateInit ) -> u32 {
    state.data.clone().unwrap().repr_depth() as u32
}



/*
pub fn get_code_hash
state.code.clone().unwrap().repr_hash().to_hex_string(),
*/
