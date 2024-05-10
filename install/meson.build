# SPDX-License-Identifier: GPL-2.0-only

hooks = [
    'acpi_override',
    'autodetect',
    'base',
    'block',
    'consolefont',
    'encrypt',
    'filesystems',
    'fsck',
    'hostdata',
    'keyboard',
    'keymap',
    'kms',
    'lvm2',
    'mdadm_udev',
    'memdisk',
    'microcode',
    'modconf',
    'resume',
    'shutdown',
    'sleep',
    'strip',
    'udev',
    'usr',
]

systemd_hooks = [
    'sd-encrypt',
    'sd-shutdown',
    'sd-vconsole',
    'systemd',
]

if want_systemd.enabled()
    hooks += systemd_hooks
endif

foreach hook: hooks
    configure_file(
        input: hook,
        output: hook,
        configuration: conf_data,
        install_dir: initcpio_libdir / 'install',
    )
endforeach
