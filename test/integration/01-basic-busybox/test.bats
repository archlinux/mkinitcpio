#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
    return
}

@test "run qemu" {
    local rootdir
    rootdir="$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")"

    ./mkinitcpio \
        -d "${rootdir}" \
        -A base \
        -c "/dev/null"

    install -Dm777 "$BATS_TEST_DIRNAME/test_init" "$rootdir/sbin/init"

    dd if=/dev/zero of="$BATS_TEST_TMPDIR"/root.img bs=1MiB count=80
    mkfs.ext4 -d "$rootdir/" "$BATS_TEST_TMPDIR"/root.img

    {
        echo "MODULES=(ext4)"
        echo "HOOKS=(base)"
    } >> "$BATS_RUN_TMPDIR/mkinitcpio.conf"

    ./mkinitcpio \
        -D "$PWD" \
        -c "$BATS_RUN_TMPDIR/mkinitcpio.conf" \
        -g "$BATS_RUN_TMPDIR/initramfs.img"

    run test/integration/run-qemu \
        -append "root=/dev/sda rootfstype=ext4 rw quiet console=ttyS0,115200n81" \
        -drive "if=none,format=raw,file=$BATS_TEST_TMPDIR/root.img,id=drive-sata1" \
        -device "ide-hd,bus=ide.1,drive=drive-sata1,id=sata1,model=disk,serial=root" \
        -initrd "$BATS_RUN_TMPDIR/initramfs.img"

    assert_success
    assert_output --partial 'mkinitcpio-booted'
}
