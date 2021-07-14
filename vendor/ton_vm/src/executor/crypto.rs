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

use crate::{
    error::TvmError, 
    executor::{
        engine::{Engine, storage::fetch_stack}, types::Instruction
    },
    stack::{
        StackItem,
        integer::{
            IntegerData, 
            serialization::{Encoding, IntoSliceExt, UnsignedIntegerBigEndianEncoding}
        },
        serialization::Deserializer
    },
    types::{Exception, Failure}
};
use sha2::Digest;
use ed25519::signature::{Signature, Verifier};
use std::sync::Arc;
use ton_types::{BuilderData, Cell, error, GasConsumer, types::ExceptionCode};

use crusty3_zk::{groth16::{verify_proof, prepare_verifying_key, Parameters, verify_groth16_proof_from_byteblob},
                 bls::{Bls12, Fr}
                };


const PUBLIC_KEY_BITS:  usize = PUBLIC_KEY_BYTES * 8;
const SIGNATURE_BITS:   usize = SIGNATURE_BYTES * 8;
const PUBLIC_KEY_BYTES: usize = ed25519_dalek::PUBLIC_KEY_LENGTH;
const SIGNATURE_BYTES:  usize = ed25519_dalek::SIGNATURE_LENGTH;

/// HASHCU (c – x), computes the representation hash of a Cell c
/// and returns it as a 256-bit unsigned integer x.
pub(super) fn execute_hashcu(engine: &mut Engine) -> Failure {
    engine.load_instruction(Instruction::new("HASHCU"))
        .and_then(|ctx| fetch_stack(ctx, 1))
        .and_then(|ctx| {
            let hash_int = hash_to_uint(&ctx.engine.cmd.var(0).as_cell()?.repr_hash());
            ctx.engine.cc.stack.push(StackItem::Integer(hash_int));
            Ok(ctx)
        })
        .err()
}

/// Computes the hash of a Slice s and returns it as a 256-bit unsigned integer x. 
/// The result is the same as if an ordinary cell containing only data 
/// and references from s had been created and its hash computed by HASHCU.
pub(super) fn execute_hashsu(engine: &mut Engine) -> Failure {
    engine.load_instruction(Instruction::new("HASHSU"))
        .and_then(|ctx| fetch_stack(ctx, 1))
        .and_then(|ctx| {
            let builder = BuilderData::from_slice(ctx.engine.cmd.var(0).as_slice()?);
            let cell = ctx.engine.finalize_cell(builder)?;
            let hash_int = hash_to_uint(&cell.repr_hash());
            ctx.engine.cc.stack.push(StackItem::Integer(hash_int));
            Ok(ctx)
        })
        .err()
}

// SHA256U ( s – x )
// Computes sha256 of the data bits of Slices.
// If the bit length of s is not divisible by eight, throws a cell underflow exception. 
// The hash value is returned as a 256-bit unsigned integer x.
pub(super) fn execute_sha256u(engine: &mut Engine) -> Failure {
    engine.load_instruction(Instruction::new("SHA256U"))
        .and_then(|ctx| fetch_stack(ctx, 1))
        .and_then(|ctx| {
            let slice = ctx.engine.cmd.var(0).as_slice()?;
            if slice.remaining_bits() % 8 == 0 {
                let mut hasher = sha2::Sha256::new();
                hasher.input(slice.get_bytestring(0));
                let hash_int = hash_to_uint(hasher.result());
                ctx.engine.cc.stack.push(StackItem::Integer(hash_int));
                Ok(ctx)
            }else {
                err!(ExceptionCode::CellUnderflow)
            }
        })
        .err()
}

pub fn obtain_cells_data(cl: Cell) -> Result<Vec<u8>, Failure> {
	let mut byte_blob = Vec::new();
    let mut queue = vec!(cl.clone());
    while let Some(cell) = queue.pop() {
        let this_reference_data = cell.data();
        
        byte_blob.extend(this_reference_data[0..this_reference_data.len()-1].iter().copied());

        let count = cell.references_count();
        for i in 0..count {
            queue.push(cell.reference(i)?);
        }
    }

    Ok(byte_blob)
}

pub(super) fn execute_vergrth16(engine: &mut Engine) -> Failure {
    engine.load_instruction(Instruction::new("VERGRTH16"))
        .and_then(|ctx| fetch_stack(ctx, 1))
        .and_then(|ctx| {
            let builder = BuilderData::from(ctx.engine.cmd.var(0).as_cell()?);
            let cell_proof_data_length = builder.length_in_bits();
	    
            let cell_proof = ctx.engine.finalize_cell(builder)?;
            
            let mut cell_proof_data = obtain_cells_data(cell_proof).unwrap();
	    
            if cell_proof_data_length % 8 == 0 {
		
                let result = verify_groth16_proof_from_byteblob::<Bls12>(&cell_proof_data[..]).unwrap();

                ctx.engine.cc.stack.push(boolean!(result));
                Ok(ctx)
            } else {
                err!(ExceptionCode::CellUnderflow)
            }
        })
        .err()
}

//CHKSIGNS(d s k–?)
// checks whethersis a valid Ed25519-signature of the data portion of Slice d using public key k,
// similarly to CHKSIGNU. If the bit length of Slice d is not divisible by eight, 
// throws a cell underflow exception. The verification of Ed25519 signatures is the standard one, 
// with sha256 used to reduce d to the 256-bit number that is actually signed.
pub(super) fn execute_chksigns(engine: &mut Engine) -> Failure {
    engine.load_instruction(Instruction::new("CHKSIGNS"))
        .and_then(|ctx| fetch_stack(ctx, 3))
        .and_then(|ctx| {
            let pub_key = ctx.engine.cmd.var(0).as_integer()?
                .into_builder::<UnsignedIntegerBigEndianEncoding>(PUBLIC_KEY_BITS)?;
            if (ctx.engine.cmd.var(1).as_slice()?.remaining_bits() < SIGNATURE_BITS) &&
               (ctx.engine.cmd.var(2).as_slice()?.remaining_bits() % 8 != 0) {
                return err!(ExceptionCode::CellUnderflow)
            }
            let pub_key = ed25519_dalek::PublicKey::from_bytes(
                &pub_key.data()[..PUBLIC_KEY_BYTES]
            ).map_err(|_| exception!(ExceptionCode::FatalError))?;
            let signature = ed25519::Signature::from_bytes(
                &ctx.engine.cmd.var(1).as_slice()?.get_bytestring(0)[..SIGNATURE_BYTES]
            ).map_err(|_| exception!(ExceptionCode::FatalError))?;

            let data = ctx.engine.cmd.var(2).as_slice()?.get_bytestring(0);
            let result = pub_key.verify(&data, &signature).is_ok();
            ctx.engine.cc.stack.push(boolean!(result));
            Ok(ctx)
        })
        .err()
}

/// CHKSIGNU (h s k – -1 or 0)
/// checks the Ed25519-signature s (slice) of a hash h (a 256-bit unsigned integer)
/// using public key k (256-bit unsigned integer).
pub(super) fn execute_chksignu(engine: &mut Engine) -> Failure {
    engine.load_instruction(Instruction::new("CHKSIGNU"))
        .and_then(|ctx| fetch_stack(ctx, 3))
        .and_then(|ctx| {
            let pub_key = ctx.engine.cmd.var(0).as_integer()?
                .into_builder::<UnsignedIntegerBigEndianEncoding>(PUBLIC_KEY_BITS)?;
            ctx.engine.cmd.var(1).as_slice()?;
            let hash = ctx.engine.cmd.var(2).as_integer()?
                .into_builder::<UnsignedIntegerBigEndianEncoding>(256)?;
            if ctx.engine.cmd.var(1).as_slice()?.remaining_bits() < SIGNATURE_BITS {
                return err!(ExceptionCode::CellUnderflow)
            }
            let signature = ctx.engine.cmd.var(1).as_slice()?.get_bytestring(0);

            let mut result = false;
            if let Ok(signature) = ed25519::Signature::from_bytes(&signature[..SIGNATURE_BYTES]) {
                if let Ok(pub_key) = ed25519_dalek::PublicKey::from_bytes(&pub_key.data()) {
                    result = pub_key.verify(hash.data(), &signature).is_ok();
                }
            }
            ctx.engine.cc.stack.push(boolean!(result));
            Ok(ctx)
        })
        .err()
}       

fn hash_to_uint<T: AsRef<[u8]>>(bits: T) -> Arc<IntegerData> {
    Arc::new(UnsignedIntegerBigEndianEncoding::new(256)
        .deserialize(bits.as_ref()))
}
