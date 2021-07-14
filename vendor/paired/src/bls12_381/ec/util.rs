use fff::Field;

#[inline(always)]
pub(super) fn osswu_helper<F: Field>(u: &F, xi: &F, ellp_a: &F, ellp_b: &F) -> [F; 7] {
    let usq = {
        let mut tmp = *u;
        tmp.square();
        tmp
    };

    let (nd_common, xi_usq, xi2_u4) = {
        let mut tmp = usq;
        tmp.mul_assign(xi); // xi * u^2
        let tmp2 = tmp;
        tmp.square(); // xi^2 * u^4
        let tmp3 = tmp;
        tmp.add_assign(&tmp2); // xi^2 * u^4 + xi * u^2
        (tmp, tmp2, tmp3)
    };

    let x0_num = {
        let mut tmp = nd_common;
        tmp.add_assign(&F::one()); // 1 + nd_common
        tmp.mul_assign(ellp_b); // B * (1 + nd_common)
        tmp
    };

    let x0_den = {
        let mut tmp = *ellp_a;
        if nd_common.is_zero() {
            tmp.mul_assign(xi);
        } else {
            tmp.mul_assign(&nd_common);
            tmp.negate();
        }
        tmp
    };

    // compute g(X0(u))
    let gx0_den = {
        let mut tmp = x0_den;
        tmp.square();
        tmp.mul_assign(&x0_den);
        tmp // x0_den ^ 3
    };

    let gx0_num = {
        let mut tmp1 = gx0_den;
        tmp1.mul_assign(ellp_b); // B * x0_den^3
        let mut tmp2 = x0_den;
        tmp2.square(); // x0_den^2
        tmp2.mul_assign(&x0_num); // x0_num * x0_den^2
        tmp2.mul_assign(ellp_a); // A * x0_num * x0_den^2
        tmp1.add_assign(&tmp2); // ^^^ + B * x0_den^3
        tmp2 = x0_num;
        tmp2.square(); // x0_num^2
        tmp2.mul_assign(&x0_num); // x0_num^3
        tmp1.add_assign(&tmp2); // x0_num^3 + A * x0_num * x0_den^2 + B * x0_den^3
        tmp1
    };

    [usq, xi_usq, xi2_u4, x0_num, x0_den, gx0_num, gx0_den]
}

#[cfg(test)]
/// Check that the point (X : Y : Z)==(X/Z^2, Y/Z^3) is on E: y^2 = x^3 + ELLP_A * x + ELLP_B.
pub fn check_g_prime<F: Field>(x: &F, y: &F, z: &F, a: &F, b: &F) {
    let lhs = {
        // y^2
        let mut tmp = *y;
        tmp.square();
        tmp
    };

    let rhs = {
        // x^3 + A x z^4 + B z^6
        let mut zsq = *z;
        zsq.square();

        let mut z4 = zsq;
        z4.square();

        let mut tmp1 = *x;
        tmp1.square();
        tmp1.mul_assign(x); // x^3

        let mut tmp2 = *x;
        tmp2.mul_assign(&z4);
        tmp2.mul_assign(a);
        tmp1.add_assign(&tmp2); // + A x z^4

        tmp2 = z4;
        tmp2.mul_assign(&zsq);
        tmp2.mul_assign(b);
        tmp1.add_assign(&tmp2); // + B z^6

        tmp1
    };

    assert_eq!(lhs, rhs);
}
