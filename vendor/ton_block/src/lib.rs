/*
* Copyright 2018-2020 TON DEV SOLUTIONS LTD.
*
* Licensed under the SOFTWARE EVALUATION License (the "License"); you may not use
* this file except in compliance with the License.
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific TON DEV software governing permissions and
* limitations under the License.
*/

#![cfg_attr(feature = "ci_run", deny(warnings))]

pub mod error;
pub use self::error::*;

pub mod types;
pub use self::types::*;

pub mod hashmapaug;
pub use self::hashmapaug::*;

pub mod blocks;
pub use self::blocks::*;

pub mod shard;
pub use self::shard::*;

pub mod accounts;
pub use self::accounts::*;

pub mod messages;
pub use self::messages::*;

pub mod inbound_messages;
pub use self::inbound_messages::*;

pub mod master;
pub use self::master::*;

pub mod envelope_message;
pub use self::envelope_message::*;

pub mod outbound_messages;
pub use self::outbound_messages::*;

pub mod shard_accounts;
pub use self::shard_accounts::*;

pub mod transactions;
pub use self::transactions::*;

pub mod bintree;
pub use self::bintree::*;

pub mod out_actions;
pub use self::out_actions::*;

pub mod merkle_proof;
pub use self::merkle_proof::*;

pub mod merkle_update;
pub use self::merkle_update::*;

pub mod validators;
pub use self::validators::*;

pub mod miscellaneous;
pub use self::miscellaneous::*;

pub mod signature;
pub use self::signature::*;

pub mod signed_block;
pub use self::signed_block::*;

pub mod config_params;
pub use self::config_params::*;

use std::{collections::HashMap, hash::Hash};
use ton_types::{
    fail, Result,
    AccountId, UInt256,
    BuilderData, Cell, IBitstring, SliceData, HashmapE, HashmapType,
};

impl<K, V> Serializable for HashMap<K, V>
where
    K: Clone + Eq + Hash + Default + Deserializable + Serializable,
    V: Serializable
{
    fn write_to(&self, cell: &mut BuilderData) -> Result<()> {
        let bit_len = K::default().write_to_new_cell()?.length_in_bits();
        let mut dictionary = HashmapE::with_bit_len(bit_len);
        for (key, value) in self.iter() {
            let key = key.serialize()?;
            dictionary.set_builder(key.into(), &value.write_to_new_cell()?)?;
        }
        dictionary.write_to(cell)
    }
}

impl<K, V> Deserializable for HashMap<K, V>
where
    K: Eq + Hash + Default + Deserializable + Serializable,
    V: Deserializable + Default
{
    fn read_from(&mut self, slice: &mut SliceData) -> Result<()> {
        let bit_len = K::default().write_to_new_cell()?.length_in_bits();
        let mut dictionary = HashmapE::with_bit_len(bit_len);
        dictionary.read_hashmap_data(slice)?;
        dictionary.iterate_slices(|ref mut key, ref mut value| {
            let key = K::construct_from(key)?;
            let value = V::construct_from(value)?;
            self.insert(key, value);
            Ok(true)
        }).map(|_|())
    }
}

impl Serializable for HashmapE {
    fn write_to(&self, cell: &mut BuilderData) -> Result<()> {
        self.write_hashmap_data(cell)?;
        Ok(())
    }
}

impl Deserializable for HashmapE {
    fn read_from(&mut self, slice: &mut SliceData) -> Result<()> {
        self.read_hashmap_data(slice)?;
        Ok(())
    }
}

pub trait Serializable {
    fn write_to(&self, cell: &mut BuilderData) -> Result<()>;

    fn write_to_new_cell(&self) -> Result<BuilderData> {
        let mut cell = BuilderData::new();
        self.write_to(&mut cell)?;
        Ok(cell)
    }

    fn write_to_bytes(&self) -> Result<Vec<u8>> {
        let cell = self.serialize()?;
        ton_types::serialize_toc(&cell)
    }

    fn write_to_file(&self, file_name: impl AsRef<std::path::Path>) -> Result<()> {
        let bytes = self.write_to_bytes()?;
        std::fs::write(file_name.as_ref(), bytes)?;
        Ok(())
    }

    fn serialize(&self) -> Result<Cell> {
        self.write_to_new_cell()?.into_cell()
    }
}

pub trait Deserializable: Default {
    fn construct_from(slice: &mut SliceData) -> Result<Self> {
        let mut x = Self::default();
        x.read_from(slice)?;
        Ok(x)
    }
    fn construct_maybe_from(slice: &mut SliceData) -> Result<Option<Self>> {
        match slice.get_next_bit()? {
            true => Ok(Some(Self::construct_from(slice)?)),
            false => Ok(None)
        }
    }
    fn construct_from_cell(cell: Cell) -> Result<Self> {
        Self::construct_from(&mut cell.into())
    }
    fn construct_from_reference(slice: &mut SliceData) -> Result<Self> {
        Self::construct_from_cell(slice.checked_drain_reference()?)
    }
    /// adapter for tests
    fn construct_from_bytes(bytes: &[u8]) -> Result<Self> {
        let cell = ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(bytes))?;
        Self::construct_from(&mut cell.into())
    }
    /// adapter for tests
    fn construct_from_file(file_name: impl AsRef<std::path::Path>) -> Result<Self> {
        let bytes = std::fs::read(file_name.as_ref())?;
        Self::construct_from_bytes(&bytes)
    }
    /// adapter for tests
    fn construct_from_base64(string: &str) -> Result<Self> {
        let bytes = base64::decode(string)?;
        Self::construct_from_bytes(&bytes)
    }
    // Override it to implement skipping
    fn skip(slice: &mut SliceData) -> Result<()> {
        Self::construct_from(slice)?;
        Ok(())
    }
    fn read_from(&mut self, slice: &mut SliceData) -> Result<()> {
        *self = Self::construct_from(slice)?;
        Ok(())
    }
    fn read_from_cell(&mut self, cell: Cell) -> Result<()> {
        self.read_from(&mut cell.into())
    }
    fn read_from_reference(&mut self, slice: &mut SliceData) -> Result<()> {
        self.read_from_cell(slice.checked_drain_reference()?)
    }
}

pub trait MaybeSerialize {
    fn write_maybe_to(&self, cell: &mut BuilderData) -> Result<()>;
}

impl Deserializable for Cell {
    fn read_from(&mut self, cell: &mut SliceData) -> Result<()> {
        *self = cell.checked_drain_reference()?;
        Ok(())
    }
}

impl Serializable for Cell {
    fn write_to(&self, cell: &mut BuilderData) -> Result<()> {
        cell.append_reference_cell(self.clone());
        Ok(())
    }
}
/* for future use
impl Serializable for SliceData {
    fn write_to_new_cell(&self) -> Result<BuilderData> {
        Ok(BuilderData::from_slice(self))
    }
    fn write_to(&self, cell: &mut BuilderData) -> Result<()> {
        cell.checked_append_references_and_data(self)?;
        Ok(())
    }
}
*/
impl<T: Serializable> MaybeSerialize for Option<T> {
    fn write_maybe_to(&self, cell: &mut BuilderData) -> Result<()> {
        match self {
            Some(x) => {
                cell.append_bit_one()?;
                x.write_to(cell)?;
            }
            None => {
                cell.append_bit_zero()?;
            }
        }
        Ok(())
    }
}

pub trait MaybeDeserialize {
    fn read_maybe_from<T: Deserializable + Default> (slice: &mut SliceData) -> Result<Option<T>> {
        match slice.get_next_bit_int()? {
            1 => Ok(Some(T::construct_from(slice)?)),
            _ => Ok(None)
        }
    }
}

impl<T: Deserializable> MaybeDeserialize for T {}

pub trait GetRepresentationHash: Serializable + std::fmt::Debug {
    fn hash(&self) -> Result<UInt256> {
        match self.serialize() {
            Err(err) => {
                log::error!("err: {}, wrong hash calculation for {:?}", err, self);
                Err(err)
            }
            Ok(cell) => Ok(cell.repr_hash())
        }
    }
}

impl<T: Serializable + std::fmt::Debug> GetRepresentationHash for T {}

impl Deserializable for UInt256 {
    fn construct_from(slice: &mut SliceData) -> Result<Self> {
        slice.get_next_hash()
    }
}

impl Serializable for UInt256 {
    fn write_to(&self, cell: &mut BuilderData) -> Result<()> {
        cell.append_raw(self.as_slice(), 256)?;
        Ok(())
    }
}

impl Deserializable for AccountId {
    fn read_from(&mut self, cell: &mut SliceData) -> Result<()> {
        *self = cell.get_next_slice(256)?;
        Ok(())
    }
}

impl Serializable for AccountId {
    fn write_to(&self, cell: &mut BuilderData) -> Result<()> {
        if self.remaining_bits() != 256 {
            fail!("account_id must contain 256 bits, but {}", self.remaining_bits())
        }
        cell.append_bytestring(self)?;
        Ok(())
    }
}

impl Deserializable for () {
    fn read_from(&mut self, cell: &mut SliceData) -> Result<()> {
        if cell.remaining_bits() == 0 && cell.remaining_references() == 0 {
            Ok(())
        } else {
            fail!("It must be True by TLB, but some data is present: {:x}", cell)
        }
    }
}

impl Serializable for () {
    fn write_to(&self, _cell: &mut BuilderData) -> Result<()> {
        Ok(())
    }
}

pub fn id_from_key(key: &ed25519_dalek::PublicKey) -> u64 {
    let bytes = key.to_bytes();
    u64::from_be_bytes([ 
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5], bytes[6], bytes[7],
    ])
}

