#[macro_use]
extern crate index_fixed;

#[test]
fn const_to() {
    let a = [1u8, 2, 3, 6];
    {
        let b: &[u8; 1] = index_fixed!(&a; ..1);
        assert_eq!(b, &[1]);
    }

    {
        let b: &[u8; 2] = index_fixed!(&a; ..2);
        assert_eq!(b, &[1, 2]);
    }
}

#[test]
fn mut_to() {
    let mut a = [1u8, 2, 3, 6];
    {
        let b: &mut [u8; 2] = index_fixed!(&mut a; ..2);
        assert_eq!(b, &[1, 2]);

        b[1] = 5;
    }

    assert_eq!(a[1], 5);
}

#[test]
fn const_range() {
    let a = [1u8, 2, 3, 6];
    {
        let b: &[u8; 2] = index_fixed!(&a; 1 * 2, .. 6 - 2);
        assert_eq!(b, &[3, 6]);
    }
}

#[test]
fn mut_range() {
    let mut a = [1u8, 2, 3, 6];
    {
        let b: &mut [u8; 2] = index_fixed!(&mut a; 4/2, .. 2 + 2);
        assert_eq!(b, &[3, 6]);

        b[0] = 5;
    }
    assert_eq!(a[2], 5);
}

#[test]
fn type_infer() {
    let a = [1u8, 7, 19];
    let b = index_fixed!(&a; 1,..2);
    assert_eq!(&a[1..2], &b[..]);
}

#[test]
#[should_panic]
fn zero_len_to_one() {
    let a: [u8; 0] = [];
    let _ = index_fixed!(&a; ..1);
}

#[test]
fn zero_to_zero() {
    let a: [u8; 0] = [];
    let _ = index_fixed!(&a; ..0);
}

#[test]
#[should_panic]
fn out_of_range() {
    let a = [1u8, 5];
    let _ = index_fixed!(&a; ..3);
}

#[test]
fn const_usage() {
    const X: usize = 2;
    let a = [1u8, 2, 4, 5];
    let _ = index_fixed!(&a; X, .. X * 2);
}
