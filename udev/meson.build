# SPDX-License-Identifier: GPL-2.0-only

udev_rules = [
    '01-memdisk.rules',
]

foreach rule: udev_rules
    configure_file(
        input: rule,
        output: rule,
        configuration: conf_data,
        install_dir: initcpio_libdir / 'udev',
    )
endforeach
