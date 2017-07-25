#!/bin/bash

path="$3"

cd "$path" && \
rm -rf node_modules && \
npm install && npm-install-peers && \
tsc -p tsconfig.json
