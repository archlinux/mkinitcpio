#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

bats_load_library 'bats-assert'
bats_load_library 'bats-support'
load "../helpers/common"

@test "test reproducible builds for initramfs" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    echo "HOOKS=(base)" >> "$tmpdir/mkinitcpio.conf"

    run ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs-1.img"

    run ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs-2.img"

    cmp "$tmpdir/initramfs-1.img" "$tmpdir/initramfs-2.img"
}

__validate_uki() {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local mode="$1" tmpdir kver
    shift
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    kver="$(uname -r)"

    tmp_knl="$(__gen_test_kernel "$kver")"
    ln -s "$tmp_knl" "$tmpdir/linux.in"
    printf '%s' "$kver" > "$tmpdir/uname.in"
    printf 'VERSION_ID=%s\n' "$kver" > "$tmpdir/osrel.in"
    grep -v '^VERSION_ID=' /etc/os-release >> "$tmpdir/osrel.in"
    printf '%s' 'root=gpt-auto rw' > "$tmpdir/cmdline.in"
    ln -s "$BATS_TEST_DIRNAME/../fixtures/uki/splash.bmp" "$tmpdir/splash.in"

    echo 'HOOKS=(base)' > "$tmpdir/mkinitcpio.conf"
    run ./mkinitcpio \
        -t "$tmpdir" \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        --kernel "$tmpdir/linux.in" \
        --generate "$tmpdir/initrd.in" \
        --cmdline "$tmpdir/cmdline.in" \
        --osrelease "$tmpdir/osrel.in" \
        --splash "$tmpdir/splash.in" \
        --uki "$tmpdir/uki.efi" \
        --verbose "$@"
    assert_success
    assert_output --partial "Using $mode to build UKI"
    assert_output --partial "Assembling UKI: $mode "

    printf ' \n\0' >> "$tmpdir/cmdline.in"

    objcopy \
        --dump-section ".linux=$tmpdir/linux.out" \
        --dump-section ".initrd=$tmpdir/initrd.out" \
        --dump-section ".uname=$tmpdir/uname.out" \
        --dump-section ".osrel=$tmpdir/osrel.out" \
        --dump-section ".cmdline=$tmpdir/cmdline.out" \
        --dump-section ".splash=$tmpdir/splash.out" \
        "$tmpdir/uki.efi"

    cmp "$tmpdir"/linux.{in,out}
    cmp "$tmpdir"/initrd.{in,out}
    cmp "$tmpdir"/uname.{in,out}
    cmp "$tmpdir"/osrel.{in,out}
    cmp "$tmpdir"/cmdline.{in,out}
    cmp "$tmpdir"/splash.{in,out}
}

@test "test creating UKI with ukify" {
    if ! command -v ukify &>/dev/null; then
        skip "ukify is not available"
    fi
    __validate_uki ukify --ukiconfig /dev/null
}

@test "test creating UKI with objcopy" {
    __validate_uki objcopy --no-ukify
}

@test "test reproducible builds for UKI" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    echo "HOOKS=(base)" >> "$tmpdir/mkinitcpio.conf"

    ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        --uki "$tmpdir/uki-1.efi" \
        --no-ukify

    ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        --uki "$tmpdir/uki-2.efi" \
        --no-ukify

    sha256sum "$tmpdir/uki-1.efi" "$tmpdir/uki-2.efi"
    cmp "$tmpdir/uki-1.efi" "$tmpdir/uki-2.efi"
}

@test "test creating UKI with no cmdline" {
    bats_require_minimum_version 1.5.0
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip 'No kernel modules available'
    fi

    local tmpdir
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    printf '%s\n' 'HOOKS=(base)' > "${tmpdir}/mkinitcpio.conf"

    ./mkinitcpio \
        -D "${PWD}" \
        -c "${tmpdir}/mkinitcpio.conf" \
        --uki "${tmpdir}/uki.efi" \
        --no-ukify \
        --no-cmdline

    run objdump -h "${tmpdir}/uki.efi"
    assert_success
    refute_output --partial ' .cmdline '
    assert_output --partial ' .linux '
    assert_output --partial ' .initrd '
    assert_output --partial ' .uname '
}

@test "test early cpio creation" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    echo "HOOKS=(base test)" >> "$tmpdir/mkinitcpio.conf"
    install -dm755 "$tmpdir/install"
    cat << EOH >> "$tmpdir/install/test"
#!/usr/bin/env bash
build() {
    echo "this is a test" > "\${EARLYROOT}/some_file"
}
EOH

    run ./mkinitcpio \
        -D "${PWD}" -D "$tmpdir" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs.img"

    assert_output --partial '-> Early uncompressed CPIO image generation successful'
}

@test "test moving compressed files to early cpio" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    echo "HOOKS=(test) COMPRESSION=zstd" >> "$tmpdir/mkinitcpio.conf"
    install -dm755 "$tmpdir/install"
    cat << EOH >> "$tmpdir/install/test"
#!/usr/bin/env bash
build() {
    mkdir -p "\$BUILDROOT"/test/{compressed,mixed,uncompressed}
    touch "\$BUILDROOT"/test/{compressed/dummy,mixed/dummy}.zst
    touch "\$BUILDROOT"/test/{mixed/dummy,uncompressed/dummy}
}
EOH

    ./mkinitcpio \
        -D "$tmpdir" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs.img"

    run ./lsinitcpio --early "$tmpdir/initramfs.img"
    assert_line 'test/compressed/dummy.zst'
    assert_line 'test/mixed/dummy.zst'
    refute_line 'test/uncompressed'

    run ./lsinitcpio --cpio "$tmpdir/initramfs.img"
    refute_line 'test/compressed'
    assert_line 'test/mixed/dummy'
    assert_line 'test/uncompressed/dummy'
    refute_output --regexp '.*\.zst$'
}

@test "image creation zstd" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio zstd
}

@test "image creation gzip" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio gzip
}

@test "image creation bzip2" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio bzip2
}

@test "image creation lzma" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio lzma
}

@test "image creation xz" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio xz
}

@test "image creation lzop" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio lzop
}

@test "image creation lz4" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio lz4
}

@test "image creation uncompressed" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    __gen_test_initcpio cat
}
