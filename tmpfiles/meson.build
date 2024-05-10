# SPDX-License-Identifier: GPL-2.0-only

if tmpfiles.found()
    configure_file(
        input: '20-mkinitcpio.conf',
        output: '20-mkinitcpio.conf',
        configuration: conf_data,
        install_dir: tmpfiles_dir,
    )
endif
