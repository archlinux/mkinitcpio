#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

load '/usr/lib/bats-assert/load'
load '/usr/lib/bats-support/load'
load "../helpers/common"

setup() {
    source "functions"
}

@test "detect_compression bzip2" {
    local tmp_img
    tmp_img="$(__gen_test_image 'bzip2')"
    run detect_compression "$tmp_img"
    assert_output "bzip2"
}

@test "detect_compression cat" {
    local tmp_img
    tmp_img="$(__gen_test_image 'cat')"
    run detect_compression "$tmp_img"
    assert_output ""
}

@test "detect_compression gzip" {
    local tmp_img
    tmp_img="$(__gen_test_image 'gzip')"
    run detect_compression "$tmp_img"
    assert_output "gzip"
}

@test "detect_compression lz4" {
    local tmp_img
    tmp_img="$(__gen_test_image 'lz4')"
    run detect_compression "$tmp_img"
    assert_output --partial "==> ERROR: Newer lz4 stream format detected! This may not boot!"
    assert_output --partial "lz4"
}

@test "detect_compression lz4 (legacy)" {
    local tmp_img
    tmp_img="$(__gen_test_image 'lz4' '-l')"
    run detect_compression "$tmp_img"
    assert_output "lz4 -l"
}

@test "detect_compression lzma" {
    local tmp_img
    tmp_img="$(__gen_test_image 'lzma')"
    run detect_compression "$tmp_img"
    assert_output "lzma"
}

@test "detect_compression lzop" {
    local tmp_img
    __check_binary "lzop"
    tmp_img="$(__gen_test_image 'lzop')"
    run detect_compression "$tmp_img"
    assert_output "lzop"
}

@test "detect_compression xz" {
    local tmp_img
    tmp_img="$(__gen_test_image 'xz' '--check=crc32')"
    run detect_compression "$tmp_img"
    assert_output "xz"
}

@test "detect_compression zstd" {
    local tmp_img
    tmp_img="$(__gen_test_image 'zstd' '-T0')"
    run detect_compression "$tmp_img"
    assert_output "zstd"
}

@test "kver_x86" {
    local kernel_ver tmp_knl
    kernel_ver="6.0.9-arch1-1 #1 SMP PREEMPT_DYNAMIC Wed, 16 Nov 2022 17:01:17 +0000 x86_64 GNU/Linux"
    tmp_knl=$(__gen_test_kernel "$kernel_ver")
    run kver_x86 "$tmp_knl"
    assert_output "6.0.9-arch1-1"
}

@test "add_binary script" {
    local tmp_bin BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}/" interpreter="/usr/local/${BATS_TEST_NAME}.${RANDOM}" _optquiet=1

    tmp_bin="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_bin.XXXXXX)"
    printf '#!%s\n\n:\n' "$interpreter" >"$tmp_bin"

    install -d -- "$BUILDROOT"
    # initialize_buildroot unconditionally creates a /tmp/mkinitcpio.XXXXXX work directory
    rmdir -- "$(initialize_buildroot 'none' "$BUILDROOT")"
    run add_binary "$tmp_bin"
    assert_output "==> WARNING: Possibly missing '${interpreter}' for script: $tmp_bin"
}

@test "add_full_dir" {
    local i dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}/" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    install -d -- "$BUILDROOT" "${dir}/testdir1/testsubdir1" \
        "${dir}/testdir2/testsubdir1" "${dir}/testdir2/testsubdir2"
    printf 'test\n' >"${dir}/testdir1/1"
    printf 'test\n' >"${dir}/testdir1/testsubdir1/2"
    printf 'test\n' >"${dir}/testdir2/testsubdir2/3"
    ln -s -- 3 "${dir}/testdir2/testsubdir2/4"

    run add_full_dir "$dir"
    LC_ALL=C diff -r "${dir}/" "${BUILDROOT}/${dir}/"
}

@test "add_full_dir glob" {
    local i dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}/" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    install -d -- "$BUILDROOT" "${dir}/testdir1/testsubdir1"
    printf 'test\n' >"${dir}/testdir1/1.notest1"
    printf 'test\n' >"${dir}/testdir1/2.test2"
    printf 'test\n' >"${dir}/testdir1/testsubdir1/3.test3"
    ln -s -- 3.test3 "${dir}/testdir1/testsubdir1/4.notest4"

    run add_full_dir "$dir" '*.test*'
    [[ ! -e "${BUILDROOT}/${dir}/testdir1/1.notest1" ]] || return
    [[ -e "${BUILDROOT}/${dir}/testdir1/2.test2" ]] || return
    [[ -e "${BUILDROOT}/${dir}/testdir1/testsubdir1/3.test3" ]] || return
    [[ ! -e "${BUILDROOT}/${dir}/testdir1/testsubdir1/4.notest4" ]] || return
}
