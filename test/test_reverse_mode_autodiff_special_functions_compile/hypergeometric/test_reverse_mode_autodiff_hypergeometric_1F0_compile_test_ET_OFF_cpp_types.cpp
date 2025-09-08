#define BOOST_MATH_REVERSE_MODE_ET_OFF
#include "../../test_autodiff_reverse.hpp"
#include <boost/math/special_functions.hpp>
#include <boost/math/tools/workaround.hpp>
#include <cmath>

BOOST_AUTO_TEST_SUITE(test_hypergeometric_1F0_compiles)

using namespace rdiff;

BOOST_AUTO_TEST_CASE_TEMPLATE(test_hypergeometric_1F0, T, bin_float_types)
{
    RandomSample<T> rng{1, 10};
    T               x = rng.next();

    rvar<T, 1> x_ad = x;
    auto y = boost::math::hypergeometric_1F0(x_ad,arg);
    auto y_expect = boost::math::hypergeometric_1F0(x,arg);
    BOOST_CHECK_CLOSE(y.item(), y_expect, 1000*boost_close_tol<T>());
}
BOOST_AUTO_TEST_SUITE_END()
