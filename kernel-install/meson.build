# SPDX-License-Identifier: GPL-2.0-only
#
kernel_install_scripts = [
    'archlinux-bootchain',
    'kernel-install',
]

if want_kernel_install
    configure_file(
        input: 'install.d' / '50-mkinitcpio.install',
        output: '50-mkinitcpio.install',
        configuration: conf_data,
        install_dir: libdir / 'kernel/install.d',
        install_mode: 'rwxr-xr-x',
    )

    foreach script: kernel_install_scripts
        configure_file(
            input: 'scripts' / script,
            output: script,
            configuration: conf_data,
            install_dir: mkinitcpio_libdir,
            install_mode: 'rwxr-xr-x',
        )
    endforeach
endif
