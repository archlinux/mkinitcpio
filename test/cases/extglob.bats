#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only
load '/usr/lib/bats-support/load'

@test "check for syntax errors" {
    local bash_scripts=(mkinitcpio lsinitcpio)
    for s in "${bash_scripts[@]}"; do
       bash -O extglob -n "${s}"
    done
}
