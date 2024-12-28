# SPDX-License-Identifier: GPL-2.0-only

project(
    'mkinitcpio',
    version: run_command('tools/dist.sh', 'get-version', check: true).stdout().strip(),
    license: 'GPL-2.0-only',
    license_files: 'LICENSE',
    meson_version: '>=1.4.0',
    default_options: [
        'prefix=/usr/local',
        'sysconfdir=/etc',
    ]
)

meson.add_dist_script('tools/dist.sh', 'dist-version', meson.project_version())

project_source_root = meson.current_source_dir()
project_build_root = meson.current_build_dir()
prefixdir = get_option('prefix')
bindir = prefixdir / get_option('bindir')
libdir = prefixdir / get_option('libdir')
sysconfdir = prefixdir / get_option('sysconfdir')
mandir = prefixdir / get_option('mandir')
datadir = prefixdir / get_option('datadir')
bashcompletiondir = datadir / 'bash-completion' / 'completions'
zshcompletiondir = datadir / 'zsh' / 'site-functions'

initcpio_libdir = libdir / 'initcpio'
initcpio_sysconfdir = sysconfdir / 'initcpio'

want_systemd = get_option('systemd')
want_kernel_install = get_option('kernel_install')
want_alpm = get_option('alpm')
want_presets = get_option('presets')
want_docs = get_option('docs')
vconsole_conf = get_option('vconsole_conf')

conf_data = configuration_data({
    'VERSION': meson.project_version(),
    'BINDIR': bindir,
    'SYSCONFDIR': sysconfdir,
    'INITCPIO_LIBDIR': initcpio_libdir,
    'INITCPIO_SYSCONFDIR': initcpio_sysconfdir,
    'VCONSOLE_CONF': sysconfdir / vconsole_conf,
})

systemd = dependency('systemd', method: 'pkg-config', required: want_systemd)

if systemd.found()
    systemd_util_dir = systemd.get_variable('systemd_util_dir')
    systemd_system_unit_dir = systemd.get_variable('systemd_system_unit_dir')
    tmpfiles_dir = systemd.get_variable('tmpfiles_dir')

    udevd_dirs = [systemd_util_dir]
else
    tmpfiles_dir = libdir / 'tmpfiles.d'

    udevd_dirs = []
endif

udevd = find_program('systemd-udevd', 'udevd', dirs: udevd_dirs, required: true)
tmpfiles = find_program('systemd-tmpfiles', required: want_systemd)
shellcheck = find_program('shellcheck', required: false)

conf_data.set('UDEVD_PATH', udevd.full_path())
if want_systemd.enabled()
    conf_data.set('TMPFILES_PATH', tmpfiles.full_path())
else
    conf_data.set('TMPFILES_PATH', '')
endif

configure_file(
    input: 'mkinitcpio',
    output: 'mkinitcpio',
    configuration: conf_data,
    install_dir: bindir,
    install_mode: 'rwxr-xr-x',
)

configure_file(
    input: 'lsinitcpio',
    output: 'lsinitcpio',
    configuration: conf_data,
    install_dir: bindir,
    install_mode: 'rwxr-xr-x',
)

configure_file(
    input: 'mkinitcpio.conf',
    output: 'mkinitcpio.conf',
    configuration: conf_data,
    install_dir: sysconfdir,
)

configure_file(
    input: 'functions',
    output: 'functions',
    configuration: conf_data,
    install_dir: initcpio_libdir,
    install_mode: 'rwxr-xr-x',
)

init_files = [
    'init',
    'init_functions',
    'shutdown',
]

foreach f: init_files
    configure_file(
        input: f,
        output: f,
        configuration: conf_data,
        install_dir: initcpio_libdir,
    )
endforeach

empty_dirs = [
    initcpio_sysconfdir / 'hooks',
    initcpio_sysconfdir / 'install',
    initcpio_sysconfdir / 'post',
    sysconfdir / 'mkinitcpio.conf.d',
    sysconfdir / 'mkinitcpio.d',
    initcpio_libdir / 'post',
]

foreach dir: empty_dirs
    install_emptydir(dir)
endforeach

shellcheck_files = [
    'functions',
    'hooks/consolefont',
    'hooks/encrypt',
    'hooks/keymap',
    'hooks/memdisk',
    'hooks/resume',
    'hooks/shutdown',
    'hooks/sleep',
    'hooks/udev',
    'hooks/usr',
    'init',
    'init_functions',
    'install/acpi_override',
    'install/autodetect',
    'install/base',
    'install/block',
    'install/consolefont',
    'install/encrypt',
    'install/filesystems',
    'install/fsck',
    'install/hostdata',
    'install/keyboard',
    'install/keymap',
    'install/kms',
    'install/lvm2',
    'install/mdadm_udev',
    'install/memdisk',
    'install/microcode',
    'install/modconf',
    'install/resume',
    'install/sd-encrypt',
    'install/sd-encrypt-opensc',
    'install/sd-shutdown',
    'install/sd-vconsole',
    'install/shutdown',
    'install/sleep',
    'install/strip',
    'install/systemd',
    'install/udev',
    'install/usr',
    'lsinitcpio',
    'mkinitcpio',
    'shell/bash-completion',
    'shutdown',
    'test/cases/bash-completion.bats',
    'test/cases/extglob.bats',
    'test/cases/functions.bats',
    'test/cases/mkinitcpio.bats',
    'test/cases/parse_cmdline.bats',
    'test/cases/zsh-completion.bats',
    'test/helpers/common.bash',
]

if shellcheck.found()
    test(
        'shellcheck',
        shellcheck,
        args: ['-W', '99', '--color'] + shellcheck_files,
        env: {'LC_ALL': 'C.UTF-8'},
        workdir: project_source_root,
        verbose: true,
        is_parallel: true,
        timeout: 600,
        suite: 'shellcheck',
    )
endif

subdir('hooks')
subdir('install')
subdir('kernel-install')
subdir('libalpm')
subdir('man')
subdir('mkinitcpio.d')
subdir('shell')
subdir('systemd')
subdir('test')
subdir('tmpfiles')
subdir('udev')
