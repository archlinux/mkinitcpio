# SPDX-License-Identifier: GPL-2.0-only

if want_kernel_install
    configure_file(
        input: '50-mkinitcpio.install',
        output: '50-mkinitcpio.install',
        configuration: conf_data,
        install_dir: libdir / 'kernel/install.d',
        install_mode: 'rwxr-xr-x',
    )
endif
