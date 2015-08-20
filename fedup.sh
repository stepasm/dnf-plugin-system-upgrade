#!/bin/bash
# wrapper script to rewrite fedup options for `dnf system-upgrade`
#
# Copyright (c) 2015 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Will Woods <wwoods@redhat.com>

warn() {
    echo "Warning: $@" >&2
}

error() {
    echo "Error: $@" >&2
    exit 1
}

cat >&2 <<'END_OF_MESSAGE'
NOTE: fedup has been replaced by `dnf system-upgrade`. Use that instead.
END_OF_MESSAGE

BASECMD="dnf system-upgrade"

dnf_cmd=($BASECMD)

while [ $# -gt 0 ]; do
    flag="${1%%=*}"
    case "$flag" in
        # pass through to DNF
        -h|--help|-v|--verbose|-d|--debug|-C|--cacheonly|--nogpgcheck)
            dnf_cmd+=("$1")
        ;;
        # pass through to DNF, with argument
        --enablerepo|--disablerepo)
            dnf_cmd+=("$1")
            [[ "$1" != *=* ]] && shift && dnf_cmd+=("$1")
        ;;
        # ignore deprecated args
        --skipbootloader|--skipkernel|--resetbootloader)
            warn "$1 is not used anymore. ignoring."
        ;;
        # ignore deprecated args and their arguments
        --instrepo*|--product)
            warn "$1 is not used anymore. ignoring."
            [[ "$1" != *=* ]] && shift
        ;;
        # silently ignore old debugging options
        --skippkgs|--logtraceback)
            : # do nothing
        ;;
        # removed options. these cause errors.
        --debuglog)
            error "Can't redirect DNF logs. Use DNF debug options instead."
        ;;
        --enableplugin|--disableplugin)
            error "Sorry, dnf doesn't support '$flag'"
        ;;
        --device|--iso|--add-install)
            error "Sorry, dnf system-upgrade doesn't support '$flag'"
        ;;
        --expire-cache)
            error "'$flag' removed. Use '$BASECMD download --refresh'."
        ;;
        --clean-metadata)
            error "'$flag' removed. Use 'dnf clean metadata --releasever=VER'."
        ;;
        # --network became --releasever, basically
        --network)
            newarg="${1/--network/--releasever}"
            dnf_cmd+=("download" "$newarg")
            [[ "$1" != *=* ]] && shift && dnf_cmd+=("$1")
        ;;
        # --clean is now the "clean" command
        --clean)
            dnf_cmd+=("clean")
        ;;
        # unknown argument
        *)
            error "unknown argument '$1'"
        ;;
    esac
    shift
done

echo Trying "'${dnf_cmd[@]}'"
exec "${dnf_cmd[@]}"