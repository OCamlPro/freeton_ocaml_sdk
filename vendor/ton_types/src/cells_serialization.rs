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


use std::collections::{HashMap, HashSet};
use std::fmt;
use std::io::{Read, Write};

use crc::{crc32, Hasher32};

use crate::cell::{Cell, CellType, DataCell, LevelMask};
use crate::types::ByteOrderRead;
use crate::types::UInt256;
use crate::{Result, fail};
use smallvec::SmallVec;

pub const SHA256_SIZE: usize = 32;
pub const DEPTH_SIZE: usize = 2;

const BOC_INDEXED_TAG: u32 = 0x68ff65f3;
const BOC_INDEXED_CRC32_TAG: u32 = 0xacc3a728;
const BOC_GENERIC_TAG: u32 = 0xb5ee9c72;

#[derive(PartialEq, Eq, Debug, Clone)]
pub enum BocSerialiseMode {
    Indexed,
    IndexedCrc,
    Generic {
        index: bool,
        crc: bool,
        cache_bits: bool,
        flags: u8, // 2 bits. Is not used for now
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct BagOfCells {
    cells: HashMap<UInt256, Cell>,
    sorted_rev: Vec<UInt256>,
    absent: HashSet<UInt256>,
    roots_indexes_rev: Vec<usize>,
    absent_count: usize,
}

impl BagOfCells {
    pub fn with_root(root_cell: &Cell) -> Self {
        Self::with_roots_and_absent(vec!(root_cell), Vec::new())
    }
    
    pub fn with_roots(root_cells: Vec<&Cell>) -> Self {
        Self::with_roots_and_absent(root_cells, Vec::new())
    }
    
    pub fn with_roots_and_absent(root_cells: Vec<&Cell>, absent_cells: Vec<&Cell>) -> Self {
        let mut	cells = HashMap::<UInt256, Cell>::new();
        let mut sorted_rev = Vec::<UInt256>::new();
        let mut absent_cells_hashes = HashSet::<UInt256>::new();

        for cell in absent_cells.iter() {
            absent_cells_hashes.insert(cell.repr_hash());
        }

        let mut roots_indexes_rev = Vec::with_capacity(root_cells.len());
        for root_cell in root_cells.iter() {
            Self::traverse(root_cell, &mut cells, &mut sorted_rev, &absent_cells_hashes);
            roots_indexes_rev.push(sorted_rev.len() - 1); // root must be added into `sorted_rev` back
        }

        // roots must be firtst
        // TODO: due to real ton sorces it is not necceary to write roots first
        BagOfCells {
            cells,
            sorted_rev,
            absent: absent_cells_hashes,
            roots_indexes_rev,
            absent_count: absent_cells.len(),
        }
    }

    pub fn cells(&self) -> &HashMap<UInt256, Cell> {
        &self.cells
    }

    pub fn withdraw_cells(self) -> HashMap<UInt256, Cell> {
        self.cells
    }

    pub fn sorted_cells_hashes(&self) -> impl Iterator<Item = &UInt256> {
        self.sorted_rev.iter().rev()
    }

    pub fn roots_count(&self) -> usize {
        self.roots_indexes_rev.len()
    }

    pub fn cells_count(&self) -> usize {
        self.sorted_rev.len()
    }

    pub fn get_cell_by_index(&self, index: usize) -> Option<Cell> {
        if let Some(hash) = self.sorted_rev.get(index) {
            if let Some(cell) = self.cells.get(hash) {
                return Some(cell.clone());
            } else {
                panic!("Bag of cells is corrupted!");
            }
        } 
        None
    }
    
    pub fn write_to<T: Write>(&self, dest: &mut T, include_index: bool) -> Result<()> {
        self.write_to_ex(
            dest,
            BocSerialiseMode::Generic{
                index: include_index,
                crc: false,
                cache_bits: false,
                flags: 0 },
            None,
            None)
    }

    pub fn write_to_ex<T: Write>(&self, dest: &mut T, mode: BocSerialiseMode,
        custom_ref_size: Option<usize>, custom_offset_size: Option<usize>) -> Result<()> {
        
        let dest = &mut IoCrcFilter::new(dest);

        let ref_size = if let Some(crs) = custom_ref_size { crs } 
                        else { number_of_bytes_to_fit(self.cells.len()) };
        let total_cells_size = self.cells.iter().map(|(_, c)| self.cell_serialized_size(c, ref_size)).sum::<usize>();
        let offset_size = if let Some(cos) = custom_offset_size { cos } 
                            else { number_of_bytes_to_fit(total_cells_size) };

        assert!(ref_size <= 4);
        assert!(offset_size <= 8);

        let magic;
        let include_index;
        let mut include_crc = false;
        let mut include_cache_bits = false;
        let mut flags = 0;
        let mut include_root_list = false;

        match mode {
            BocSerialiseMode::Indexed => {
                include_index = true;
                magic = BOC_INDEXED_TAG;
            },
            BocSerialiseMode::IndexedCrc => {
                include_index = true;
                include_crc = true;
                magic = BOC_INDEXED_CRC32_TAG;
            },
            BocSerialiseMode::Generic {index, crc, cache_bits, flags: flags1} => {
                include_index = index;
                include_crc = crc;
                include_cache_bits = cache_bits;
                flags = flags1;
                magic = BOC_GENERIC_TAG;
                include_root_list = true;
            },
        };

        // TODO: CRC support
        if include_crc {
        //	unimplemented!(); 
        }
        // TODO: figre out what `include_cache_bits` is 
        if include_cache_bits {
        //	unimplemented!(); 
        }
        // TODO: investigate `flags` values possible meaning
        if flags != 0 {
        //	unimplemented!(); 
        }

        dest.write_all(&magic.to_be_bytes())?;
        // Header

        match mode {
            BocSerialiseMode::Indexed | BocSerialiseMode::IndexedCrc => {
                dest.write_all(&[ref_size as u8])?; // size:(## 8) { size <= 4 }
            },
            BocSerialiseMode::Generic {index, crc, cache_bits, flags} => {
                let mut b = ref_size as u8; // size:(## 3) { size <= 4 }
                if index { b |= 0b1000_0000; } // has_idx:(## 1) 
                if crc { b |= 0b0100_0000; } // has_crc32c:(## 1) 
                if cache_bits { b |= 0b0010_0000; } // has_cache_bits:(## 1)
                if flags != 0 { b |= flags << 3; }  // flags:(## 2) { flags = 0 }
                dest.write_all(&[b])?;
            },
        };

        dest.write_all(&[offset_size as u8])?; // off_bytes:(## 8) { off_bytes <= 8 }
        dest.write_all(&(self.cells.len() as u64).to_be_bytes()[(8-ref_size)..8])?;
        dest.write_all(&(self.roots_count() as u64).to_be_bytes()[(8-ref_size)..8])?;
        dest.write_all(&(self.absent_count as u64).to_be_bytes()[(8-ref_size)..8])?;
        dest.write_all(&(total_cells_size as u64).to_be_bytes()[(8-offset_size)..8])?;

        // Root list 
        if include_root_list {
            // Write root's indexes 
            for index in self.roots_indexes_rev.iter() {
                dest.write_all(&((self.cells.len() - *index - 1) as u64).to_be_bytes()[(8-ref_size)..8])?;
            }
        }

        // Index
        if include_index { 
            let mut total_size = 0;
            for cell_hash in self.sorted_rev.iter().rev() {
                total_size += self.cell_serialized_size(&self.cells[cell_hash], ref_size);
                let for_write = 
                    if !include_cache_bits { total_size }
                    else {
                        total_size << 1
                        // TODO: figre out what `include_cache_bits` is 
                    };
                dest.write_all(&(for_write as u64).to_be_bytes()[(8-offset_size)..8])?;
            }
        }

        // Cells
        let mut hashes_to_indexes = HashMap::<&UInt256, u32>::new();
        for (index, cell_hash) in self.sorted_rev.iter().rev().enumerate() {
            hashes_to_indexes.insert(cell_hash, index as u32);
        }

        for (cell_index, cell_hash) in self.sorted_rev.iter().rev().enumerate() {
            if let Some(cell) = &self.cells.get(cell_hash) {
                if self.absent.contains(cell_hash) {
                    Self::serialize_absent_cell(cell, dest)?;
                } else {
                    Self::serialize_ordinary_cell_data(cell, dest)?;
                    
                    for i in 0..cell.references_count() {
                        let child = cell.reference(i).unwrap();
                        let child_index = hashes_to_indexes[&child.repr_hash()] as u64;
                        assert!(child_index > cell_index as u64);
                        dest.write_all(&(child_index).to_be_bytes()[(8-ref_size)..8])?;
                    }
                }
            } else {
                panic!("Bag of cells is corrupted!");
            }
        }

        if include_crc {
            let crc = dest.sum32();
            dest.write_all(&crc.to_le_bytes())?;
        }

        Ok(())
    }

    fn traverse(cell: &Cell, cells: &mut HashMap<UInt256, Cell>, sorted: &mut Vec<UInt256>, 
        absent_cells: &HashSet<UInt256>) {

        let hash = cell.repr_hash();

        if !cells.contains_key(&hash) {
            if !absent_cells.contains(&hash) {
                for i in 0..cell.references_count() {
                    let child = cell.reference(i).unwrap();
                    Self::traverse(&child, cells, sorted, absent_cells);
                }
            }
            cells.insert(hash.clone(), cell.clone());
            sorted.push(hash);
        }
    }

    fn serialize_absent_cell(cell: &Cell, write: &mut dyn Write) -> Result<()> {
        
        // For absent cells (i.e., external references), only d1 is present, always equal to 23 + 32l.
        let l = cell.level();
        assert!(l == 0);
        assert_eq!(cell.bit_length(), SHA256_SIZE * 8);
        write.write_all(&[23 + 32 * l])?;
        write.write_all(&cell.data()[..SHA256_SIZE])?;
        Ok(())
    }

    /// Serialize ordinary cell data
    pub fn serialize_ordinary_cell_data(cell: &Cell, write: &mut dyn Write) -> Result<()> {
        let data_bit_len = cell.bit_length();

        // descriptor bytes
        let (d1, d2) = Self::calculate_descriptor_bytes(
            data_bit_len,
            cell.references_count() as u8,
            cell.level_mask().mask(),
            cell.cell_type() != CellType::Ordinary,
            cell.store_hashes());
        write.write_all(&[d1])?;
        write.write_all(&[d2])?;

        // hashes and depths if exists
        if cell.store_hashes() {
            for hash in cell.hashes() {
                write.write_all(hash.as_slice())?;
            }
            for depth in cell.depths() {
                write.write_all(&[(depth >> 8) as u8, (depth & 0xff) as u8])?;
            }
        }

        // data
        let data_size = (data_bit_len / 8) + if data_bit_len % 8 != 0 { 1 } else { 0 };
        write.write_all(&cell.data()[..data_size])?;

        Ok(())
    }

    pub fn calculate_descriptor_bytes(
        data_bit_len: usize,
        refs: u8,
        level_mask: u8,
        exotic: bool, 
        store_hashes: bool
    ) -> (u8, u8) {
        let h = if store_hashes { 1 } else { 0 };
        let s: u8 = if exotic { 1 } else { 0 };
        let d1 = (refs + 8 * s + 16 * h + 32 * level_mask) as u8;
        let d2 = (((data_bit_len / 8) << 1) | if data_bit_len % 8 != 0 { 1 } else { 0 }) as u8;
        (d1, d2)
    }

    /// Serialized cell size including descriptor bytes and competition tag
    pub fn cell_serialized_size(&self, cell: &Cell, ref_size: usize) -> usize {
        if self.absent.contains(&cell.repr_hash()) {
            1 +
            (1 + cell.level() as usize + 1) * SHA256_SIZE
        } else {
            let bits = cell.bit_length();
            2 +
            if cell.store_hashes() { (cell.level() as usize + 1) * (SHA256_SIZE + DEPTH_SIZE) } else { 0 } +
            (bits / 8) + if bits % 8 != 0 { 1 } else { 0 } +
            cell.references_count() * ref_size
        }
    }
}

#[rustfmt::skip]
impl fmt::Display for BagOfCells {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "total unique cells: {}", self.cells.len())?;
        for (n, index) in self.roots_indexes_rev.iter().enumerate() {
            let root = &self.cells[&self.sorted_rev[*index]];
            write!(f, "\nroot #{}:{:#.1024}", n, root)?;
        }
        Ok(())
    }
}

struct RawCell {
    pub cell_type: CellType,
    pub level: u8,
    pub data: SmallVec<[u8; 128]>,
    pub refs: SmallVec<[u32; 4]>,
    pub hashes: Option<[UInt256; 4]>,
    pub depths: Option<[u16; 4]>,
}

pub fn deserialize_tree_of_cells<T: Read>(src: &mut T) -> Result<Cell> {
    let mut cells = deserialize_cells_tree_ex(src).map(|(v, _, _, _)| v)?;
    match cells.len() {
        0 => fail!("Error parsing cells tree: empty root"),
        1 => Ok(cells.remove(0)),
        _ => fail!("Error parsing cells tree: too many roots")
    }
}

pub fn serialize_tree_of_cells<T: Write>(cell: &Cell, dst: &mut T) -> Result<()> {
    BagOfCells::with_root(cell).write_to(dst, false)
}

pub fn serialize_toc(cell: &Cell) -> Result<Vec<u8>> {
    let mut dst = vec![];
    BagOfCells::with_root(cell).write_to(&mut dst, false).map(|_| dst)
}

// Absent cells is deserialized into cell with hash. Caller have to know about the cells and process it by itself.
// Returns vector with root cells
pub fn deserialize_cells_tree<T>(src: &mut T) -> Result<Vec<Cell>> where T: Read {
    deserialize_cells_tree_ex(src).map(|(v, _, _, _)| v)
}

pub fn deserialize_cells_tree_ex<T>(src: &mut T) -> Result<(Vec<Cell>, BocSerialiseMode, usize, usize)>
    where T: Read {
        
    let mut src = IoCrcFilter::new(src);
    let magic = src.read_be_u32()?;
    let first_byte = src.read_byte()?;
    
    let index_included;
    let mut has_crc = false;
    let mut has_cache_bits = false; // TODO What is it?
    let ref_size;
    let mode;
    let mut _flags = 0;

    match magic {
        BOC_INDEXED_TAG => {
            ref_size = first_byte as usize;
            index_included = true;
            mode = BocSerialiseMode::Indexed;
        },
        BOC_INDEXED_CRC32_TAG => {
            ref_size = first_byte as usize;
            index_included = true;
            has_crc = true;
            mode = BocSerialiseMode::IndexedCrc;
        },
        BOC_GENERIC_TAG => {
            index_included = first_byte & 0b1000_0000 != 0;
            has_crc = first_byte & 0b0100_0000 != 0;
            has_cache_bits = first_byte & 0b0010_0000 != 0;
            _flags = ((first_byte & 0b0001_1000) >> 3) as u8;
            ref_size = (first_byte & 0b0000_0111) as usize;
            mode = BocSerialiseMode::Generic {
                index: index_included,
                crc: has_crc,
                cache_bits: has_cache_bits,
                flags: _flags,
            };
        },
        _ => fail!("unknown BOC_TAG: {}", magic)
    };

    if ref_size == 0 || ref_size > 4 {
        fail!("ref size has to be more than 0 and less or equal 4, actual value: {}", ref_size)
    }

    let offset_size = src.read_byte()? as usize;
    if offset_size == 0 || offset_size > 8 {
        fail!("offset size has to be  less or equal 8, actual value: {}", offset_size)
    }

    let cells_count = src.read_be_uint(ref_size)?; // cells:(##(size * 8))
    let roots_count = src.read_be_uint(ref_size)?; // roots:(##(size * 8))
    let _absent_count = src.read_be_uint(ref_size)?; // absent:(##(size * 8)) { roots + absent <= cells }

    if (magic == BOC_INDEXED_TAG || magic == BOC_INDEXED_CRC32_TAG) && roots_count > 1 {
        fail!("roots count has to be less or equal 1 for TAG: {}, value: {}", magic, offset_size)
    }
    if roots_count > cells_count {
        fail!("roots count has to be less or equal than cells count, roots: {}, cells: {}", roots_count, cells_count)
    }

    let _tot_cells_size = src.read_be_uint(offset_size); // tot_cells_size:(##(off_bytes * 8))

    // Root list

    let roots_indexes = if magic == BOC_GENERIC_TAG {
        // root_list:(roots * ##(size * 8)) 
        let mut roots_indexes = Vec::with_capacity(roots_count);
        for _ in 0..roots_count {
            roots_indexes.push(src.read_be_uint(ref_size)?); // cells:(##(size * 8))
        }
        roots_indexes
    } else {
        Vec::with_capacity(0)
    };


    // Index processing - extract cell's sizes to check and correct future deserialization 
    let mut cells_sizes = vec![0_usize; cells_count];
    let mut prev_offset = 0;
    if index_included {
        let mut raw_index = vec![0; cells_count * offset_size];
        src.read_exact(&mut raw_index)?;

        for i in 0_usize..cells_count {
            let mut offset = std::io::Cursor::new(&raw_index[i * offset_size..i * offset_size + offset_size])
                .read_be_uint(offset_size)?;

            if has_cache_bits {
                offset >>= 1;
            } 
            if prev_offset > offset {
                fail!("cell[{}]'s offset is wrong", i)
            }
            cells_sizes[i as usize] = (offset - prev_offset) as usize;
            prev_offset = offset;
        }
    }
    
    let mut raw_cells = HashMap::new();

    // Deserialize cells
    for cell_index in 0..cells_count {
        raw_cells.insert(
            cell_index,
            deserialize_cell(&mut src, ref_size, cell_index, cells_count, 
                if index_included { Some(cells_sizes[cell_index as usize]) } else { None })?
            );
    }

    // Resolving references & constructing cells from leaves to roots
    let mut done_cells = HashMap::<u32, Cell>::new();
    for cell_index in (0..cells_count).rev() {
        let raw_cell = raw_cells.remove(&cell_index).unwrap();
        let mut refs = vec!();
        for ref_cell_index in raw_cell.refs {
            if let Some(child) = done_cells.get(&ref_cell_index) {
                refs.push(child.clone())
            } else {
                fail!("unresolved reference")
            }
        }
        let cell = DataCell::with_params(refs, raw_cell.data, raw_cell.cell_type, raw_cell.level, 
            raw_cell.hashes, raw_cell.depths)?;

        done_cells.insert(cell_index as u32, Cell::with_cell_impl(cell));
    }

    let mut roots = Vec::with_capacity(roots_count);
    if magic == BOC_GENERIC_TAG {
        for index in roots_indexes {
            roots.push(done_cells.get(&(index as u32)).unwrap().clone());
        }
    } else {
        roots.push(done_cells.get(&0).unwrap().clone());
    }

    if has_crc {
        let crc = src.sum32();
        let read_crc = src.read_le_u32()?;
        if read_crc != crc {
            fail!("crc not the same, values: {}, {}", read_crc, crc)
        }
    }

    Ok((roots, mode, ref_size, offset_size))
}

/*
Deserialization separately data and referensed cells indexes.
Returns cell data, their refs (as indexes), and total read data size.
*/
fn deserialize_cell<T>(
    src: &mut T,
    ref_size: usize,
    cell_index: usize,
    cells_count: usize, 
    cell_size_opt: Option<usize>
) -> Result<RawCell> where T: Read {

    let d1 = src.read_byte()? as usize;
    let level = (d1 >> 5) as u8; // level // TODO not foget about level mask
    let hashes = (d1 & 16) == 16; // with hashes
    let exotic = (d1 & 8) == 8; // exotic
    let refs = d1 & 7;	// refs count
    let absent = refs == 7 && hashes;

    if absent {
        // TODO ABSENT CELLS are NOT serialized right way. 
        // Need to rewrite as soon as right way will be known.
        //
        // For absent cells (i.e., external references), only d1 is present, always equal to 23 + 32l.
        let data_size = SHA256_SIZE * ((LevelMask::with_mask(level).level() + 1) as usize);
        let mut cell_data = [0; 128];
        src.read_exact(&mut cell_data[..data_size])?;
        cell_data[data_size] = 0x80;

        return Ok(RawCell { 
            data: SmallVec::from_slice(&cell_data[0..data_size + 1]),
            refs: SmallVec::new(),
            level,
            cell_type: CellType::Ordinary,
            hashes: None,
            depths: None, 
        });
    }
    
    if refs > 4 {
        fail!("refs count has to be less or equal 4, actual value: {}", refs)
    }

    let d2 = src.read_byte()?;
    let data_size = ((d2 >> 1) + if d2 & 1 != 0 { 1 } else { 0 }) as usize;	
    let no_completion_tag = d2 & 1 == 0;		
    let full_cell_size = ref_size * refs + 2 + data_size +
                            if hashes { (1 + level as usize) * (SHA256_SIZE + DEPTH_SIZE) } else { 0 };
    
    if let Some(cell_size) = cell_size_opt {
        if full_cell_size != cell_size {
            fail!("cell sizes have to be same, expected: {}, real: {}", full_cell_size, cell_size)
        }
    }
    
    let (hashes_opt, depths_opt) = if hashes {
        let mut hashes = [UInt256::default(), UInt256::default(), UInt256::default(), UInt256::default()];
        let mut depths = [0; 4];
        let mut u256 = [0; SHA256_SIZE];
        let level = LevelMask::with_mask(level).level() as usize;
        for hash in hashes.iter_mut().take(level + 1) {
            src.read_exact(&mut u256)?;
            *hash = UInt256::from(u256);
        }
        for depth in depths.iter_mut().take(level + 1) {
            *depth = src.read_be_uint(DEPTH_SIZE)? as u16;
        }
        (Some(hashes), Some(depths))
    } else {
        (None, None)
    };

    let cell_size = data_size + if no_completion_tag { 1 } else { 0 };
    let mut cell_data = [0; 128];
    src.read_exact(&mut cell_data[..data_size])?;

    // If complition tag was not serialized, we must add it (it is need for SliceData)
    if no_completion_tag {
        cell_data[data_size] = 0x80; 
    }
    
    let cell_type = if !exotic { CellType::Ordinary } else { CellType::from(cell_data[0]) };

    //println!("{} l={} h={} s={} r={}", cell_type, level, hashes, exotic, refs);

    let mut references = SmallVec::with_capacity(refs);
    for _ in 0..refs {
        let i = src.read_be_uint(ref_size)?;
        if i > cells_count || i <= cell_index {
            fail!("reference out of range, {} < (value: {}) <= {}", cells_count, i, cell_index)
        } else {
            references.push(i as u32);
        }
    }

    Ok(RawCell { 
        data: SmallVec::from_slice(&cell_data[0..cell_size]),
        refs: references,
        level,
        cell_type,
        hashes: hashes_opt,
        depths: depths_opt, 
    })
}

fn number_of_bytes_to_fit(l: usize) -> usize {
    let mut n = 0;
    let mut l1 = l;
    
    while l1 != 0 {
        l1 >>= 8;
        n += 1;
    }

    n
}

/// Filters given Write or Read object's write or read operations and calculates data's CRC
struct IoCrcFilter<'a, T> {
    io_object: &'a mut T,
    hasher: crc32::Digest
}

impl<'a, T> IoCrcFilter<'a, T> {
    pub fn new(io_object: &'a mut T) -> Self {
        IoCrcFilter{ 
            io_object,
            hasher: crc32::Digest::new(crc32::CASTAGNOLI) 
        }
    }

    pub fn sum32(&self) -> u32 {
        self.hasher.sum32()
    }
}

impl<'a, T> Write for IoCrcFilter<'a, T> where T: Write {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        self.hasher.write(buf);
        self.io_object.write(buf)
    }

    fn flush(&mut self) -> std::io::Result<()> {
        self.io_object.flush()
    }
}

impl<'a, T> Read for IoCrcFilter<'a, T> where T: Read {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        let res = self.io_object.read(buf);
        self.hasher.write(buf);
        res
    }
}

