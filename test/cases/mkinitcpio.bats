#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

@test "test reproducible builds for initramfs" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir
    tmpdir=$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")

    echo "HOOKS=(base)" >> "$tmpdir/mkinitcpio.conf"

    run ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs-1.img"

    run ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs-2.img"

    run cmp "$tmpdir/initramfs-1.img" "$tmpdir/initramfs-2.img"
    (( status == 0 ))
}


@test "test reproducible builds for uki" {
    if [[ ! -d "/lib/modules/$(uname -r)/" ]]; then
        skip "No kernel modules available"
    fi

    local tmpdir
    tmpdir=$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")

    echo "HOOKS=(base)" >> "$tmpdir/mkinitcpio.conf"

    ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        --uki "$tmpdir/uki-1.efi"

    ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        --uki "$tmpdir/uki-2.efi"

    sha256sum "$tmpdir/uki-1.efi" "$tmpdir/uki-2.efi"
    run cmp "$tmpdir/uki-1.efi" "$tmpdir/uki-2.efi"
    (( status == 0 ))
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
        --uki "${tmpdir}/uki.efi" --no-cmdline

    run objdump -j .uname -s "${tmpdir}/uki.efi"
    run -1 objdump -j .cmdline -s "${tmpdir}/uki.efi"
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
