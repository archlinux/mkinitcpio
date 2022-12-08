#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

load '/usr/lib/bats-assert/load'
load "../helpers/common"

setup() {
    source "functions"
}

@test "detect_compression bzip2" {
    local tmp_img="$(__gen_test_image 'bzip2')"
    run detect_compression "$tmp_img"
    assert_output "bzip2"
}

@test "detect_compression cat" {
    local tmp_img="$(__gen_test_image 'cat')"
    run detect_compression "$tmp_img"
    assert_output ""
}

@test "detect_compression gzip" {
    local tmp_img="$(__gen_test_image 'gzip')"
    run detect_compression "$tmp_img"
    assert_output "gzip"
}

@test "detect_compression lz4" {
    local tmp_img="$(__gen_test_image 'lz4')"
    run detect_compression "$tmp_img"
    assert_output --partial "==> ERROR: Newer lz4 stream format detected! This may not boot!"
    assert_output --partial "lz4"
}

@test "detect_compression lz4 (legacy)" {
    local tmp_img="$(__gen_test_image 'lz4' '-l')"
    run detect_compression "$tmp_img"
    assert_output "lz4 -l"
}

@test "detect_compression lzma" {
    local tmp_img="$(__gen_test_image 'lzma')"
    run detect_compression "$tmp_img"
    assert_output "lzma"
}

@test "detect_compression lzop" {
    __check_binary "lzop"
    local tmp_img="$(__gen_test_image 'lzop')"
    run detect_compression "$tmp_img"
    assert_output "lzop"
}

@test "detect_compression xz" {
    local tmp_img="$(__gen_test_image 'xz' '--check=crc32')"
    run detect_compression "$tmp_img"
    assert_output "xz"
}

@test "detect_compression zstd" {
    local tmp_img="$(__gen_test_image 'zstd' '-T0')"
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
    local tmp_bin BUILDROOT="${BATS_RUN_TMPDIR}/buildroot/" interpreter="/usr/local/${BATS_TEST_NAME}.${RANDOM}" _optquiet=1

    tmp_bin="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_bin.XXXXXX)"
    printf '#!%s\n\n:\n' "$interpreter" > "$tmp_bin"

    install -d -- "$BUILDROOT"
    # initialize_buildroot unconditionally creates a /tmp/mkinitcpio.XXXXXX work directory
    rmdir -- "$(initialize_buildroot 'none' "$BUILDROOT")"
    run add_binary "$tmp_bin"
    assert_output "==> WARNING: Possibly missing '${interpreter}' for script: $tmp_bin"
}
