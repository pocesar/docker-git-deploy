#!/bin/bash

path="$3"
cmd="$0 $@ retry"
retry="$4"

revert() {
  cd $IN
  if [[ -z "$retry"  ]]; then
    # simple revert in case of failure
    report = "Reverting in $path"
    echo "$report"

    GIT_WORK_TREE="$path" git reset --soft HEAD~1
    "$cmd" &>/dev/null &disown
    exit 0
  else
    exit 1
  fi
}

( cd "$path" && \
  rm -rf node_modules && \
  npm install && npm-install-peers && \
  tsc -p base.json ) || revert
