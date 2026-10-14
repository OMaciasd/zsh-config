#!/usr/bin/env zsh
set -eu
root=${0:A:h:h}
for file in "$root"/config/*.zsh "$root"/tests/*.zsh; do
    zsh -n "$file"
done
print "PASS: zsh syntax"
