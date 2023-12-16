#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only
bats_load_library 'bats-support'

@test "check for syntax errors" {
    local bash_scripts=(mkinitcpio lsinitcpio)
    for s in "${bash_scripts[@]}"; do
        bash -O extglob -n "${s}"
    done
}
