#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

BATS_TEST_TIMEOUT=30

# shellcheck disable=SC2317
setup() {

    # First we make our rootfs. This is the FS systemd will be booting.
    tmpdir_rootfs=$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "rootfs.XXX")

    # Make our root filesystem
    ./mkinitcpio \
        -d "${tmpdir_rootfs}" \
        -A base \
        -c "/dev/null"

    # We replace the rootfs init with our own test_init to make the marker
    (
        # shellcheck disable=SC1091
        . functions
        export BUILDROOT="${tmpdir_rootfs}"
        add_file "$BATS_TEST_DIRNAME/test_init" "/sbin/init"
    )

    # This sets up an initramfs that will create our rootfs
    {
        echo "MODULES=(ext4)"
        echo "HOOKS=(base udev encrypt)"
    } >>  "$BATS_RUN_TMPDIR/mkinitcpio.conf"

    # We include our bootable rootfs into this initramfs so we can setup the disk.
    # it's included under /rootfs
    ./mkinitcpio \
        -D "$PWD" \
        -i "/usr/bin/mkfs.ext4" \
        -i "${tmpdir_rootfs}:/rootfs" \
        -i "$BATS_TEST_DIRNAME/create_root:/init" \
        -c "$BATS_RUN_TMPDIR/mkinitcpio.conf" \
        -g "$BATS_RUN_TMPDIR/initramfs.img"

    dd if=/dev/zero of="$BATS_TEST_TMPDIR"/root.img bs=1MiB count=80

    # TEST setup for debug
    # run test/integration/run-debug-qemu \
    #     -append "root=/dev/sda init=/bin/sh rootfstype=ext4 rw quiet console=ttyS0,115200n81" \
    #     -drive "if=none,format=raw,file=$BATS_TEST_TMPDIR/root.img,id=drive-sata1" \
    #     -device "ide-hd,bus=ide.1,drive=drive-sata1,id=sata1,model=disk,serial=root" \
    #     -initrd "$BATS_RUN_TMPDIR/initramfs.img" || return 1
  
    # This creates our rootfs, ext4 with a bootable filesystem.
    run test/integration/run-qemu \
        -append "root=/dev/sda rootfstype=ext4 rw console=ttyS0,115200n81" \
        -drive "if=none,format=raw,file=$BATS_TEST_TMPDIR/root.img,id=drive-sata1" \
        -device "ide-hd,bus=ide.1,drive=drive-sata1,id=sata1,model=disk,serial=root" \
        -initrd "$BATS_RUN_TMPDIR/initramfs.img" || return 1

    assert_success
    assert_output --partial 'mkinitcpio-test-created-root'

    # This is our test case. A minimal systemd initramfs
    {
        echo "MODULES=(ext4)"
        echo "HOOKS=(systemd)"
    } >>  "$BATS_RUN_TMPDIR/mkinitcpio.conf"

    ./mkinitcpio \
        -D "$PWD" \
        -c "$BATS_RUN_TMPDIR/mkinitcpio.conf" \
        -g "$BATS_RUN_TMPDIR/initramfs_testing.img"
}

@test "test basic systemd boot" {
    run test/integration/run-qemu \
        -append "root=/dev/sda rootfstype=ext4 rw console=ttyS0,115200n81" \
        -drive "if=none,format=raw,file=$BATS_TEST_TMPDIR/root.img,id=drive-sata1" \
        -device "ide-hd,bus=ide.1,drive=drive-sata1,id=sata1,model=disk,serial=root" \
        -initrd "$BATS_RUN_TMPDIR/initramfs_testing.img" || return 1

    assert_success
    assert_output --partial 'mkinitcpio-test-completed'
}
