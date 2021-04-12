/*!
# Debug Helper

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

*/

#![no_std]

extern crate alloc;

use alloc::fmt::{Debug, Formatter, Result as FormatResult};
use alloc::string::String;

#[doc(hidden)]
pub struct RawString(pub String);

impl Debug for RawString {
    fn fmt(&self, f: &mut Formatter<'_>) -> FormatResult {
        if f.alternate() {
            f.write_str(self.0.replace("\n", "\n    ").as_str())
        } else {
            f.write_str(self.0.as_str())
        }
    }
}

#[macro_export]
macro_rules! impl_debug_for_struct {
    // TODO unit struct
    ($struct_name:ident, $formatter:expr $(, $self:expr)? $(,)*) => {
        return $formatter.write_str(stringify!($struct_name));
    };
    // TODO struct
    ($struct_name:ident, $formatter:expr, $self:expr, $( $(.$field:ident)? $((.$field_2:ident, $($field_2_fmt:tt)+))? $(let .$field_3:ident = $field_3_value:expr)? ),* $(,)*) => {
        {
            let mut builder = $formatter.debug_struct(stringify!($struct_name));

            $(
                $(
                    builder.field(stringify!($field), &$self.$field);
                )?

                $(
                    builder.field(stringify!($field_2), &$crate::RawString(format!($($field_2_fmt)*)));
                )?

                $(
                    builder.field(stringify!($field_3), &$field_3_value);
                )?
            )*

            return builder.finish();
        }
    };
}

#[macro_export]
macro_rules! impl_debug_for_tuple_struct {
    // TODO unit tuple struct
    ($struct_name:ident, $formatter:expr $(, $self:expr)? $(,)*) => {
        return $formatter.write_str(stringify!($struct_name));
    };
    // TODO tuple struct
    ($struct_name:ident, $formatter:expr, $self:expr, $( $(.$field:tt)? $((.$field_2:tt, $($field_2_fmt:tt)+))? $(let .$field_3:tt = $field_3_value:expr)? ),* $(,)*) => {
        {
            let mut builder = $formatter.debug_tuple(stringify!($struct_name));

            $(
                $(
                    builder.field(&$self.$field);
                )?

                $(
                    builder.field(&$crate::RawString(format!($($field_2_fmt)*)));
                )?

                $(
                    builder.field(&$field_3_value);
                )?
            )*

            return builder.finish();
        }
    }
}

#[macro_export]
macro_rules! impl_debug_for_enum {
    // TODO enum
    ($enum_name:ident::{$( $($variant_unit:ident)? $(($variant_tuple:ident ($($tuple:tt)*) $(:($( $(.$t_field:tt)? $((.$t_field_2:tt, $($t_field_2_fmt:tt)+))? $(let .$t_field_3:tt = $t_field_3_value:expr)? ),* $(,)*))? ) )? $({$variant_struct:ident {$($struct:tt)*} $(:($( $(.$s_field:tt)? $((.$s_field_2:tt, $($s_field_2_fmt:tt)+))? $(let .$s_field_3:ident = $s_field_3_value:expr)? ),* $(,)*))? })? ),+ $(,)*}, $formatter:expr, $self:expr $(,)*) => {
        {
            match $self {
                $(
                    $(
                        Self::$variant_unit => {
                            return $formatter.write_str(stringify!($variant_unit));
                        }
                    )?
                    $(
                        Self::$variant_tuple ($($tuple)*)=> {
                            let mut builder = $formatter.debug_tuple(stringify!($variant_tuple));

                            $(
                                $(
                                    $(
                                        builder.field(&$t_field);
                                    )?

                                    $(
                                        builder.field(&$crate::RawString(format!($($t_field_2_fmt)*)));
                                    )?

                                    $(
                                        builder.field(&$t_field_3_value);
                                    )?
                                )*
                            )?

                            return builder.finish();
                        }
                    )?
                    $(
                        Self::$variant_struct {$($struct)*}=> {
                            let mut builder = $formatter.debug_struct(stringify!($variant_struct));

                            $(
                                $(
                                    $(
                                        builder.field(stringify!($s_field), &$s_field);
                                    )?

                                    $(
                                        builder.field(stringify!($s_field_2), &$crate::RawString(format!($($s_field_2_fmt)*)));
                                    )?

                                    $(
                                        builder.field(stringify!($s_field_3), &$s_field_3_value);
                                    )?
                                )*
                            )?

                            return builder.finish();
                        }
                    )?
                )+
            }
        }
    };
    // TODO enum full path
    ({$enum_name:ident::$( $($variant_unit:ident)? $(($variant_tuple:ident ($($tuple:tt)*) $(:($( $(.$t_field:tt)? $((.$t_field_2:tt, $($t_field_2_fmt:tt)+))? $(let .$t_field_3:tt = $t_field_3_value:expr)? ),* $(,)*))? ) )? $({$variant_struct:ident {$($struct:tt)*} $(:($( $(.$s_field:tt)? $((.$s_field_2:tt, $($s_field_2_fmt:tt)+))? $(let .$s_field_3:ident = $s_field_3_value:expr)? ),* $(,)*))? })? ),+ $(,)*}, $formatter:expr, $self:expr $(,)*) => {
        {
            match $self {
                $(
                    $(
                        Self::$variant_unit => {
                            $formatter.write_str(stringify!($enum_name))?;
                            $formatter.write_str("::")?;
                            return $formatter.write_str(stringify!($variant_unit));
                        }
                    )?
                    $(
                        Self::$variant_tuple ($($tuple)*)=> {
                            let mut builder = $formatter.debug_tuple(&format!("{}::{}", stringify!($enum_name), stringify!($variant_tuple)));

                            $(
                                $(
                                    $(
                                        builder.field(&$t_field);
                                    )?

                                    $(
                                        builder.field(&$crate::RawString(format!($($t_field_2_fmt)*)));
                                    )?

                                    $(
                                        builder.field(&$t_field_3_value);
                                    )?
                                )*
                            )?

                            return builder.finish();
                        }
                    )?
                    $(
                        Self::$variant_struct {$($struct)*}=> {
                            let mut builder = $formatter.debug_struct(&format!("{}::{}", stringify!($enum_name), stringify!($variant_struct)));

                            $(
                                $(
                                    $(
                                        builder.field(stringify!($s_field), &$s_field);
                                    )?

                                    $(
                                        builder.field(stringify!($s_field_2), &$crate::RawString(format!($($s_field_2_fmt)*)));
                                    )?

                                    $(
                                        builder.field(stringify!($s_field_3), &$s_field_3_value);
                                    )?
                                )*
                            )?

                            return builder.finish();
                        }
                    )?
                )+
            }
        }
    };
}
