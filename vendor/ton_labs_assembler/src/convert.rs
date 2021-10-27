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


use num::{bigint::Sign, BigInt};

#[inline]
fn bits_to_bytes(length_in_bits: usize) -> usize {
    (length_in_bits + 7) >> 3
}

#[inline]
fn bitsize(value: &BigInt) -> usize {
    if (value == &0.into()) || (value == &(-1).into()) {
        return 1
    }
    let res = value.bits();
    if value.sign() == Sign::Plus {
        return res + 1
    }
    // For negative values value.bits() returns correct result only when value is power of 2.
    let mut modpow2 = -value;
    modpow2 &= &modpow2 - 1;
    if modpow2.sign() == Sign::NoSign {
        return res
    }
    res + 1
}

/// Encodes value as big endian octet string for PUSHINT primitive using the format
/// from TVM Spec A.3.1:
///  "82lxxx — PUSHINT xxx, where 5-bit 0 ≤ l ≤ 30 determines the length n = 8l + 19
///  of signed big-endian integer xxx. The total length of this instruction
///  is l + 4 bytes or n + 13 = 8l + 32 bits."
pub fn to_big_endian_octet_string(value: &BigInt) -> Option<Vec<u8>> {
    let mut n = bitsize(value);
    if n > 257 {
        return None
    }
    if n < 19 {
        n = 19;
    } else {
        let excessive = n & 0b111;
        if excessive == 0 || excessive > 3 {
            // Rounding to full octet and adding 3.
            n = (((n + 7) as isize & -8) + 3) as usize;
        } else {
            n += 3 - excessive;
        }
    };

    let bytelen = bits_to_bytes(n);
    let mut serialized_val = value.to_signed_bytes_be();
    let prefixlen = bytelen - serialized_val.len();
    let mut ret: Vec<u8> = Vec::with_capacity(bytelen);
    let is_negative = value.sign() == Sign::Minus;
    let mut prefix: Vec<u8> = if prefixlen == 0 {
        let new_serialized_val = serialized_val.split_off(1);
        let first_element = serialized_val;
        serialized_val = new_serialized_val;
        first_element
    } else if is_negative {
        vec![0xFF; prefixlen]
    } else {
        vec![0x00; prefixlen]
    };
    debug_assert_eq!((n - 19) & 0b111, 0);
    prefix[0] = (n - 19) as u8 | (prefix[0] & 0b111);

    ret.append(&mut prefix);
    ret.append(&mut serialized_val);
    Some(ret)
}

// /// Constructs new BigInt value from the little-endian slice of u32
// /// with overflow checking.
// #[inline]
// fn from_vec_le(sign: num::bigint::Sign, digits: Vec<u32>) -> Result<BigInt> {
//     let bigint = BigInt::new(sign, digits);
//     if !check_overflow(&bigint) {
//         fail!("integer overflow")
//     }
//     Ok(bigint)
// }

// #[inline]
// fn check_overflow(value: &BigInt) -> bool {
//     bitsize(value) < 258
// }
