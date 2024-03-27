#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

bats_load_library 'bats-assert'
bats_load_library 'bats-support'
load "../helpers/common"

setup() {
    source "functions"
}

@test "detect_compression bzip2" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'bzip2')"
    run detect_compression "$tmp_img"
    assert_output "bzip2"
}

@test "detect_compression cat" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'cat')"
    run detect_compression "$tmp_img"
    assert_output ""
}

@test "detect_compression gzip" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'gzip')"
    run detect_compression "$tmp_img"
    assert_output "gzip"
}

@test "detect_compression lz4" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'lz4')"
    run detect_compression "$tmp_img"
    assert_output --partial "==> ERROR: Newer lz4 stream format detected! This may not boot!"
    assert_output --partial "lz4"
}

@test "detect_compression lz4 (legacy)" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'lz4' '-l')"
    run detect_compression "$tmp_img"
    assert_output "lz4 -l"
}

@test "detect_compression lzma" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'lzma')"
    run detect_compression "$tmp_img"
    assert_output "lzma"
}

@test "detect_compression lzop" {
    local tmp_img=''
    __check_binary "lzop"
    tmp_img="$(__gen_test_image 'lzop')"
    run detect_compression "$tmp_img"
    assert_output "lzop"
}

@test "detect_compression xz" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'xz' '--check=crc32')"
    run detect_compression "$tmp_img"
    assert_output "xz"
}

@test "detect_compression zstd" {
    local tmp_img=''
    tmp_img="$(__gen_test_image 'zstd' '-T0')"
    run detect_compression "$tmp_img"
    assert_output "zstd"
}

@test "detect_compression zimg" {
    local tmp_img=''

    tmp_img="$(__gen_test_image 'zimg')"
    run detect_compression "$tmp_img"
    assert_output "zimg"
}

@test "detect_compression with offset" {
    local tmp_img=''

    tmp_img="$(__gen_test_image 'zstd' '-T0')"
    dd if="$tmp_img" of="$tmp_img.offset" seek=1
    run detect_compression "$tmp_img.offset" 512
    assert_output 'zstd'
}

@test "kver_x86" {
    local kernel_ver='' tmp_knl=''
    kernel_ver="6.0.9-arch1-1 #1 SMP PREEMPT_DYNAMIC Wed, 16 Nov 2022 17:01:17 +0000 x86_64 GNU/Linux"
    tmp_knl=$(__gen_test_kernel "$kernel_ver")
    run kver_x86 "$tmp_knl"
    assert_output "6.0.9-arch1-1"
}

@test "kver_zimage gzip" {
    local kernel_ver='' tmp_knl='' tmp_img=''
    kernel_ver="Linux version 6.1.0-rc5-5 #1 SMP Sat, 17 Dec 2022 05:05:29 +0000 loongarch64 GNU/Linux"
    tmp_img="$(__gen_test_zboot_kernel "$kernel_ver" 'gzip')"
    run kver_zimage "$tmp_img"
    assert_output "6.1.0-rc5-5"
}

@test "kver_zimage lz4" {
    local kernel_ver='' tmp_knl='' tmp_img=''
    kernel_ver="Linux version 6.1.0-rc5-5 #1 SMP Sat, 17 Dec 2022 05:05:29 +0000 loongarch64 GNU/Linux"
    tmp_img="$(__gen_test_zboot_kernel "$kernel_ver" 'lz4')"
    run kver_zimage "$tmp_img"
    assert_output "6.1.0-rc5-5"
}

@test "kver_zimage lzma" {
    local kernel_ver='' tmp_knl='' tmp_img=''
    kernel_ver="Linux version 6.1.0-rc5-5 #1 SMP Sat, 17 Dec 2022 05:05:29 +0000 loongarch64 GNU/Linux"
    tmp_img="$(__gen_test_zboot_kernel "$kernel_ver" 'lzma')"
    run kver_zimage "$tmp_img"
    assert_output "6.1.0-rc5-5"
}

@test "kver_zimage lzo" {
    local kernel_ver='' tmp_knl='' tmp_img=''
    kernel_ver="Linux version 6.1.0-rc5-5 #1 SMP Sat, 17 Dec 2022 05:05:29 +0000 loongarch64 GNU/Linux"
    tmp_img="$(__gen_test_zboot_kernel "$kernel_ver" 'lzo')"
    run kver_zimage "$tmp_img"
    assert_output "6.1.0-rc5-5"
}

@test "kver_zimage xz" {
    local kernel_ver='' tmp_knl='' tmp_img=''
    kernel_ver="Linux version 6.1.0-rc5-5 #1 SMP Sat, 17 Dec 2022 05:05:29 +0000 loongarch64 GNU/Linux"
    tmp_img="$(__gen_test_zboot_kernel "$kernel_ver" 'xzkern')"
    run kver_zimage "$tmp_img"
    assert_output "6.1.0-rc5-5"
}

@test "kver_zimage zstd" {
    local kernel_ver='' tmp_knl='' tmp_img=''
    kernel_ver="Linux version 6.1.0-arch1-2 #1 SMP Sat, 17 Dec 2022 05:05:29 +0000 loongarch64 GNU/Linux"
    tmp_img="$(__gen_test_zboot_kernel "$kernel_ver" 'zstd22')"
    run kver_zimage "$tmp_img"
    assert_output "6.1.0-arch1-2"
}

@test "initialize_buildroot success" {
    local parentdir="${BATS_RUN_TMPDIR}/${BATS_TEST_NAME}" workingdir=''

    install -dm755 "$parentdir"
    workingdir="$(TMPDIR="$parentdir" initialize_buildroot 'none')"

    # asserting the entire expected tree would be extremely verbose
    assert [ -n "${workingdir}" ]
    assert [ -e "${workingdir}/early/early_cpio" ]
    assert [ -e "${workingdir}/root/VERSION" ]
}

@test "initialize_buildroot unwriteable parent directory" {
    local parentdir="${BATS_RUN_TMPDIR}/${BATS_TEST_NAME}/"

    install -dm555 "$parentdir"
    TMPDIR="$parentdir" run initialize_buildroot 'none'
    assert_failure
    assert_output "==> ERROR: Failed to create temporary working directory in $parentdir"
}

@test "initialize_buildroot unwriteable working directory" {
    local generatedir="${BATS_RUN_TMPDIR}/${BATS_TEST_NAME}/workdir"

    install -dm555 "$generatedir"
    run initialize_buildroot 'none' "$generatedir"
    assert_failure
    assert_output "==> ERROR: Unable to write to build root: $generatedir"
}

@test "add_file regular file" {
    local dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    install -d -- "$BUILDROOT" "${dir}/testdir"
    printf 'test1\n' >"${dir}/testdir/test1"
    printf 'test2\n' >"${dir}/testdir/test2"

    run add_file "${dir}/testdir/test1"
    run add_file "${dir}/testdir/test2" '/testdir2/testsubdir/test'

    cmp -s "${dir}/testdir/test1" "${BUILDROOT}${dir}/testdir/test1" || return
    cmp -s "${dir}/testdir/test2" "${BUILDROOT}/testdir2/testsubdir/test" || return
    [[ "$(stat -c '%a' "${dir}/testdir/test1")" == "$(stat -c '%a' "${BUILDROOT}${dir}/testdir/test1")" ]] || return
    [[ "$(stat -c '%a' "${dir}/testdir/test2")" == "$(stat -c '%a' "${BUILDROOT}/testdir2/testsubdir/test")" ]] || return
}

@test "add_file with mode" {
    local dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    install -d -- "$BUILDROOT" "${dir}/testdir"
    printf 'test1\n' >"${dir}/testdir/test1"
    printf 'test2\n' >"${dir}/testdir/test2"

    run add_file "${dir}/testdir/test1" "${dir}/testdir/test1" 600
    run add_file "${dir}/testdir/test2" '/testdir2/testsubdir/test' 444

    cmp -s "${dir}/testdir/test1" "${BUILDROOT}${dir}/testdir/test1" || return
    cmp -s "${dir}/testdir/test2" "${BUILDROOT}/testdir2/testsubdir/test" || return
    [[ "$(stat -c '%a' "${BUILDROOT}${dir}/testdir/test1")" == '600' ]] || return
    [[ "$(stat -c '%a' "${BUILDROOT}/testdir2/testsubdir/test")" == '444' ]] || return

}
@test "add_file parent directory is a symlink" {
    local dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    install -d -- "$BUILDROOT" "${dir}/testdir/testsubdir1"
    ln -s -- testsubdir1 "${dir}/testdir/testsubdir2"
    printf 'test\n' >"${dir}/testdir/testsubdir1/1"
    printf 'test\n' >"${dir}/testdir/testsubdir1/2"
    printf 'test\n' >"${dir}/testdir/testsubdir1/3"

    run add_file "${dir}/testdir/testsubdir2/1"
    run add_file "${dir}/testdir/testsubdir2/2"
    run add_file "${dir}/testdir/testsubdir1/3"

    [[ -e "${BUILDROOT}${dir}/testdir/testsubdir2/1" ]] || return
    [[ -e "${BUILDROOT}${dir}/testdir/testsubdir2/3" ]] || return
    [[ -L "${BUILDROOT}${dir}/testdir/testsubdir2" && "$(realpath -- "${BUILDROOT}${dir}/testdir/testsubdir2")" == "${BUILDROOT}${dir}/testdir/testsubdir1" ]] || return
    [[ -e "${BUILDROOT}${dir}/testdir/testsubdir1/1" ]] || return
    [[ -e "${BUILDROOT}${dir}/testdir/testsubdir1/2" ]] || return
}

@test "add_file target is a directory" {
    local dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    install -d -- "$BUILDROOT" "${dir}/testdir/testsubdir1"
    ln -s -- testsubdir1 "${dir}/testdir/testsubdir2"
    printf 'test1\n' >"${dir}/testdir/test1"
    printf 'test2\n' >"${dir}/testdir/test2"

    run add_file "${dir}/testdir/test1" '/testdir2/'
    run add_file "${dir}/testdir/test2" '/testdir3/testsubdir1/' 400

    [[ -d "${BUILDROOT}/testdir2/" ]] || return
    [[ -d "${BUILDROOT}/testdir3/testsubdir1/" ]] || return
    cmp -s "${dir}/testdir/test1" "${BUILDROOT}/testdir2/test1" || return
    cmp -s "${dir}/testdir/test2" "${BUILDROOT}/testdir3/testsubdir1/test2" || return
    [[ "$(stat -c '%a' "${dir}/testdir/test1")" == "$(stat -c '%a' "${BUILDROOT}/testdir2/test1")" ]] || return
    [[ "$(stat -c '%a' "${BUILDROOT}/testdir3/testsubdir1/test2")" == '400' ]] || return
}

@test "add_file from stdin" {
    local dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}" _optquiet=1
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    install -d -- "$BUILDROOT"

    file_from_stdin1() {
        printf 'test1\n' | add_file - '/testdir/test1' 600
    }

    file_from_stdin2() {
        printf 'test2\n' | add_file - '/testdir/test2'
    }

    run file_from_stdin1
    assert_success
    cmp -s <(printf 'test1\n') "${BUILDROOT}/testdir/test1" || return
    run file_from_stdin2
    assert_failure
    run add_file /dev/null '/testdir/test3' 644
    assert_success
    cmp -s /dev/null "${BUILDROOT}/testdir/test3" || return
}

@test "add_binary script" {
    local tmp_bin BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}/" interpreter="/usr/local/${BATS_TEST_NAME}.${RANDOM}" _optquiet=1

    tmp_bin="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_bin.XXXXXX)"
    printf '#!%s\n\n:\n' "$interpreter" >"$tmp_bin"

    install -d -- "$BUILDROOT"
    initialize_buildroot 'none' "$BUILDROOT"
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
    LC_ALL=C.UTF-8 diff -r "${dir}/" "${BUILDROOT}/${dir}/"
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

@test "find_module_from_symbol" {
    local KERNELVERSION
    KERNELVERSION="$(uname -r)"

    if [[ ! -d "/lib/modules/${KERNELVERSION}/" ]]; then
        skip "No kernel modules available"
    fi

    run find_module_from_symbol "drm_privacy_screen_register" "=drivers/platform"
    assert_output --partial "thinkpad_acpi"
}

@test "include_files" {
    local dir BUILDROOT="${BATS_RUN_TMPDIR}/buildroot.${BATS_TEST_NAME}" _optquiet=0
    dir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    install -d -- "$BUILDROOT" "${dir}"
    touch "${dir}/create_root"
    run include_files "${dir}/create_root:/sbin/init"
    [[ ! -e "${BUILDROOT}/create_root" ]] || return
    [[ -e "${BUILDROOT}/sbin/init" ]] || return
}
