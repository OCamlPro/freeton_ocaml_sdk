#[macro_use]
extern crate index_fixed;

#[test]
fn const_to() {
    let a = [1u8, 2, 3, 6];
    {
        let b: Option<&[u8; 1]> = index_fixed_get!(&a; ..1);
        assert_eq!(b, Some(&[1]));
    }

    {
        let b: Option<&[u8; 2]> = index_fixed_get!(&a; ..2);
        assert_eq!(b, Some(&[1, 2]));
    }
}

#[test]
fn mut_to() {
    let mut a = [1u8, 2, 3, 6];
    {
        let b: Option<&mut [u8; 2]> = index_fixed_get!(&mut a; ..2);
        assert_eq!(b, Some(&mut [1, 2]));

        let b = b.unwrap();
        b[1] = 5;
    }

    assert_eq!(a[1], 5);
}

#[test]
fn const_range() {
    let a = [1u8, 2, 3, 6];
    {
        let b: Option<&[u8; 2]> = index_fixed_get!(&a; 1 * 2, .. 6 - 2);
        assert_eq!(b, Some(&[3, 6]));
    }
}

#[test]
fn mut_range() {
    let mut a = [1u8, 2, 3, 6];
    {
        let b: Option<&mut [u8; 2]> = index_fixed_get!(&mut a; 4/2, .. 2 + 2);
        assert_eq!(b, Some(&mut [3, 6]));

        b.unwrap()[0] = 5;
    }
    assert_eq!(a[2], 5);
}

#[test]
fn type_infer() {
    let a = [1u8, 7, 19];
    let b = index_fixed_get!(&a; 1,..2);
    assert_eq!(&a[1..2], &b.unwrap()[..]);
}

#[test]
fn zero_len_to_one() {
    let a: [u8; 0] = [];
    assert_eq!(index_fixed_get!(&a; ..1), None);
}

#[test]
fn zero_to_zero() {
    let a: [u8; 0] = [];
    assert_eq!(index_fixed_get!(&a; ..0), Some(&[]))
}

#[test]
fn out_of_range() {
    let a = [1u8, 5];
    assert_eq!(index_fixed_get!(&a; ..3), None);
}

#[test]
fn const_usage() {
    const X: usize = 2;
    let a = [1u8, 2, 4, 5];
    assert_eq!(index_fixed_get!(&a; X, .. X * 2), Some(&[4, 5]));
}
