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
    printf "%b" '\x10\x02' >>"$tmp_knl"
    # pad with 0x200 (512) bytes
    dd if=/dev/zero of="$tmp_knl" bs=1 count=512 oflag=append conv=notrunc
    # append kernel version
    echo "$kernel_ver" >>"$tmp_knl"
    echo "$tmp_knl"
}

# Generates a temporary zboot dummy kernel, with the passed string as kernel version and specified compression type
__gen_test_zboot_kernel() {
    local kernel_ver="$1"
    local comp_type="$2"
    local tmp_img tmp_file
    local num count size start
    local compress_opts

    tmp_img="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_img.XXXXXX)"
    tmp_file="$(mktemp --tmpdir="$BATS_RUN_TMPDIR" tmp_file.XXXXXX)"

    # generate image with random size between 256 to 1024, 4 bytes align
    num=$(head -n 10 /dev/urandom | cksum | awk -F ' ' '{print $1}')
    count=$((num%192*4+512))
    dd if=/dev/zero of="$tmp_img" count="$count" bs=1 status=none

    trap '{ rm -f -- "$tmp_img"; }' EXIT
    trap '{ rm -f -- "$tmp_file"; }' EXIT

    case $comp_type in
        gzip)
            compress_opts=("gzip")
            ;;
        lz4)
            compress_opts=("lz4")
            ;;
        lzma)
            compress_opts=("lzma")
            ;;
        lzo)
            compress_opts=("lzop")
            ;;
        xzkern)
            compress_opts=("xz" "--check=crc32")
            ;;
        zstd22)
            compress_opts=("zstd" "-T0")
            ;;
        *)
            echo "Compress type is not supported"
            return 1
            ;;
    esac

    echo "$kernel_ver" | "${compress_opts[@]}" > "$tmp_file"
    cat "$tmp_file" >> "$tmp_img"
    size=$(stat -c %s "$tmp_file")

    # write "zimg" into image at 0x04
    printf "zimg" | dd of="$tmp_img" seek="$((0x4))" bs=1 count=4 status=none conv=notrunc

    # write COMP_TYPE string into image at 0x18
    printf '%s' "$comp_type" | dd of="$tmp_img" seek="$((0x18))" bs=1 count=36 status=none conv=notrunc

    # write compress data start offset at 0x08
    start=$(printf "%08x" "$count")
    echo -n -e "\\x${start:6:2}\\x${start:4:2}\\x${start:2:2}\\x${start:0:2}" | dd of="$tmp_img" seek=$((0x8)) bs=1 count=4 status=none conv=notrunc

    # write compress data size offset at 0x0c
    size=$(printf "%08x\n" "$size")
    echo -n -e "\\x${size:6:2}\\x${size:4:2}\\x${size:2:2}\\x${size:0:2}" | dd of="$tmp_img" seek=$((0xc)) bs=1 count=4 status=none conv=notrunc

    rm -f -- "$tmp_file"
    echo "$tmp_img"
}

# Generates a temporary initcpio with the specified compression options
__gen_test_initcpio() {
    local tmpdir compression="$1"
    tmpdir=$(mktemp -d --tmpdir="$BATS_RUN_TMPDIR" "${BATS_TEST_NAME}.XXXXXX")

    cat << EOC >> "$tmpdir/mkinitcpio.conf"
HOOKS=(base)
COMPRESSION=$compression
EOC

    ./mkinitcpio \
        -D "${PWD}" \
        -c "$tmpdir/mkinitcpio.conf" \
        -g "$tmpdir/initramfs.img"
}

__check_binary(){
    local binary="$1"
    if ! command -v "${binary}" &>/dev/null; then
        skip "${binary} not installed"
    fi
}
