/*
 * Copyright 2018-2019 TON DEV SOLUTIONS LTD.
 *
 * Licensed under the SOFTWARE EVALUATION License (the "License"); you may not use
 * this file except in compliance with the License.  You may obtain a copy of the
 * License at:
 *
 * https://www.ton.dev/licenses
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific TON DEV software governing permissions and limitations
 * under the License.
 */

use num::BigInt;
use serde_json::{Map, Value};
use std::str::FromStr;
use ton_types::{deserialize_tree_of_cells, error, fail, Result, UInt256};
use ton_block::{
    Deserializable,
    Account,
    BlockCreateFees,
    BlockLimits,
    CatchainConfig,
    ConfigParamEnum, ConfigParam0, ConfigParam1, ConfigParam2,
    ConfigParam7, ConfigParam8, ConfigParam9,
    ConfigParam10, ConfigParam11, ConfigParam12, ConfigParam13, ConfigParam14,
    ConfigParam15, ConfigParam16, ConfigParam17, ConfigParam18,
    ConfigParam29, ConfigParam31, ConfigParam34,
    ConfigParam18Map, ConfigParams,
    ConfigProposalSetup,
    ConsensusConfig,
    CurrencyCollection,
    ExtraCurrencyCollection,
    FundamentalSmcAddresses,
    GasLimitsPrices,
    GlobalVersion,
    Grams,
    LibDescr,
    MandatoryParams,
    McStateExtra,
    MsgForwardPrices,
    ParamLimits,
    ShardAccount, ShardIdent, ShardStateUnsplit,
    SigPubKey,
    StoragePrices,
    ValidatorDescr, ValidatorSet,
    Workchains, WorkchainDescr, WorkchainFormat, WorkchainFormat0, WorkchainFormat1,
};

trait ParseJson {
    fn as_uint256(&self) -> Result<UInt256>;
    fn as_base64(&self) -> Result<Vec<u8>>;
    fn as_int(&self) -> Result<i32>;
    fn as_uint(&self) -> Result<u32>;
    fn as_long(&self) -> Result<i64>;
    fn as_ulong(&self) -> Result<u64>;
}

impl ParseJson for Value {
    fn as_uint256(&self) -> Result<UInt256> {
        UInt256::from_str(self.as_str().ok_or_else(|| error!("field is not str"))?)
    }
    fn as_base64(&self) -> Result<Vec<u8>> {
        Ok(base64::decode(self.as_str().ok_or_else(|| error!("field is not str"))?)?)
    }
    fn as_int(&self) -> Result<i32> {
        match self.as_i64() {
            Some(v) => Ok(v as i32),
            None => match self.as_str() {
                Some(s) => Ok(i32::from_str(s)?),
                None => Ok(i32::default())
            }
        }
    }
    fn as_uint(&self) -> Result<u32> {
        match self.as_u64() {
            Some(v) => Ok(v as u32),
            None => match self.as_str() {
                Some(s) => Ok(u32::from_str(s)?),
                None => Ok(u32::default())
            }
        }
    }
    fn as_long(&self) -> Result<i64> {
        match self.as_i64() {
            Some(v) => Ok(v),
            None => match self.as_str() {
                Some(s) => Ok(i64::from_str(s)?),
                None => Ok(i64::default())
            }
        }
    }
    fn as_ulong(&self) -> Result<u64> {
        match self.as_u64() {
            Some(v) => Ok(v),
            None => match self.as_str() {
                Some(s) => Ok(u64::from_str(s)?),
                None => Ok(u64::default())
            }
        }
    }
}

#[derive(Debug)]
struct PathMap<'m, 'a> {
    map: &'m Map<String, Value>,
    path: Vec<&'a str>
}

impl<'m, 'a> PathMap<'m, 'a> {
    fn new(map: &'m Map<String, Value>) -> Self {
        Self {
            map,
            path: vec!["root"]
        }
    }
    fn map(&self) -> &Map<String, Value> {
        self.map
    }
    fn cont(prev: &Self, name: &'a str, value: &'m Value) -> Result<Self> {
        let map = value
            .as_object()
            .ok_or_else(|| error!("{}/{} must be the vector of objects", prev.path.join("/"), name))?;
        let mut path = prev.path.clone();
        path.push(name);
        Ok(Self {
            map,
            path
        })
    }
    fn get_item(&self, name: &'a str) -> Result<&'m Value> {
        let item = self.map.get(name).ok_or_else(|| error!("{} must have the field `{}`", self.path.join("/"), name))?;
        Ok(item)
    }
    fn get_obj(&self, name: &'a str) -> Result<Self> {
        let map = self.get_item(name)?
            .as_object()
            .ok_or_else(|| error!("{}/{} must be the object", self.path.join("/"), name))?;
        let mut path = self.path.clone();
        path.push(name);
        Ok(Self {
            map,
            path
        })
    }
    fn get_vec(&self, name: &'a str) -> Result<&'m Vec<Value>> {
        self.get_item(name)?
            .as_array()
            .ok_or_else(|| error!("{}/{} must be the vector", self.path.join("/"), name))
    }
    fn get_str(&self, name: &'a str) -> Result<&'m str> {
        self.get_item(name)?
            .as_str()
            .ok_or_else(|| error!("{}/{} must be the string", self.path.join("/"), name))
    }
    fn get_uint256(&self, name: &'a str) -> Result<UInt256> {
        UInt256::from_str(self.get_str(name)?)
            .map_err(|err| error!("{}/{} must be the uint256 in hex format : {}", self.path.join("/"), name, err))
    }
    fn get_base64(&self, name: &'a str) -> Result<Vec<u8>> {
        base64::decode(self.get_str(name)?)
            .map_err(|err| error!("{}/{} must be the base64 : {}", self.path.join("/"), name, err))
    }
    fn get_num(&self, name: &'a str) -> Result<i64> {
        let item = self.get_item(name)?;
        match item.as_i64() {
            Some(v) => Ok(v),
            None => match item.as_str() {
                Some(s) => {
                    i64::from_str(s)
                    .map_err(|_| error!("{}/{} must be the integer or a string with the integer {}", self.path.join("/"), name, s))
                }
                None => fail!("{}/{} must be the integer or a string with the integer {}", self.path.join("/"), name, item)
            }
        }
    }
    fn get_bool(&self, name: &'a str) -> Result<bool> {
        self.get_item(name)?
            .as_bool()
            .ok_or_else(|| error!("{}/{} must be boolean", self.path.join("/"), name))
    }
}

fn set_config(map: &PathMap, config_params: &mut ConfigParams, config: ConfigParamEnum) -> Result<()> {
    config_params.set_config(config)
        .map_err(|err| error!("Can't set config for {} : {}", map.path.join("/"), err))
}

fn parse_param_limits(param: &PathMap) -> Result<ParamLimits> {
    ParamLimits::with_limits(
        param.get_num("underload")? as u32,
        param.get_num("soft_limit")? as u32,
        param.get_num("hard_limit")? as u32,
    )
}

fn parse_block_limits(param: &PathMap) -> Result<BlockLimits> {
    Ok(BlockLimits::with_limits(
        parse_param_limits(&param.get_obj("bytes")?)?,
        parse_param_limits(&param.get_obj("gas")?)?,
        parse_param_limits(&param.get_obj("lt_delta")?)?,
    ))
}

fn parse_msg_forward_prices(param: &PathMap) -> Result<MsgForwardPrices> {
    Ok(MsgForwardPrices {
        lump_price:       param.get_num("lump_price")? as u64,
        bit_price:        param.get_num("bit_price")? as u64,
        cell_price:       param.get_num("cell_price")? as u64,
        ihr_price_factor: param.get_num("ihr_price_factor")? as u32,
        first_frac:       param.get_num("first_frac")? as u16,
        next_frac:        param.get_num("next_frac")? as u16,
    })
}

pub fn parse_config(config: &Map<String, Value>) -> Result<ConfigParams> {
    let config = PathMap::new(config);
    let mut config_params = ConfigParams::default();
    let config_addr = config.get_uint256("p0")?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam0(ConfigParam0 {config_addr} ))?;
    let elector_addr = config.get_uint256("p1")?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam1(ConfigParam1 {elector_addr} ))?;
    let minter_addr = config.get_uint256("p2")?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam2(ConfigParam2 {minter_addr} ))?;

    let p7 = config.get_vec("p7")?;
    let mut to_mint = ExtraCurrencyCollection::default();
    p7.iter().try_for_each(|currency| {
        let currency = PathMap::cont(&config, "p7", currency)?;
        to_mint.set(
            &(currency.get_num("currency")? as u32),
            &BigInt::from_str(currency.get_str("value")?)?.into()
        )
    })?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam7(ConfigParam7 {to_mint} ))?;

    let p8 = config.get_obj("p8")?;
    let version = p8.get_num("version")? as u32;
    let capabilities = p8.get_num("capabilities")? as u64;
    let global_version = GlobalVersion {version, capabilities};
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam8(ConfigParam8 {global_version} ))?;

    let p9 = config.get_vec("p9")?;
    let mut mandatory_params = MandatoryParams::default();
    p9.iter().try_for_each(|n| mandatory_params.set(&n.as_uint()?, &()))?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam9(ConfigParam9 {mandatory_params} ))?;

    let p10 = config.get_vec("p10")?;
    let mut critical_params = MandatoryParams::default();
    p10.iter().try_for_each(|n| critical_params.set(&n.as_uint()?, &()))?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam10(ConfigParam10 {critical_params} ))?;

    let p11 = config.get_obj("p11")?;
    let mut normal_params = ConfigProposalSetup::default();
    let mut critical_params = ConfigProposalSetup::default();

    let params = p11.get_obj("normal_params")?;
    normal_params.min_tot_rounds = params.get_num("min_tot_rounds")? as u8;
    normal_params.max_tot_rounds = params.get_num("max_tot_rounds")? as u8;
    normal_params.min_wins       = params.get_num("min_wins"      )? as u8;
    normal_params.max_losses     = params.get_num("max_losses"    )? as u8;
    normal_params.min_store_sec  = params.get_num("min_store_sec" )? as u32;
    normal_params.max_store_sec  = params.get_num("max_store_sec" )? as u32;
    normal_params.bit_price      = params.get_num("bit_price"     )? as u32;
    normal_params.cell_price     = params.get_num("cell_price"    )? as u32;

    let params = p11.get_obj("critical_params")?;
    critical_params.min_tot_rounds = params.get_num("min_tot_rounds")? as u8;
    critical_params.max_tot_rounds = params.get_num("max_tot_rounds")? as u8;
    critical_params.min_wins       = params.get_num("min_wins"      )? as u8;
    critical_params.max_losses     = params.get_num("max_losses"    )? as u8;
    critical_params.min_store_sec  = params.get_num("min_store_sec" )? as u32;
    critical_params.max_store_sec  = params.get_num("max_store_sec" )? as u32;
    critical_params.bit_price      = params.get_num("bit_price"     )? as u32;
    critical_params.cell_price     = params.get_num("cell_price"    )? as u32;

    let p11 = ConfigParam11::new(&normal_params, &critical_params)?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam11(p11))?;

    let p12 = config.get_vec("p12")?;
    let mut workchains = Workchains::default();
    p12.iter().try_for_each(|wc_info| {
        let wc_info = PathMap::cont(&config, "p12", wc_info)?;
        let mut descr = WorkchainDescr::default();
        let workchain_id = wc_info.get_num("workchain_id")? as u32;
        descr.enabled_since = wc_info.get_num("enabled_since")? as u32;
        descr.set_min_split(wc_info.get_num("min_split")? as u8)?;
        descr.set_max_split(wc_info.get_num("max_split")? as u8)?;
        descr.flags = wc_info.get_num("flags")? as u16;
        descr.active = wc_info.get_bool("active")?;
        descr.accept_msgs = wc_info.get_bool("accept_msgs")?;
        descr.zerostate_root_hash = wc_info.get_uint256("zerostate_root_hash")?;
        descr.zerostate_file_hash = wc_info.get_uint256("zerostate_file_hash")?;
        // TODO: check here
        descr.format = match wc_info.get_bool("basic")? {
            true => {
                let vm_version = wc_info.get_num("vm_version")? as i32;
                let vm_mode    = wc_info.get_num("vm_mode"   )? as u64;
                WorkchainFormat::Basic(WorkchainFormat1::with_params(vm_version, vm_mode))
            }
            false => {
                let min_addr_len      = wc_info.get_num("min_addr_len")? as u16;
                let max_addr_len      = wc_info.get_num("max_addr_len")? as u16;
                let addr_len_step     = wc_info.get_num("addr_len_step")? as u16;
                let workchain_type_id = wc_info.get_num("workchain_type_id")? as u32;
                WorkchainFormat::Extended(WorkchainFormat0::with_params(min_addr_len, max_addr_len, addr_len_step, workchain_type_id)?)
            }
        };
        workchains.set(&workchain_id, &descr)
    })?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam12(ConfigParam12 {workchains}))?;

    if let Ok(p13) = config.get_obj("p13") {
        let cell = deserialize_tree_of_cells(&mut std::io::Cursor::new(p13.get_base64("boc")?))?;
        set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam13(ConfigParam13 {cell}))?;
    }

    let p14 = config.get_obj("p14")?;
    let mut block_create_fees = BlockCreateFees::default();
    block_create_fees.masterchain_block_fee = Grams::from(p14.get_num("masterchain_block_fee")? as u64);
    block_create_fees.basechain_block_fee   = Grams::from(p14.get_num("basechain_block_fee")? as u64);
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam14(ConfigParam14 {block_create_fees}))?;

    let p15 = config.get_obj("p15")?;
    let p15 = ConfigParam15 {
        validators_elected_for: p15.get_num("validators_elected_for")? as u32,
        elections_start_before: p15.get_num("elections_start_before")? as u32,
        elections_end_before:   p15.get_num("elections_end_before")? as u32,
        stake_held_for:         p15.get_num("stake_held_for")? as u32,
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam15(p15))?;

    let p16 = config.get_obj("p16")?;
    let p16 = ConfigParam16 {
        min_validators:      p16.get_num("min_validators")?.into(),
        max_validators:      p16.get_num("max_validators")?.into(),
        max_main_validators: p16.get_num("max_main_validators")?.into(),
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam16(p16))?;

    let p17 = config.get_obj("p17")?;
    let p17 = ConfigParam17 {
        min_stake:        p17.get_num("min_stake")?.into(),
        max_stake:        p17.get_num("max_stake")?.into(),
        min_total_stake:  p17.get_num("min_total_stake")?.into(),
        max_stake_factor: p17.get_num("max_stake_factor")? as u32,
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam17(p17))?;

    let p18 = config.get_vec("p18")?;
    let mut map = ConfigParam18Map::default();
    let mut index = 0u32;
    p18.iter().try_for_each::<_, Result<_>>(|p| {
        let p = PathMap::cont(&config, "p18", p)?;
        let p = StoragePrices {
            utime_since:      p.get_num("utime_since")? as u32,
            bit_price_ps:     p.get_num("bit_price_ps")? as u64,
            cell_price_ps:    p.get_num("cell_price_ps")? as u64,
            mc_bit_price_ps:  p.get_num("mc_bit_price_ps")? as u64,
            mc_cell_price_ps: p.get_num("mc_cell_price_ps")? as u64,
        };
        map.set(&index, &p)?;
        index += 1;
        Ok(())
    })?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam18(ConfigParam18 { map }))?;

    let p20 = config.get_obj("p20")?;
    let p20 = GasLimitsPrices {
        gas_price:         p20.get_num("gas_price")? as u64,
        gas_limit:         p20.get_num("gas_limit")? as u64,
        special_gas_limit: p20.get_num("special_gas_limit")? as u64,
        gas_credit:        p20.get_num("gas_credit")? as u64,
        block_gas_limit:   p20.get_num("block_gas_limit")? as u64,
        freeze_due_limit:  p20.get_num("freeze_due_limit")? as u64,
        delete_due_limit:  p20.get_num("delete_due_limit")? as u64,
        flat_gas_limit:    p20.get_num("flat_gas_limit")? as u64,
        flat_gas_price:    p20.get_num("flat_gas_price")? as u64,
        max_gas_threshold: 0,
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam20(p20))?;

    let p21 = config.get_obj("p21")?;
    let p21 = GasLimitsPrices {
        gas_price:         p21.get_num("gas_price")? as u64,
        gas_limit:         p21.get_num("gas_limit")? as u64,
        special_gas_limit: p21.get_num("special_gas_limit")? as u64,
        gas_credit:        p21.get_num("gas_credit")? as u64,
        block_gas_limit:   p21.get_num("block_gas_limit")? as u64,
        freeze_due_limit:  p21.get_num("freeze_due_limit")? as u64,
        delete_due_limit:  p21.get_num("delete_due_limit")? as u64,
        flat_gas_limit:    p21.get_num("flat_gas_limit")? as u64,
        flat_gas_price:    p21.get_num("flat_gas_price")? as u64,
        max_gas_threshold: 0,
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam21(p21))?;

    let p22 = parse_block_limits(&config.get_obj("p22")?)?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam22(p22))?;

    let p23 = parse_block_limits(&config.get_obj("p23")?)?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam23(p23))?;
    
    let p24 = parse_msg_forward_prices(&config.get_obj("p24")?)?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam24(p24))?;

    let p25 = parse_msg_forward_prices(&config.get_obj("p25")?)?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam25(p25))?;

    let p28 = config.get_obj("p28")?;
    let p28 = CatchainConfig {
        shuffle_mc_validators:     p28.get_bool("shuffle_mc_validators")?,
        isolate_mc_validators:     p28.get_bool("isolate_mc_validators").unwrap_or_default(),
        mc_catchain_lifetime:      p28.get_num("mc_catchain_lifetime")? as u32,
        shard_catchain_lifetime:   p28.get_num("shard_catchain_lifetime")? as u32,
        shard_validators_lifetime: p28.get_num("shard_validators_lifetime")? as u32,
        shard_validators_num:      p28.get_num("shard_validators_num")? as u32,
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam28(p28))?;

    let p29 = config.get_obj("p29")?;
    let consensus_config = ConsensusConfig {
        new_catchain_ids:        p29.get_bool("new_catchain_ids")?,
        round_candidates:        p29.get_num("round_candidates")? as u32,
        next_candidate_delay_ms: p29.get_num("next_candidate_delay_ms")? as u32,
        consensus_timeout_ms:    p29.get_num("consensus_timeout_ms")? as u32,
        fast_attempts:           p29.get_num("fast_attempts")? as u32,
        attempt_duration:        p29.get_num("attempt_duration")? as u32,
        catchain_max_deps:       p29.get_num("catchain_max_deps")? as u32,
        max_block_bytes:         p29.get_num("max_block_bytes")? as u32,
        max_collated_bytes:      p29.get_num("max_collated_bytes")? as u32,
    };
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam29(ConfigParam29 {consensus_config}))?;

    let p31 = config.get_vec("p31")?;
    let mut fundamental_smc_addr = FundamentalSmcAddresses::default();
    p31.iter().try_for_each(|n| fundamental_smc_addr.set(&n.as_uint256()?, &()))?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam31(ConfigParam31 {fundamental_smc_addr} ))?;

    let p34 = config.get_obj("p34")?;
    let mut list = vec![];
    p34.get_vec("list")?.iter().try_for_each::<_, Result<()>>(|p| {
        let p = PathMap::cont(&config, "p34", p)?;
        list.push(ValidatorDescr::with_params(
            SigPubKey::from_str(p.get_str("public_key")?)?,
            p.get_num("weight")? as u64,
            None
        ));
        Ok(())
    })?;

    let cur_validators = ValidatorSet::new(
        p34.get_num("utime_since")? as u32,
        p34.get_num("utime_until")? as u32,
        p34.get_num("main")? as u16,
        list
    )?;
    set_config(&config, &mut config_params, ConfigParamEnum::ConfigParam34(ConfigParam34 {cur_validators}))?;
    Ok(config_params)
}

pub fn parse_state(map: &Map<String, Value>) -> Result<ShardStateUnsplit> {
    let map_path = PathMap::new(&map);

    let mut state = ShardStateUnsplit::with_ident(ShardIdent::masterchain());
    state.set_min_ref_mc_seqno(std::u32::MAX);
    state.set_global_id(map_path.get_num("global_id")? as i32);
    state.set_gen_time(map_path.get_num("gen_utime")? as u32);
    let balance = map_path.get_num("total_balance")? as u64;
    state.set_total_balance(CurrencyCollection::with_grams(balance));

    let master = map_path.get_obj("master")?;
    let mut extra = McStateExtra::default();
    let config = master.get_obj("config")?;
    extra.config = parse_config(config.map())?;
    extra.config.config_addr = master.get_uint256("config_addr")?;

    extra.validator_info.validator_list_hash_short = master.get_num("validator_list_hash_short")? as u32;
    extra.validator_info.catchain_seqno = master.get_num("catchain_seqno")? as u32;
    extra.validator_info.nx_cc_updated = master.get_bool("nx_cc_updated")?;

    extra.after_key_block = true;
    extra.global_balance = CurrencyCollection::with_grams(master.get_num("global_balance")? as u64);
    state.write_custom(Some(&extra))?;

    let accounts = map_path.get_vec("accounts")?;
    accounts.iter().try_for_each::<_, Result<()>>(|account| {
        let account = PathMap::cont(&map_path, "accounts", account)?;
        let id = account.get_str("id")?;
        let account_id = UInt256::from_str(id.trim_start_matches("-1:"))
            ?;
        Account::construct_from_bytes(&account.get_base64("boc")?)
            .and_then(|acc| ShardAccount::with_params(&acc, UInt256::default(), 0))
            .and_then(|acc| state.insert_account(&account_id, &acc))
            
    })?;

    let libraries = map_path.get_vec("libraries")?;
    libraries.iter().try_for_each::<_, Result<()>>(|library| {
        let library = PathMap::cont(&map_path, "libraries", library)?;
        let id = library.get_uint256("hash")?;
        let lib = library.get_base64("lib")?;
        let lib = deserialize_tree_of_cells(&mut std::io::Cursor::new(lib))?;
        let mut lib = LibDescr::new(lib);
        let publishers = library.get_vec("publishers")?;
        publishers.iter().try_for_each::<_, Result<()>>(|publisher| {
            lib.publishers_mut().set(&publisher.as_uint256()?, &())
        })?;
        state.libraries_mut().set(&id, &lib)
    })?;
    Ok(state)
}

