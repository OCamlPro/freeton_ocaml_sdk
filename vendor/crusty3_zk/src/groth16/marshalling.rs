use std::io::{self, Read, Write};
use crate::bls::{Engine, PairingCurveAffine, Bls12, Fr, Fq, Fq2, Fq6, Fq12, FqRepr, FrRepr};
use ff::{Field, PrimeField};
use groupy::{CurveAffine, CurveProjective, EncodedPoint};
use rayon::prelude::*;

use std::error;
use std::fmt;

use byteorder::{ByteOrder, BigEndian, LittleEndian};

use super::{multiscalar, PreparedVerifyingKey, Proof, VerifyingKey, GROTH16VerificationKey};
use crate::multicore::VERIFIER_POOL as POOL;
use crate::SynthesisError;

pub fn std_size_t_process(proof_bytes: &[u8]) -> Result<usize, Box<dyn error::Error>>{

    let std_size_byteblob_size = 4;

    let fr_byteblob : Vec<u8> = proof_bytes[..std_size_byteblob_size].to_vec();

    let mut dst = [0; 1];
    LittleEndian::read_u32_into(&fr_byteblob, &mut dst);

    let res = dst[0] as usize;
    Ok(res)
}

pub fn fr_process<E: Engine>(proof_bytes: &[u8]) -> Result<Fr, Box<dyn error::Error>>{

    let fr_byteblob_size = 32;

    let fr_byteblob : Vec<u8> = proof_bytes[..fr_byteblob_size].to_vec();

    let mut dst = [0; 4];
    LittleEndian::read_u64_into(&fr_byteblob, &mut dst);

    let fr_element = Fr::from_repr(FrRepr(dst))?;

    Ok(fr_element)
}

pub fn fp_process<E: Engine>(proof_bytes: &[u8]) -> Result<Fq, Box<dyn error::Error>>{

    let fp_byteblob_size = 48;

    let fp_byteblob : Vec<u8> = proof_bytes[..fp_byteblob_size].to_vec();

    let mut dst = [0; 6];
    LittleEndian::read_u64_into(&fp_byteblob, &mut dst);

    let fq_element = Fq::from_repr(FqRepr(dst))?;

    Ok(fq_element)
}

pub fn fp2_process<E: Engine>(proof_bytes: &[u8]) -> Result<Fq2, Box<dyn error::Error>>{

    let fp_byteblob_size = 48;

    let mut c0 = fp_process::<E>(&proof_bytes[..fp_byteblob_size])?;
    let mut c1 = fp_process::<E>(&proof_bytes[fp_byteblob_size..])?;

    let fq2_element = Fq2 {c0: c0, c1: c1};

    Ok(fq2_element)
}

pub fn fp6_3over2_process<E: Engine>(proof_bytes: &[u8]) -> Result<Fq6, Box<dyn error::Error>>{

    let fp_byteblob_size = 48;
    let fp2_byteblob_size = 2*fp_byteblob_size;

    let mut c0 = fp2_process::<E>(&proof_bytes[..fp2_byteblob_size])?;
    let mut c1 = fp2_process::<E>(&proof_bytes[fp2_byteblob_size..2*fp2_byteblob_size])?;
    let mut c2 = fp2_process::<E>(&proof_bytes[2*fp2_byteblob_size..])?;
    
    let fq6_3over2_element = Fq6 {c0: c0, c1: c1, c2: c2};

    Ok(fq6_3over2_element)
}

pub fn fp12_2over3over2_process<E: Engine>(proof_bytes: &[u8]) -> Result<Fq12, Box<dyn error::Error>>{

    let fp_byteblob_size = 48;
    let fp6_3over2_bytblob_size = 3*2*fp_byteblob_size;

    let mut c0_processed = fp6_3over2_process::<E>(&proof_bytes[..fp6_3over2_bytblob_size])?;
    let mut c1_processed = fp6_3over2_process::<E>(&proof_bytes[fp6_3over2_bytblob_size..])?;
    
    let fq12_2over3over2_element = Fq12 {c0: c0_processed, c1: c1_processed};

    Ok(fq12_2over3over2_element)
}

pub fn g1_affine_process<E: Engine>(proof_bytes: &[u8]) -> Result<E::G1Affine, Box<dyn error::Error>>{

    let g1_byteblob_size = <E::G1Affine as CurveAffine>::Compressed::size();

    let mut g1_repr = <E::G1Affine as CurveAffine>::Compressed::empty();
        let start = 0;
        let end = start + g1_byteblob_size;
        g1_repr.as_mut().copy_from_slice(&proof_bytes[start..end]);

    let g1_affine_element = g1_repr
        .into_affine()
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))
        .and_then(|e| {
            if e.is_zero() {
                Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "point at infinity",
                ))
            } else {
                Ok(e)
            }
        })?;

    Ok(g1_affine_element)
}

pub fn g2_affine_process<E: Engine>(proof_bytes: &[u8]) -> Result<E::G2Affine, Box<dyn error::Error>>{

    let g2_byteblob_size = <E::G2Affine as CurveAffine>::Compressed::size();

    let mut g2_repr = <E::G2Affine as CurveAffine>::Compressed::empty();
        let start = 0;
        let end = start + g2_byteblob_size;
        g2_repr.as_mut().copy_from_slice(&proof_bytes[start..end]);

    let g2_affine_element = g2_repr
        .into_affine()
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))
        .and_then(|e| {
            if e.is_zero() {
                Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "point at infinity",
                ))
            } else {
                Ok(e)
            }
        })?;

    Ok(g2_affine_element)
}

#[derive(Debug, Clone)]
struct MarshallingError;

impl fmt::Display for MarshallingError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "invalid first item to double")
    }
}

impl error::Error for MarshallingError {}

pub fn accumulation_vector_process<E: Engine>(proof_bytes: &[u8]) -> Result<Vec<E::G1Affine>, Box<dyn error::Error>>{
    let std_size_byteblob_size = 4;

    let g1_byteblob_size = <E::G1Affine as CurveAffine>::Compressed::size();
    // let accumulation_vector_size = (proof_bytes.len() - std_size_byteblob_size)/g1_byteblob_size;

    let mut accumulation_vector = Vec::new();

    if (proof_bytes.get(g1_byteblob_size + std_size_byteblob_size) == None){
        {Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "point at infinity",
                ))}?;
    };

    let first = g1_affine_process::<E>(&proof_bytes[..g1_byteblob_size])?;

    accumulation_vector.push(first);

    let indices_count = std_size_t_process(&proof_bytes[g1_byteblob_size..g1_byteblob_size + std_size_byteblob_size])?;

    // skip indices:
    let accumulation_vector_g1s_byteblob_begin = g1_byteblob_size + (1 + indices_count) * std_size_byteblob_size;

    if (proof_bytes.get(accumulation_vector_g1s_byteblob_begin + indices_count*g1_byteblob_size) == None){
        {Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "point at infinity",
                ))}?;
    };

    for i in 0..indices_count {
        let i_element = g1_affine_process::<E>(&proof_bytes[accumulation_vector_g1s_byteblob_begin + i*g1_byteblob_size..accumulation_vector_g1s_byteblob_begin + (i+1)*g1_byteblob_size])?;

        accumulation_vector.push(i_element);
    }

    // there is also domain size written in byteblob, but we don't need it

    Ok(accumulation_vector)
}

pub fn groth16_vk_from_byteblob(proof_bytes: &[u8]) -> Result<GROTH16VerificationKey::<Bls12>, Box<dyn error::Error>>{
    let fp_byteblob_size = 48;
    let fqk_byteblob_size = 2*3*2*fp_byteblob_size;
    let g1_byteblob_size = <<Bls12 as Engine>::G1Affine as CurveAffine>::Compressed::size();
    let g2_byteblob_size = <<Bls12 as Engine>::G2Affine as CurveAffine>::Compressed::size();

    let mut alpha_g1_beta_g2_processed = fp12_2over3over2_process::<Bls12>(&proof_bytes[..fqk_byteblob_size])?;
    let mut gamma_g2_processed = g2_affine_process::<Bls12>(&proof_bytes[fqk_byteblob_size..fqk_byteblob_size+g2_byteblob_size])?;
    let mut delta_g2_processed = g2_affine_process::<Bls12>(&proof_bytes[fqk_byteblob_size+g2_byteblob_size..fqk_byteblob_size+2*g2_byteblob_size])?;

    let mut ic_processed = accumulation_vector_process::<Bls12>(&proof_bytes[fqk_byteblob_size+2*g2_byteblob_size..])?;

    let mut alpha_g1_beta_g2_processed = alpha_g1_beta_g2_processed as <paired::bls12_381::Bls12 as Engine>::Fqk;
    let mut gamma_g2_processed = gamma_g2_processed as <paired::bls12_381::Bls12 as Engine>::G2Affine;
    let mut delta_g2_processed = delta_g2_processed as <paired::bls12_381::Bls12 as Engine>::G2Affine;
    let mut ic_processed = ic_processed as Vec<<paired::bls12_381::Bls12 as Engine>::G1Affine>;

    let groth16_key = GROTH16VerificationKey::<Bls12>{
            alpha_g1_beta_g2: alpha_g1_beta_g2_processed,
            gamma_g2: gamma_g2_processed,
            delta_g2: delta_g2_processed,
            ic: ic_processed
        };

    Ok(groth16_key)
}

pub fn groth16_proof_from_byteblob<E: Engine>(proof_bytes: &[u8]) -> Result<Proof<E>, Box<dyn error::Error>>{
    
    let g1_byteblob_size = <E::G1Affine as CurveAffine>::Compressed::size();
    let g2_byteblob_size = <E::G2Affine as CurveAffine>::Compressed::size();

    let proof_byteblob_size = g1_byteblob_size + g2_byteblob_size + g1_byteblob_size;

    let de_prf = Proof::<E>::read(&proof_bytes[..proof_byteblob_size])?;

    Ok(de_prf)
}

pub fn groth16_primary_input_from_byteblob<E: Engine>(proof_bytes: &[u8]) -> Result<Vec<Fr>, Box<dyn error::Error>>{
    
    let fr_byteblob_size = 32;
    let groth16_primary_input_size = proof_bytes.len()/fr_byteblob_size;
    let mut groth16_primary_input = Vec::new();

    for i in 0..groth16_primary_input_size {
        groth16_primary_input.push(fr_process::<E>(&proof_bytes[i*fr_byteblob_size.. (i+1)*fr_byteblob_size])?);
    }

    Ok(groth16_primary_input)
}