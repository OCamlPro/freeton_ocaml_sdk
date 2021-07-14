# paired [![Crates.io](https://img.shields.io/crates/v/paired.svg)](https://crates.io/crates/paired)

> This is a fork of the great [pairing](https://github.com/zkcrypto/pairing) library.

`pairing` is a crate for using pairing-friendly elliptic curves.

Currently, only the [BLS12-381](https://z.cash/blog/new-snark-curve.html)
construction is implemented.

## Roadmap

`pairing` is being refactored into a generic library for working with
pairing-friendly curves. After the refactor, `pairing` will provide basic traits
for pairing-friendly elliptic curve constructions, while specific curves will be
in separate crates.

## [Documentation](https://docs.rs/paired/)

Bring the `paired` crate into your project just as you normally would.

## Security Warnings

This library does not make any guarantees about constant-time operations, memory
access patterns, or resistance to side-channel attacks.

## License

Licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or
   http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.
