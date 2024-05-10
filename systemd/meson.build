# SPDX-License-Identifier: GPL-2.0-only

if not want_systemd.enabled()
    subdir_done()
endif

shutdown_targets = [
    'halt.target.wants',
    'kexec.target.wants',
    'poweroff.target.wants',
    'reboot.target.wants',
]

configure_file(
    input: 'mkinitcpio-generate-shutdown-ramfs.service',
    output: 'mkinitcpio-generate-shutdown-ramfs.service',
    configuration: conf_data,
    install_dir: systemd_system_unit_dir,
)
foreach tgt: shutdown_targets
    install_symlink(
        'mkinitcpio-generate-shutdown-ramfs.service',
        pointing_to: '../mkinitcpio-generate-shutdown-ramfs.service',
        install_dir: systemd_system_unit_dir / tgt,
    )
endforeach
