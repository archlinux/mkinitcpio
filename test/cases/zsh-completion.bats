shopt -s extglob

load '/usr/lib/bats-assert/load'
load "../helpers/common"

setup() {
    source ./shell/zsh-completion || true
}

@test "_detect_kver" {
    local kernel_ver tmp_knl
    kernel_ver="6.0.9-arch1-1 #1 SMP PREEMPT_DYNAMIC Wed, 16 Nov 2022 17:01:17 +0000 x86_64 GNU/Linux"
    tmp_knl=$(__gen_test_kernel "$kernel_ver")
    run _detect_kver "$tmp_knl"
    assert_output "6.0.9-arch1-1"
}
