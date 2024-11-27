# SPDX-License-Identifier: GPL-2.0-only

presets = [
    'example.preset',
    'hook.preset',
]

if want_presets
    foreach preset: presets
        configure_file(
            input: preset,
            output: preset,
            configuration: conf_data,
            install_dir: datadir / 'mkinitcpio',
        )
    endforeach
endif
