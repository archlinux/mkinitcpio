#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

bats_load_library 'bats-assert'
bats_load_library 'bats-support'
load "../helpers/common"

setup() {
    source "init_functions"
}

__assert() {
    local expect_fail key expected_value actual_value

    if [[ "$1" == '--expect-fail' ]]; then
        expect_fail=y
        shift
    fi

    key=$1 expected_value=$2
    eval actual_value=\$"$1"

    # shellcheck disable=SC2254
    case $actual_value in
        $expected_value)
            if [[ -n "$expect_fail" ]]; then
                echo "EXPECTED FAIL: $key: expected='$expected_value', got='$actual_value'"
                return 1
            fi
            ;;
        *)
            if [[ -z "$expect_fail" ]]; then
                echo "FAIL: $key: expected='$expected_value', got='$actual_value'"
                return 1
            fi
            ;;
    esac

    return 0
}

__test_parse() {
    local flag cmdline expect_fail expect_parse_fail

    for flag; do
        case $flag in
            --expect-fail)
                expect_fail='--expect-fail'
                shift
                ;;
            --expect-parse-fail)
                # shellcheck disable=SC2034
                expect_parse_fail=y
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    cmdline=$1
    shift
    [[ -n "$V" ]] && echo "testing cmdline: $cmdline"

    echo "$cmdline" | {
        parse_cmdline

        result=0
        while (( $# )); do
            key=$1 expected_value=$2
            shift 2
            # Quoting expect_fail ruins the test, unsure why
            # shellcheck disable=SC2248
            __assert $expect_fail "$key" "$expected_value" || result=$e_assertion_failure
        done

        exit "$result"
    } 2>/dev/null

}

@test "parse_cmdline" {

    # Legacy stuff, idk man

    # shellcheck disable=SC2034
    failed=0
    # shellcheck disable=SC2034
    tests=0

    # shellcheck disable=SC2034
    e_ok=0
    # shellcheck disable=SC2034
    e_parser_failure=2
    # shellcheck disable=SC2034
    e_assertion_failure=130

    # bare words
    __test_parse 'foo' \
        'foo' 'y'
    __test_parse 'foo bar' \
        'foo' 'y' \
        'bar' 'y'

    # overwriting
    __test_parse 'foo=bar bar=baz foo bar="no pe"' \
        'bar' 'no pe' \
        'foo' 'y'

    # simple key=value assignment
    __test_parse 'foo=bar' \
        'foo' 'bar'
    __test_parse 'foo=bar bar=baz' \
        'foo' 'bar' \
        'bar' 'baz'
    __test_parse '_derpy=hooves' \
        '_derpy' 'hooves'
    __test_parse 'f5=abc f_5_=abc' \
        'f5' 'abc' \
        'f_5_' 'abc'
    __test_parse 'v="foo bar=baz"' \
        'v' 'foo bar=baz'

    # double quoting
    __test_parse 'foo="bar"' \
        'foo' 'bar'
    __test_parse 'foo="bar baz"' \
        'foo' 'bar baz'

    # single quoting
    __test_parse "foo='bar'" \
        'foo' 'bar'
    __test_parse "foo='bar baz'" \
        'foo' 'bar baz'

    # dangling quotes
    __test_parse 'foo="bar' \
        'foo' '"bar'
    __test_parse 'foo=bar"' \
        'foo' 'bar"'

    # nested quotes
    __test_parse "foo='\"bar baz\"' herp='\"de\"rp'" \
        'foo' '"bar baz"' \
        'herp' '"de"rp'

    # escaped quotes
    __test_parse 'foo=bar"baz' \
        'foo' 'bar"baz'

    # neighboring quoted regions
    __test_parse --expect-fail 'foo="bar""baz"' \
        'foo' 'barbaz'
    __test_parse --expect-fail "foo=\"bar\"'baz'" \
        'foo' "barbaz"
    __test_parse --expect-fail "foo='bar'\"baz\"" \
        'foo' "barbaz"

    # comments
    __test_parse 'foo=bar # ignored content' \
        'foo' 'bar' \
        'ignored' '' \
        'content' ''
    __test_parse 'foo=bar #ignored content' \
        'foo' 'bar' \
        'ignored' '' \
        'content' ''
    __test_parse 'foo="bar #baz" parse=this' \
        'foo' 'bar #baz' \
        'parse' 'this'

    # shell metachars
    __test_parse 'foo=*' \
        'foo' '\*'
    __test_parse 'Make*' \
        'Makefile' ''
    __test_parse '[Makefile]*' \
        'Makefile' '' \
        'init' '' \
        'functions' ''

    # invalid names
    __test_parse 'in-valid=name'
    __test_parse '6foo=bar'
    __test_parse '"gar bage"' \
        'gar' '' \
        'bage' ''

    # special handling
    __test_parse 'rw' \
        'ro' '' \
        'rw' '' \
        'rwopt' 'rw'
    __test_parse 'ro' \
        'ro' '' \
        'rw' '' \
        'rwopt' 'ro'
    __test_parse 'fstype=btrfs' \
        'rootfstype' 'btrfs'
    __test_parse 'fsck.mode=force' \
        'forcefsck' 'y' \
        'fastboot' ''
    __test_parse 'fsck.mode=skip' \
        'forcefsck' '' \
        'fastboot' 'y'
    __test_parse 'rd.debug' \
        'rd_debug' 'y'
    __test_parse 'rd.log' \
        'rd_logmask' '6'
    __test_parse 'rd.log=all' \
        'rd_logmask' '7'
    __test_parse 'rd.log=console' \
        'rd_logmask' '4'
    __test_parse 'rd.log=kmsg' \
        'rd_logmask' '2'
    __test_parse 'rd.log=file' \
        'rd_logmask' '1'

    # a mix of stuff
    __test_parse 'foo=bar bareword bar="ba az"' \
        'foo' 'bar' \
        'bareword' 'y' \
        'bar' 'ba az'

}

__test_getarg() {
    local flag="$1" cmdline expect_fail key expected actual_value
    local cmdline_cache="${BATS_TEST_TMPDIR}/cmdline"

    if [[ "$flag" = '--expect-fail' ]]; then
        expect_fail='y'
        shift
    fi

    cmdline="$1"
    key="$2"
    default="$3"
    expected="$4"

    [[ -n "$V" ]] && printf 'testing cmdline: %s\n' "$cmdline"

    : > "$cmdline_cache"
    parse_cmdline "parse_cmdline_item" "$cmdline_cache" <<< "$cmdline"

    run getarg "$key" "$default" "$cmdline_cache"

    if [[ -z "$expect_fail" ]]; then
        assert_output "$expected"
    else
        refute_output "$expected"
    fi
}

@test "getarg" {
    # bare words
    __test_getarg 'foo' \
        'foo' '' 'y'
    __test_getarg 'foo bar' \
        'bar' '' 'y'

    # overwriting
    __test_getarg 'foo=bar bar=baz foo bar="no pe"' \
        'bar' '' 'no pe'
    __test_getarg 'foo=bar bar=baz foo bar="no pe"' \
        'foo' '' 'y'

    # simple key=value assignment
    __test_getarg 'foo=bar' \
        'foo' '' 'bar'
    __test_getarg 'foo=bar bar=baz' \
        'bar' '' 'baz'
    __test_getarg '_derpy=hooves' \
        '_derpy' '' 'hooves'
    __test_getarg 'f5=abc f_5_=abc' \
        'f5' '' 'abc'
    __test_getarg 'f5=abc f_5_=abc' \
        'f_5_' '' 'abc'
    __test_getarg 'v="foo bar=baz"' \
        'v' '' 'foo bar=baz'

    # double quoting
    __test_getarg 'foo="bar"' \
        'foo' '' 'bar'
    __test_getarg 'foo="bar baz"' \
        'foo' '' 'bar baz'

    # single quoting
    __test_getarg "foo='bar'" \
        'foo' '' 'bar'
    __test_getarg "foo='bar baz'" \
        'foo' '' 'bar baz'

    # dangling quotes
    __test_getarg 'foo="bar' \
        'foo' '' '"bar'
    __test_getarg 'foo=bar"' \
        'foo' '' 'bar"'

    # nested quotes
    __test_getarg "foo='\"bar baz\"' herp='\"de\"rp'" \
        'foo' '' '"bar baz"'
    __test_getarg "foo='\"bar baz\"' herp='\"de\"rp'" \
        'herp' '' '"de"rp'

    # escaped quotes
    __test_getarg 'foo=bar"baz' \
        'foo' '' 'bar"baz'

    # neighboring quoted regions
    __test_getarg --expect-fail 'foo="bar""baz"' \
        'foo' '' 'barbaz'
    __test_getarg --expect-fail "foo=\"bar\"'baz'" \
        'foo' '' "barbaz"
    __test_getarg --expect-fail "foo='bar'\"baz\"" \
        'foo' '' "barbaz"

    # comments
    __test_getarg 'foo=bar # ignored content' \
        'foo' '' 'bar'
    __test_getarg 'foo=bar # ignored content' \
        'ignored' '' ''
    __test_getarg 'foo=bar # ignored content' \
        'content' '' ''
    __test_getarg 'foo=bar #ignored content' \
        'foo' '' 'bar'
    __test_getarg 'foo=bar #ignored content' \
        'ignored' '' ''
    __test_getarg 'foo=bar #ignored content' \
        'content' '' ''
    __test_getarg 'foo="bar #baz" parse=this' \
        'foo' '' 'bar #baz'
    __test_getarg 'foo="bar #baz" parse=this' \
        'parse' '' 'this'

    # shell metachars
    __test_getarg 'foo=*' \
        'foo' '' '*'
    __test_getarg 'Make*' \
        'Makefile' '' ''
    __test_getarg '[Makefile]*' \
        'Makefile' '' ''
    __test_getarg '[Makefile]*' \
        'init' '' ''
    __test_getarg '[Makefile]*' \
        'functions' '' ''

    # invalid shell variables
    __test_getarg 'in-valid=name' \
        'in-valid' '' 'name'
    __test_getarg '6foo=bar' \
        '6foo' '' 'bar'
    __test_getarg '"gar bage"' \
        'gar' '' ''
    __test_getarg '"gar bage"' \
        'bage' '' ''
    __test_getarg 'foo.bar=bage' \
        'foo.bar' '' 'bage'

    # a mix of stuff
    __test_getarg 'foo=bar bareword bar="ba az"' \
        'foo' '' 'bar'
    __test_getarg 'foo=bar bareword bar="ba az"' \
        'bareword' '' 'y'
    __test_getarg 'foo=bar bareword bar="ba az"' \
        'bar' '' 'ba az'

    # defaults
    __test_getarg 'foo=bar' \
        'foo' 'default' 'bar'
    __test_getarg 'foo' \
        'foo' 'default' 'y'
    __test_getarg 'foo' \
        'bar' 'default' 'default'

    # pass through escaped characters
    # https://gitlab.archlinux.org/archlinux/mkinitcpio/mkinitcpio/-/issues/257
    __test_getarg 'foo=bar\:baz:qux' \
        'foo' '' 'bar\:baz:qux'
}
