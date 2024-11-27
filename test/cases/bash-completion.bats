#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

bats_load_library 'bats-assert'
bats_load_library 'bats-support'
load "../helpers/common"

setup() {
    # shellcheck disable=SC1091
    source ./shell/mkinitcpio || true
}

@test "_detect_kver" {
    local kernel_ver tmp_knl
    local arch
    arch="$(uname -m)"

    kernel_ver="6.0.9-arch1-1 #1 SMP PREEMPT_DYNAMIC Wed, 16 Nov 2022 17:01:17 +0000 x86_64 GNU/Linux"

    # For non-i686/x86_64 platform, we rely on Linux banner for version detection.
    # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/init/version-timestamp.c?h=v6.7#n28
    [[ "$arch" != @(i?86|x86_64) ]] && kernel_ver="Linux version ${kernel_ver}"

    tmp_knl=$(__gen_test_kernel "$kernel_ver")
    run _detect_kver "$tmp_knl"
    assert_output "6.0.9-arch1-1"
}
