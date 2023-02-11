#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later
# From: https://github.com/systemd/systemd/blob/main/tools/git-contrib.sh
set -eu

tag="$(git describe --abbrev=0 --match 'v[0-9]*')"
git log --pretty=tformat:%aN -s "${tag}.." |
    sed 's/ / /g; s/--/-/g; s/.*/\0,/' |
    sort -u | tr '\n' ' ' | sed -e "s/^/Contributions from: /g" -e "s/,\s*$/\n/g" | fold -w 72 -s |
    sed -e "s/^/        /g" -e "s/\s*$//g"
