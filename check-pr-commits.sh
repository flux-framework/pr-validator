#!/bin/bash
#############################################################################
#  Simple PR commit validator.
#
#  Exit with nonzero status if any PR commits (commits between the current
#   branch and origin/master do not validate, e.g. are themselves merge
#   commits, or have the word "fixup" or "squash" in the commit subect, etc.
#
#  Usage: check-pr-commits.sh [upstream ref]
#
set -e
set -o pipefail

HEAD="HEAD"
BASE=${1:-"origin/master"}

RESULT=0
ERRORS=()
WARNINGS=()

# ok, not ok unicode symbols:
OK='\u2714'
NOK='\u2718'
WARN='\u26A0'

#############################################################################
#  error/warning log and output functions:

color=t
loglevel="error"
if test -n "$color"; then
    color_fail='\e[1m\e[31m' # bold red
    color_pass='\e[1m\e[32m' # bold green
    color_warn='\e[1m\e[33m' # bold yellow
    color_reset='\e[0m'
else
    color_fail=''
    color_pass=''
    color_warn=''
    color_reset=''
fi
ok()      { printf "${color_pass}${OK}${color_reset}"; }
notok()   { printf "${color_fail}${NOK}${color_reset}"; }
warning() { printf "${color_warn}${WARN}${color_reset}"; }

log() {
    if test "$loglevel" = "error"; then
        ERRORS+=("${color_fail}$*${color_reset}")
    else
        WARNINGS+=("${color_warn}$*${color_reset}")
    fi
}

dump_errors() {
    printf "\nCommit message validation failed::\n"
    for line in "${ERRORS[@]}"; do
        printf " $line\n"
    done
}

dump_warnings() {
    if test ${#WARNINGS} -gt 0; then
        printf "\nCommit warnings::\n"
        for line in "${WARNINGS[@]}"; do
            printf " $line\n"
        done
    fi
}

#############################################################################
#  Tests


is_only_child() {
    return $(git rev-list --no-walk --count --merges "$@")
}

#  Return zero if commit is a merge commit (more than one parent)
is_merge_commit() {
    if ! is_only_child $1; then
        log "$1 appears to be a merge commit"
        return 0
    fi
    return 1
}

#  Return zero if commit appears to be labeled a fixup or squash commit
is_fixup_commit() {
    if git show -s --format=%s $1 | egrep -q 'fixup|squash'; then
        log "$1 appears to be a fixup/squash commit"
        return 0
    fi
    return 1
}

#  Return zero if commit subject length is > N characters
subject_length_exceeds() {
    local max=$1
    local sha=$2
    local len=$(git show -s --format=%s $sha | wc -c)
    if test $len -gt $max; then
        log "$sha has a subject longer than $max characters"
        return 0
    fi
    return 1
}

#  Return zero if commit body line length is > N characters
body_line_length_exceeds() {
    local max=$1
    local sha=$2
    local count=0
    local rc=1
    git show -s --format=%b | while read line; do
       if test ${#line} -gt $max; then
           log "${sha} commit body line ${count} ${#line} characters long"
           rc=0
       fi
    done
    return $rc
}

#  Add more test functions here...

#############################################################################
#  Check single commit:

check_commit() {
    sha=$1
    subject=$(git show -s --format=%s $sha)
    symbol="$(ok)"
    result=0

    # First check for errors:
    if is_fixup_commit $sha || \
       is_merge_commit $sha || \
       subject_length_exceeds 70 $sha || \
       body_line_length_exceeds 78 $sha; then
        symbol="$(notok)"
        result=1
    else
        # No errors, check warnings:
        loglevel="warn"
        if subject_length_exceeds 50 $sha || \
           body_line_length_exceeds 72 $sha; then
            symbol="$(warning)"
        fi
    fi
    printf " ${symbol} ${sha} ${subject}\n"
    return $result
}

#############################################################################
#  Main loop:

printf "Validating commits on current branch:\n"

COMMITS=$(git log --format=%h ${BASE}..${HEAD})
for sha in $COMMITS; do
    if ! check_commit $sha; then
        RESULT=1
    fi
done

[ $RESULT = 1 ] && dump_log

dump_warnings

exit $RESULT

# vi: ts=4 sw=4 expandtab
