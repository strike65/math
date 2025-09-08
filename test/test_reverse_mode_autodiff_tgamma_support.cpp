#define BOOST_MATH_REVERSE_MODE_ET_ON
#include "test_autodiff_reverse.hpp"
#include <boost/math/special_functions.hpp>
#include <boost/math/tools/workaround.hpp>
#include <cmath>
BOOST_AUTO_TEST_SUITE(test_stl_supported_functions)

using namespace rdiff;
BOOST_AUTO_TEST_CASE_TEMPLATE(test_tgamma, T, bin_float_types)
{
    RandomSample<T> rng{-10, 10};
    T               x = rng.next();

    rvar<T, 1> x_ad = x;
    auto       y                   = boost::math::tgamma(x_ad);
    auto       y_expect            = boost::math::tgamma(x);
    auto       expected_derivative = boost::math::tgamma(x) * boost::math::digamma(x);
    y.backward();

    BOOST_REQUIRE_CLOSE_FRACTION(y.item(), y_expect, boost_close_tol<T>());
    BOOST_REQUIRE_CLOSE_FRACTION(x_ad.adjoint(), expected_derivative, 1000 * boost_close_tol<T>());
}
BOOST_AUTO_TEST_CASE_EXPECTED_FAILURES(test_tgamma_int, 1)
BOOST_AUTO_TEST_CASE_TEMPLATE(test_tgamma_int, T, bin_float_types)
{
    T          x                   = 1.0;
    rvar<T, 1> x_ad                = x;
    auto       y                   = boost::math::tgamma(x_ad);
    auto       y_expect            = boost::math::tgamma(x);
    auto       expected_derivative = boost::math::tgamma(x) * boost::math::digamma(x);
    y.backward();

    BOOST_REQUIRE_CLOSE_FRACTION(y.item(), y_expect, boost_close_tol<T>());
    BOOST_REQUIRE_CLOSE_FRACTION(x_ad.adjoint(), expected_derivative, 1000 * boost_close_tol<T>());
}
BOOST_AUTO_TEST_SUITE_END()
