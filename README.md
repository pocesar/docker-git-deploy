Docker Git Deploy [![Docker Automated buil](https://img.shields.io/docker/automated/pocesar/docker-git-deploy.svg)](https://hub.docker.com/r/pocesar/docker-git-deploy/)
================

Dockerized Git deploy through SSH service, built on top of [official Ubuntu](https://registry.hub.docker.com/_/ubuntu/) trusty image. It uses git 'post-receive' hook and provides nice colored logs for each pushed commit.

Accepts an `IN`, `BRANCH_*`, `USER` and `PUBLIC_KEY` settings through environment variables, if the git history doesn't matter to you, pass only the `BRANCH_*` and `PUBLIC_KEY` settings, which aren't optional

This Dockerized image doesn't allow plain text logins, can only connect to it through the use of a public RSA key.

## Defaults

```
USER = git # The user used in the git push
PUBLIC_KEY = "" # Your mounted public key path inside the container
IN = "" # The folder that holds the git bare repo
BRANCH_* = "" # The folder that receives the git checkout depending on the name of the variable
# use BRANCH_MASTER="/out" for example, or BRANCH_TESTING="/testout"
```

## Setup

```bash
$ docker run -d \
    -p 1234:22 \
    --name deploy \
    -e PUBLIC_KEY="/id_rsa.pub" \
    -v ~/.ssh/id_rsa.pub:/id_rsa.pub \
    -e BRANCH_TRUSTY="/out" \
    -e BRANCH_MASTER="/out" \
    -v /var/www:/out \
    -e IN="/in" \
    pocesar/docker-git-deploy

c48f7b86594953012ca4731b1ec08b053ce5826d3f501ed579c660bec42d2c88
```

NOTE: You can use `-e PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"` as well and drop the `-v` part of the public key

## Deploy

```bash
git remote add upstream ssh://docker@yourhost:1234/in # or /home/git/repo.git by default
git commit -m "Behold!"
git push upstream master
```

## Get logs (with colors!)

```
$ docker logs deploy
[+] 2014-09-18T11:36:05Z: Using branches:
         - BRANCH_TRUSTY=/out
         - BRANCH_MASTER=/out

[+] 2014-09-18T11:36:05Z: Reading public key mount
[+] 2014-09-18T11:36:05Z: Created user docker
[+] 2014-09-18T11:36:05Z: Using existing path
Initialized empty shared Git repository in /in/
[+] 2014-09-18T11:36:05Z: Deploy using this git remote url: ssh://docker@host:port/in
Server listening on 0.0.0.0 port 22.
Server listening on :: port 22.
Accepted publickey for docker from 172.17.42.1 port 35341 ssh2: RSA 79:4f:46:33:1f:39:25:6d:0d:37:e1:e0:d2:42:5c:0e
[^] 2014-09-18T11:36:05Z: Updated sources on BRANCH_TRUSTY:/out
-------------
trusty a4f9d05 - Paulo Cesar, 27 hours ago: README
-------------
Received disconnect from 172.17.42.1: 11: disconnected by user
Accepted publickey for docker from 172.17.42.1 port 35344 ssh2: RSA 79:4f:46:33:1f:39:25:6d:0d:37:e1:e0:d2:42:5c:0e
[^] 2014-09-18T11:36:05Z: Updated sources on BRANCH_MASTER:/out
-------------
master a4f9d05 - Paulo Cesar, 27 hours ago: README
-------------
Received disconnect from 172.17.42.1: 11: disconnected by user
```

## Mods

You can inject your bash scripts into the `post-receive` hook by mounting your script to `-v /var/some/script.sh:/userscript`. It can be anything, like set folder / file permissions, execute `npm install`, `bower install` etc. and any type of language (if you install the needed binaries of course).

You can also use `echo "hello world" >> $MEM_LOG` to output stuff to the docker log from any of your scripts. Be aware that the user script will be called everytime there's a push.

The same goes for the setup script, in `-v /var/some/script.sh:/setup`, it will be called once the container is ran. Useful to install extra software you may need (like `ruby`, `node`, `jekyll`). Please note that those tools are ran inside the container, and you may only output or use the `BRANCH_*` environment variables to execute your commands. Eg.:

```bash
#!/bin/bash

# this is /setup

apt-get -y -qq install nodejs
wget http://example.com/something.js > "$BRANCH_MASTER/something.js"
echo "something.js downloaded" >> $MEM_LOG # goes to docker logs
```

```bash
#!/usr/bin/env node

/** this is /userscript
 * it receives the following arguments:
 * $1 = the branch name (as seen in git)
 * $2 = the refname, like ea9da19
 * $3 = the current path of the working dir
 *
 * all environment variables are available inside, including the IN, BRANCH_* and GIT
 */

var
    path = require('path'), fs = require('fs');

# process.argv[1] === branch
# process.argv[2] === gitref
# process.argv[3] === working tree

if (process.argv[1] === 'master') {
    fs.chmodSync(path.join(process.env.BRANCH_MASTER, 'cache'), '0774');
}
```
