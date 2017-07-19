#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt-get update
apt-get install curl -y -qq
curl -sL https://deb.nodesource.com/setup_8.x | bash
apt-get install nodejs -y -qq
node --version
npm --version
npm install node-gyp npm-install-peers typescript -g
node-gyp install
