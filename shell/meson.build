# SPDX-License-Identifier: GPL-2.0-only

configure_file(
    input: 'bash-completion',
    output: 'mkinitcpio',
    configuration: conf_data,
    install_dir: bashcompletiondir,
    install_tag: 'completions',
)

install_symlink(
    'lsinitcpio',
    pointing_to: 'mkinitcpio',
    install_dir: bashcompletiondir,
    install_tag: 'completions',
)

configure_file(
    input: 'zsh-completion',
    output: '_mkinitcpio',
    configuration: conf_data,
    install_dir: zshcompletiondir,
    install_tag: 'completions',
)
