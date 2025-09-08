#!/bin/bash

#           Copyright Maksym Zhelyeznyakov 2025-2026
# Distributed under the Boost Software License, Version 1.0.
#     (See accompanying file LICENSE_1_0.txt or copy at
#           https://www.boost.org/LICENSE_1_0.txt)]
TEST_FOLDER="./"
SPECFUN_LIST="${TEST_FOLDER}specfun_list.txt"
CC="g++"
CPPFLAGS="--std=c++14"
CWD=$(pwd)
BOOST_ROOT_DIR="$CWD/../../../../"
BOOST_MATH_DIR="$BOOST_ROOT_DIR/libs/math/"
BOOST_MATH_TEST_DIR="$BOOST_MATH_DIR/test/"
INCLUDE_FLAGS="-I$BOOST_MATH_DIR/include/ -I$BOOST_ROOT_DIR -I$BOOST_MATH_TEST_DIR"
LOG_FILE="$BOOST_ROOT_DIR/libs/math/doc/differentiation/compilation_table.txt"
echo "current working direcotry $CWD"
echo "boost root $BOOST_ROOT_DIR"
echo "math test dir $BOOST_MATH_TEST_DIR"
echo "include flags $INCLUDE_FLAGS"

generate_boost_test() {
    local func_sig="$1"
    local et_str="$2"
    local type_str="$3"
    local func_name=$(echo "$func_sig" | cut -d'(' -f1)

    cat <<EOF
#define BOOST_MATH_REVERSE_MODE_ET_${et_str}
#include "../../test_autodiff_reverse.hpp"
#include <boost/math/special_functions.hpp>
#include <boost/math/tools/workaround.hpp>
#include <cmath>

BOOST_AUTO_TEST_SUITE(test_${func_name}_compiles)

using namespace rdiff;

BOOST_AUTO_TEST_CASE_TEMPLATE(test_${func_name}, T, ${type_str})
{
    RandomSample<T> rng{1, 10};
    T               x = rng.next();

    rvar<T, 1> x_ad = x;
    auto y = boost::math::${func_sig/arg/x_ad};
    auto y_expect = boost::math::${func_sig/arg/x};
    BOOST_CHECK_CLOSE(y.item(), y_expect, 1000*boost_close_tol<T>());
}
BOOST_AUTO_TEST_SUITE_END()
EOF
}
test_and_get_result() {
    local func_name="$1"
    local et_str="$2"
    local float_type="$3"
    local function_group="$4"
    local func_sig="$5"

    local outfilename="${TEST_FOLDER}${function_group}/test_reverse_mode_autodiff_${func_name}_compile_test_ET_${et_str}_${float_type}.cpp"
    local temp_executable="/tmp/test_reverse_mode_autodiff_${func_name}_ET_${et_str}_${float_type}"
    generate_boost_test "$func_sig" "$et_str" "${floats_to_test[$float_type]}" > "$outfilename"
    $CC -o "$temp_executable" $CPPFLAGS $INCLUDE_FLAGS -lboost_unit_test_framework "$outfilename" &>/dev/null
    local compile_status=$?
    if [ $compile_status -eq 0 ]; then
        "$temp_executable" &>/dev/null
        local run_status=$?

        if [ $run_status -eq 0 ]; then
            echo "YES]\t[YES"
        else
            echo "YES]\t[NO"
        fi
    else
        echo "NO]\t[N/A"
    fi
}


echo -e "[table\n
[[Function]\t[compiles with ET ON]\t[runs with ET ON]\t[compiles with ET OFF]\t[runs with ET OFF]\t[works with multiprecision]\t[known issues]]\n" > "$LOG_FILE"

# Check if the list file exists
if [[ ! -f "$SPECFUN_LIST" ]]; then
    echo "Error: ${SPECFUN_LIST} not found!"
    exit 1
fi

# Define float types to test using an associative array
bin_floats="bin_float_types"
mp_type="bmp::cpp_bin_float_50"

declare -A floats_to_test
floats_to_test["cpp_types"]="${bin_floats}"
floats_to_test["mp_types"]="${mp_type}"

# Skip the header (first line) and read the list of special functions line by line.
# The `IFS=$'\t'` ensures that the fields are split by a tab character.
tail -n +2 "$SPECFUN_LIST" | while IFS=$'\t' read -r function_group specfun; do
    # Create the directory if it doesn't exist
    if [[ ! -d "${TEST_FOLDER}${function_group}" ]]; then
        mkdir -p "${TEST_FOLDER}${function_group}"
    fi

    func_name=$(echo "$specfun" | cut -d'(' -f1)
    
    # Run tests for standard C++ types
    cpp_et_on_result=$(test_and_get_result "$func_name" "ON" "cpp_types" "$function_group" "$specfun")
    cpp_et_off_result=$(test_and_get_result "$func_name" "OFF" "cpp_types" "$function_group" "$specfun")

    # Run tests for multiprecision types
    mp_et_on_result=$(test_and_get_result "$func_name" "ON" "mp_types" "$function_group" "$specfun")
    mp_et_off_result=$(test_and_get_result "$func_name" "OFF" "mp_types" "$function_group" "$specfun")

    # Determine the "works with multiprecision" column value
    mp_status="NO"
    if [[ "$mp_et_on_result" == *"PASS"* ]]; then
        mp_status="with ET ON"
        if [[ "$mp_et_off_result" == *"PASS"* ]]; then
            mp_status="with ET ON, with ET OFF"
        fi
    elif [[ "$mp_et_off_result" == *"PASS"* ]]; then
        mp_status="with ET OFF"
    fi

    # Append the completed line to the log file
    func_name=$(echo "$specfun" | cut -d'(' -f1)
    known_issues_status="N/A"
    if [[ "$func_name" == "[tgamma]" ]]; then
        known_issues_status="derivative incorrect at integer arguments"
    fi

    # Append the completed line to the log file
    echo -e "[[$func_name]\t[${cpp_et_on_result}]\t[${cpp_et_off_result}]\t[${mp_status}]\t[${known_issues_status}]]" >> "$LOG_FILE"

done
echo -e "]" >> "$LOG_FILE"
sed -i -e '/BEGIN SPECFUN TABLE/,/END SPECFUN TABLE/{
    /BEGIN SPECFUN TABLE/{
        p
        r ../../doc/differentiation/compilation_table.txt
    }
    /END SPECFUN TABLE/p
    d
}' ../../doc/differentiation/autodiff_reverse.qbk

