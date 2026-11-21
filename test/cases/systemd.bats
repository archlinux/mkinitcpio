#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
    source 'functions'
    source 'install/systemd'
    _d_units="$BATS_TEST_TMPDIR/units"
    mkdir -p "$_d_units"

    # shellcheck disable=SC2329
    type() {
        if [[ "$1" == '-P' ]]; then
            printf '%s\n' "$2" >> "$_d_units/lookups"
            if [[ -f "$_d_units/$2" ]]; then
                printf '%s\n' "$_d_units/$2"
                return
            fi
        fi
        builtin type "$@"
    }

    # shellcheck disable=SC2329
    add_file() {
        printf '%s\n' "${1##*/}"
    }
}

@test "add_systemd_unit follows BindsTo and its transitive dependencies" {
    printf '[Unit]\nBindsTo=bound.service\n' > "$_d_units/main.service"
    printf '[Unit]\nRequires=required.socket\n' > "$_d_units/bound.service"
    printf '[Socket]\nListenStream=/run/example\n' > "$_d_units/required.socket"

    run add_systemd_unit main.service
    assert_success
    assert_output $'main.service\nbound.service\nrequired.socket'
}

@test "add_systemd_unit skips device and specifier dependencies" {
    cat > "$_d_units/main@.service" <<'EOF'
[Unit]
BindsTo=%i.device dev-sda.device bound.service
Requires=%i.mount required.socket
EOF
    printf '[Service]\n' > "$_d_units/bound.service"
    printf '[Socket]\n' > "$_d_units/required.socket"

    run add_systemd_unit main@.service
    assert_success
    assert_output $'main@.service\nbound.service\nrequired.socket'
    assert_equal "$(< "$_d_units/lookups")" $'main@.service\nbound.service\nrequired.socket'
}

@test "add_systemd_unit stops dependency cycles and retains sibling dependencies" {
    printf '[Unit]\nBindsTo=bound.service sibling.socket\n' > "$_d_units/main.service"
    printf '[Unit]\nRequires=main.service\n' > "$_d_units/bound.service"
    printf '[Socket]\n' > "$_d_units/sibling.socket"

    FUNCNEST=32 run add_systemd_unit main.service
    assert_success
    assert_output $'main.service\nbound.service\nsibling.socket'
}

@test "add_systemd_unit scans dependencies again on independent calls" {
    printf '[Unit]\nBindsTo=bound.service\n' > "$_d_units/main.service"
    printf '[Service]\n' > "$_d_units/bound.service"

    add_systemd_unit main.service > "$BATS_TEST_TMPDIR/first"
    add_systemd_unit main.service > "$BATS_TEST_TMPDIR/second"
    assert_equal "$(< "$BATS_TEST_TMPDIR/first")" $'main.service\nbound.service'
    assert_equal "$(< "$BATS_TEST_TMPDIR/second")" $'main.service\nbound.service'
}

@test "add_systemd_unit follows OnFailure, OnSuccess and .requires dependencies" {
    printf '[Unit]\nOnFailure=failed.service\nOnSuccess=succeeded.service\n' > "$_d_units/main.service"
    printf '[Service]\n' > "$_d_units/failed.service"
    printf '[Service]\n' > "$_d_units/succeeded.service"
    mkdir "$_d_units/main.service.requires"
    printf '[Unit]\nRequires=main.service\n' > "$_d_units/required.service"
    ln -s ../required.service "$_d_units/main.service.requires/required.service"

    FUNCNEST=32 run add_systemd_unit main.service
    assert_success
    assert_output $'main.service\nfailed.service\nsucceeded.service\nrequired.service'
}

@test "add_systemd_unit does not pull in Wants dependencies" {
    printf '[Unit]\nWants=optional.service\n' > "$_d_units/main.service"
    printf '[Service]\n' > "$_d_units/optional.service"

    run add_systemd_unit main.service
    assert_success
    assert_output 'main.service'
}
