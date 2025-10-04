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

@test "preset with ALL_cmdline and ALL_splash" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir kver
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    kver="$(uname -r)"

    # Create test kernel
    tmp_knl="$(__gen_test_kernel "$kver")"
    ln -s "$tmp_knl" "$tmpdir/vmlinuz-test"

    # Create config file
    echo 'HOOKS=(base)' > "$tmpdir/mkinitcpio.conf"

    # Create cmdline file
    echo 'root=/dev/sda1 rw quiet' > "$tmpdir/cmdline"

    # Create splash file
    __gen_bmp > "$tmpdir/splash.bmp"

    # Create preset file
    cat > "$tmpdir/test.preset" <<EOF
PRESETS=('default' 'fallback')

ALL_kver='$tmpdir/vmlinuz-test'
ALL_config='$tmpdir/mkinitcpio.conf'
ALL_cmdline='$tmpdir/cmdline'
ALL_splash='$tmpdir/splash.bmp'

default_uki='$tmpdir/default.efi'
fallback_uki='$tmpdir/fallback.efi'
EOF

    # Build from preset
    run ./mkinitcpio -p "$tmpdir/test.preset" --no-ukify
    assert_success
    assert_output --partial "Building image from preset"

    # Verify UKIs were created
    [[ -f "$tmpdir/default.efi" ]]
    [[ -f "$tmpdir/fallback.efi" ]]

    # Extract sections from default UKI to verify cmdline and splash
    objcopy --dump-section ".cmdline=$tmpdir/default.cmdline" "$tmpdir/default.efi"
    objcopy --dump-section ".splash=$tmpdir/default.splash" "$tmpdir/default.efi"

    # Verify cmdline content (with added null terminator and space)
    printf 'root=/dev/sda1 rw quiet \n\0' > "$tmpdir/expected.cmdline"
    cmp "$tmpdir/expected.cmdline" "$tmpdir/default.cmdline"

    # Verify splash was included
    cmp "$tmpdir/splash.bmp" "$tmpdir/default.splash"
}

@test "preset with individual cmdline overrides" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir kver
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    kver="$(uname -r)"

    # Create test kernel
    tmp_knl="$(__gen_test_kernel "$kver")"
    ln -s "$tmp_knl" "$tmpdir/vmlinuz-test"

    # Create config file
    echo 'HOOKS=(base)' > "$tmpdir/mkinitcpio.conf"

    # Create different cmdline files
    echo 'root=/dev/sda1 rw' > "$tmpdir/cmdline-default"
    echo 'root=/dev/sda1 rw single' > "$tmpdir/cmdline-rescue"

    # Create preset file
    cat > "$tmpdir/test.preset" <<EOF
PRESETS=('default' 'rescue')

ALL_kver='$tmpdir/vmlinuz-test'
ALL_config='$tmpdir/mkinitcpio.conf'
ALL_cmdline='$tmpdir/cmdline-default'

default_uki='$tmpdir/default.efi'
rescue_uki='$tmpdir/rescue.efi'
rescue_cmdline='$tmpdir/cmdline-rescue'
EOF

    # Build from preset
    run ./mkinitcpio -p "$tmpdir/test.preset" --no-ukify
    assert_success

    # Extract cmdline sections
    objcopy --dump-section ".cmdline=$tmpdir/default.cmdline.out" "$tmpdir/default.efi"
    objcopy --dump-section ".cmdline=$tmpdir/rescue.cmdline.out" "$tmpdir/rescue.efi"

    # Verify default uses ALL_cmdline
    printf 'root=/dev/sda1 rw \n\0' > "$tmpdir/expected.default"
    cmp "$tmpdir/expected.default" "$tmpdir/default.cmdline.out"

    # Verify rescue uses its own cmdline
    printf 'root=/dev/sda1 rw single \n\0' > "$tmpdir/expected.rescue"
    cmp "$tmpdir/expected.rescue" "$tmpdir/rescue.cmdline.out"
}

@test "preset cmdline and splash work with options array" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir kver
    tmpdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"
    kver="$(uname -r)"

    # Create test kernel
    tmp_knl="$(__gen_test_kernel "$kver")"
    ln -s "$tmp_knl" "$tmpdir/vmlinuz-test"

    # Create config files
    echo 'HOOKS=(base)' > "$tmpdir/mkinitcpio.conf"
    echo 'HOOKS=(base udev)' > "$tmpdir/mkinitcpio-custom.conf"

    # Create cmdline and splash
    echo 'root=/dev/sda1 rw' > "$tmpdir/cmdline"
    dd if=/dev/zero of="$tmpdir/splash.bmp" bs=1K count=1

    # Create preset file that mixes preset variables with options
    cat > "$tmpdir/test.preset" <<EOF
PRESETS=('default')

ALL_kver='$tmpdir/vmlinuz-test'
ALL_cmdline='$tmpdir/cmdline'
ALL_splash='$tmpdir/splash.bmp'

default_uki='$tmpdir/default.efi'
default_options='-c $tmpdir/mkinitcpio-custom.conf'
EOF

    __gen_bmp > "$tmpdir/splash.bmp"

    # Build from preset
    run ./mkinitcpio -p "$tmpdir/test.preset" --no-ukify
    assert_success
    assert_output --partial "$tmpdir/mkinitcpio-custom.conf"

    # Verify UKI was created
    [[ -f "$tmpdir/default.efi" ]]

    # Verify cmdline was still used despite options
    objcopy --dump-section ".cmdline=$tmpdir/default.cmdline.out" "$tmpdir/default.efi"
    printf 'root=/dev/sda1 rw \n\0' > "$tmpdir/expected.cmdline"
    cmp "$tmpdir/expected.cmdline" "$tmpdir/default.cmdline.out"

    # Verify splash was included (preset variables are processed after options)
    objcopy --dump-section ".splash=$tmpdir/default.splash.out" "$tmpdir/default.efi"
    cmp "$tmpdir/splash.bmp" "$tmpdir/default.splash.out"
}
