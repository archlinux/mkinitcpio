# SPDX-License-Identifier: GPL-2.0-only

if not want_docs
    subdir_done()
endif

fs = import('fs')

manpages = [
    'lsinitcpio.1',
    'mkinitcpio.conf.5',
    'mkinitcpio.8',
]

asciidoctor = find_program('asciidoctor', required: false)
if asciidoctor.found()
else
    a2x = find_program('a2x', required: false)
endif

# support pregenerated (but still with @macros@) manpages
# and generating from adoc at configure-time
foreach page : manpages
    meson.add_dist_script('../tools/dist.sh', 'gen-doc', page + '.adoc')

    if fs.is_file(page)
        mp = configure_file(
            configuration: conf_data,
            input: page,
            output: page,
        )
    else
        adoc = configure_file(
            configuration: conf_data,
            input: page + '.adoc',
            output: page + '.adoc',
        )
        if asciidoctor.found()
            mp = configure_file(
                input: adoc,
                output: page,
                command: [asciidoctor, '-b', 'manpage', adoc],
            )
        elif a2x.found()
            mp = configure_file(
                input: adoc,
                output: page,
                command: [a2x, '-f', 'manpage', adoc],
            )
        endif
    endif

    install_man(mp)
endforeach
