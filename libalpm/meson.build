# SPDX-License-Identifier: GPL-2.0-only

alpm_hooks = [
    '60-mkinitcpio-remove.hook',
    '90-mkinitcpio-install.hook',
]

alpm_scripts = [
    'mkinitcpio',
]

if want_alpm
    foreach hook: alpm_hooks
        configure_file(
            input: 'hooks' / hook,
            output: hook,
            configuration: conf_data,
            install_dir: datadir / 'libalpm/hooks',
        )
    endforeach

    foreach script: alpm_scripts
        configure_file(
            input: 'scripts' / script,
            output: script,
            configuration: conf_data,
            install_dir: datadir / 'libalpm/scripts',
            install_mode: 'rwxr-xr-x',
        )
    endforeach
endif
