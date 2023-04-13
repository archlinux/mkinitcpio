#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

@test "test reproducible builds for initramfs" {
    local tmpdir
    tmpdir=$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")

    echo "HOOKS=(base)" >> "$tmpdir/mkinitcpio.conf"

    run ./mkinitcpio \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs-1.img"

    run ./mkinitcpio \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs-2.img"

    run cmp "$tmpdir/initramfs-1.img" "$tmpdir/initramfs-2.img"
    (( status == 0 ))
}


@test "test reproducible builds for uki" {
    local tmpdir
    tmpdir=$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")

    echo "HOOKS=(base)" >> "$tmpdir/mkinitcpio.conf"

    ./mkinitcpio \
        -c "$tmpdir/mkinitcpio.conf" \
        --uki "$tmpdir/uki-1.efi"

    ./mkinitcpio \
        -c "$tmpdir/mkinitcpio.conf" \
        --uki "$tmpdir/uki-2.efi"

    sha256sum "$tmpdir/uki-1.efi" "$tmpdir/uki-2.efi"
    run cmp "$tmpdir/uki-1.efi" "$tmpdir/uki-2.efi"
    (( status == 0 ))
}
