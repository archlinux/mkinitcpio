# SPDX-License-Identifier: GPL-2.0-only

bats = find_program('bats', required: false)
kcov = find_program('kcov', required: false)

test_files = [
    'bash-completion',
    'extglob',
    'functions',
    'mkinitcpio',
    'parse_cmdline',
    'zsh-completion',
]

coverage_dirs = []

test_env = environment({
    'LC_ALL': 'C.UTF-8',
    'MESON_TEST': '1',
})

if not bats.found()
    subdir_done()
endif

foreach test: test_files
    test(
        test,
        bats,
        args: project_source_root / 'test/cases' / test + '.bats',
        env: test_env,
        workdir: project_build_root,
        protocol: 'tap',
        verbose: true,
        timeout: 600,
        suite: 'bats',
    )

    if kcov.found()
        test(
            'coverage-' + test,
            kcov,
            args: [
                '--include-path=.', '--exclude-path=test', '--collect-only',
                project_build_root / 'coverage-' + test,
                bats.full_path(), project_source_root / 'test/cases' / test + '.bats',
            ],
            env: test_env,
            workdir: project_build_root,
            verbose: true,
            timeout: 600,
            suite: 'coverage',
        )
        coverage_dirs += project_build_root / 'coverage-' + test
    endif
endforeach

# merge all coverage results after all other tests run
if kcov.found()
    test(
        'merge-coverage',
        kcov,
        args: [
            '--merge', project_build_root / 'coverage', coverage_dirs,
        ],
        workdir: project_build_root,
        verbose: true,
        is_parallel: false,
        priority: -1000,
        timeout: 600,
        suite: 'coverage',
    )
endif
