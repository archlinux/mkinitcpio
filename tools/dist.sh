#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only

case "$1" in
    get-version)
        git -C "$MESON_SOURCE_ROOT" describe --abbrev=7 | sed 's/-/./g;s/^v//;'
        ;;
    dist-version)
        $MESONREWRITE --sourcedir="$MESON_PROJECT_DIST_ROOT" kwargs set project / version "$2"
        ;;
    gen-doc)
        if command -v asciidoctor &>/dev/null; then
            asciidoctor -b manpage "${MESON_PROJECT_DIST_ROOT}/man/$2"
        else
            a2x -f manpages "${MESON_PROJECT_DIST_ROOT}/man/$2"
        fi
        ;;
    *)
        exit 1
        ;;
esac
