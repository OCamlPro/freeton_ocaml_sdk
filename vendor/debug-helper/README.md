Debug Helper
====================

[![CI](https://github.com/magiclen/debug-helper/actions/workflows/ci.yml/badge.svg)](https://github.com/magiclen/debug-helper/actions/workflows/ci.yml)

This crate provides declarative macros to help you implement the `Debug` trait manually.

Instead of this crate, in most cases, you can use the [`educe`](https://crates.io/crates/educe) crate to implement the `Debug` trait.

## Examples

For structs,

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub struct A {
    pub f1: u8,
    pub f2: i16,
    pub f3: f64,
}

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_struct!(A, f, self, .f1, (.f3, "{:.3}", self.f3));
    }
}

let a = A {
    f1: 1,
    f2: 2,
    f3: std::f64::consts::PI,
};

println!("{:#?}", a);

/*
    A {
        f1: 1,
        f3: 3.142,
    }
*/
```

For tuple structs,

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub struct A(pub u8, pub i16, pub f64);

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_tuple_struct!(A, f, self, .0, (.2, "{:.3}", self.2));
    }
}

let a = A(1, 2, std::f64::consts::PI);

println!("{:#?}", a);

/*
    A(
        1,
        3.142,
    )
*/
```

For enums (without the enum name),

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub enum A {
    V1,
    V2(u8, i16, f64),
    V3 {
        f1: u8,
        f2: i16,
        f3: f64,
    },
}

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_enum!(A::{V1, (V2(f1, _, f3): (.f1, (.f3, "{:.3}", f3))), {V3{f1, f2: _, f3}: (.f1, (.f3, "{:.3}", f3))}}, f, self);
    }
}

let a = A::V1;
let b = A::V2(1, 2, std::f64::consts::PI);
let c = A::V3{
    f1: 1,
    f2: 2,
    f3: std::f64::consts::PI,
};

println!("{:#?}", a);
println!("{:#?}", b);
println!("{:#?}", c);

/*
    V1
    V2(
        1,
        3.142,
    )
    V3 {
        f1: 1,
        f3: 3.142,
    }
*/
```

For enums (with the enum name),

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub enum A {
    V1,
    V2(u8, i16, f64),
    V3 {
        f1: u8,
        f2: i16,
        f3: f64,
    },
}

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_enum!({A::V1, (V2(f1, _, f3): (.f1, (.f3, "{:.3}", f3))), {V3{f1, f2: _, f3}: (.f1, (.f3, "{:.3}", f3))}}, f, self);
    }
}

let a = A::V1;
let b = A::V2(1, 2, std::f64::consts::PI);
let c = A::V3{
    f1: 1,
    f2: 2,
    f3: std::f64::consts::PI,
};

println!("{:#?}", a);
println!("{:#?}", b);
println!("{:#?}", c);

/*
    A::V1
    A::V2(
        1,
        3.142,
    )
    A::V3 {
        f1: 1,
        f3: 3.142,
    }
*/
```



Ghost fields,

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub struct A {
    pub f1: u8,
    pub f2: i16,
    pub f3: f64,
}

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_struct!(A, f, self, .f1, (.f3, "{:.3}", self.f3), (.sum, "{:.3}", self.f1 as f64 + self.f2 as f64 + self.f3));
    }
}

let a = A {
    f1: 1,
    f2: 2,
    f3: std::f64::consts::PI,
};

println!("{:#?}", a);

/*
    A {
        f1: 1,
        f3: 3.142,
        sum: 6.142,
    }
*/
```

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub struct A(pub u8, pub i16, pub f64);

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_tuple_struct!(A, f, self, .0, (.2, "{:.3}", self.2), (.3, "{:.3}", self.0 as f64 + self.1 as f64 + self.2));
    }
}

let a = A(1, 2, std::f64::consts::PI);

println!("{:#?}", a);

/*
    A(
        1,
        3.142,
        6.142,
    )
*/
```

Fake structs,

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub struct A(pub u8, pub i16, pub f64);

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_struct!(A, f, self, let .f1 = self.0, let .f2 = self.1, let .f3 = self.2);
    }
}

let a = A(1, 2, std::f64::consts::PI);

println!("{:#?}", a);

/*
    A {
        f1: 1,
        f2: 2,
        f3: 3.141592653589793,
    }
*/
```

Fake tuple structs,

```rust
#[macro_use] extern crate debug_helper;

use std::fmt::{self, Formatter, Debug};

pub struct A {
    pub f1: u8,
    pub f2: i16,
    pub f3: f64,
}

impl Debug for A {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), fmt::Error> {
        impl_debug_for_tuple_struct!(A, f, self, let .0 = self.f1, let .1 = self.f2, let .2 = self.f3);
    }
}

let a = A {
    f1: 1,
    f2: 2,
    f3: std::f64::consts::PI,
};

println!("{:#?}", a);

/*
    A(
        1,
        2,
        3.141592653589793,
    )
*/
```

## TODO

1. Fake enum struct variants and tuple variants.
1. Enum variants can be renamed.

## Crates.io

https://crates.io/crates/debug-helper

## Documentation

https://docs.rs/debug-helper

## License

[MIT](LICENSE)