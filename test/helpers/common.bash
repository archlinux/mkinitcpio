#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only

# Generates a temporary image with the specified compression options
__gen_test_image() {
    local compress_opts tmp_img tmp_file
    compress_opts=("${@:-cat}")
    tmp_img="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_img.XXXXXX)"
    tmp_file="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_file.XXXXXX)"
    trap '{ rm -f -- "$tmp_img"; }' EXIT
    trap '{ rm -f -- "$tmp_file"; }' EXIT
    echo "this is a test file" > "$tmp_file"
    bsdtar -cf - "$tmp_file" | "${compress_opts[@]}" > "$tmp_img"
    rm -f -- "$tmp_file"
    echo "$tmp_img"
}

# Generates a temporary dummy kernel, setting the passed string as kernel version
__gen_test_kernel() {
    local kernel_ver tmp_knl
    kernel_ver="$1"
    tmp_knl="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_knl.XXXXXX)"
    # generate a file of 526 bytes to 0x20E
    dd if=/dev/zero of="$tmp_knl" count=526 bs=1
    # set the offset value at 0x20E to point to the very next byte at 0x210
    printf "%b" '\x10\x02' >> "$tmp_knl"
    # pad with 0x200 (512) bytes
    dd if=/dev/zero of="$tmp_knl" bs=1 count=512 oflag=append conv=notrunc
    # append kernel version
    echo "$kernel_ver" >> "$tmp_knl"
    echo "$tmp_knl"
}
