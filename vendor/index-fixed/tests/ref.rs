#[macro_use]
extern crate index_fixed;

#[test]
fn const_slice() {
    let a = [1u8, 2, 3, 6];
    let b = &a;
    assert_eq!(index_fixed!(&b; ..2), &[1u8, 2]);
}

#[test]
fn mut_slice() {
    let mut a = [1u8, 2, 3, 6];
    let b = &mut a;
    assert_eq!(index_fixed!(&mut b; ..2), &[1u8, 2]);
}

#[test]
fn const_get() {
    let a = [1u8, 2, 3, 6];
    let b = &a;
    assert_eq!(index_fixed_get!(&b; ..2), Some(&[1u8, 2]));
}

#[test]
fn mut_get() {
    let mut a = [1u8, 2, 3, 6];
    let b = &mut a;
    assert_eq!(index_fixed_get!(&mut b; ..2), Some(&mut [1u8, 2]));
}
