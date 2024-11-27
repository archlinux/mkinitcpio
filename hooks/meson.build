# SPDX-License-Identifier: GPL-2.0-only

hooks = [
    'consolefont',
    'encrypt',
    'keymap',
    'memdisk',
    'resume',
    'shutdown',
    'sleep',
    'udev',
    'usr',
]

foreach hook: hooks
    configure_file(
        input: hook,
        output: hook,
        configuration: conf_data,
        install_dir: initcpio_libdir / 'hooks',
    )
endforeach
