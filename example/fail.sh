#!/bin/bash

path="$3"

echo "Reverting last commit in $path" >> $MEM_LOG

cd $IN

GIT_WORK_TREE="$path" git reset --hard HEAD~1
cmd="$USERSCRIPT $@"
"$cmd" &>/dev/null &disown
