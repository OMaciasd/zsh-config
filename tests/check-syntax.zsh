#!/usr/bin/env zsh
set -eu
root=${0:A:h:h}
zsh -n "$root/config/prompt.zsh"
print "PASS: prompt syntax"
