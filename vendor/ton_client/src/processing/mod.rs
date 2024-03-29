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
 *
 */

#[cfg(test)]
mod tests;

pub mod blocks_walking;
mod errors;
mod fetching;
mod internal;
pub mod parsing;
pub mod process_message;
pub mod send_message;
mod types;
pub mod wait_for_transaction;

pub use errors::{Error, ErrorCode};
pub use process_message::{process_message, ParamsOfProcessMessage};
pub use send_message::{send_message, ParamsOfSendMessage, ResultOfSendMessage};
pub use types::{DecodedOutput, ProcessingEvent, ProcessingResponseType, ResultOfProcessMessage};
pub use wait_for_transaction::{wait_for_transaction, ParamsOfWaitForTransaction};
