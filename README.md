Docker Git Deploy
================

Dockerized Git deploy through SSH service, built on top of [official Ubuntu](https://registry.hub.docker.com/_/ubuntu/) trusty image.

Accepts an `IN`, `OUT`, `USER` and `PUBLIC_KEY` settings, if the git history doesn't matter to you, pass only the `OUT` and `PUBLIC_KEY` settings

Doesn't allow user logins, only public keys.

## Defaults

```
USER = git
PUBLIC_KEY = ""
IN = ""
OUT = ""
```

## Setup

```bash
$ docker run -p 1234:22 -d --name deploy -e OUT="/repo" -e PUBLIC_KEY="/id_dsa.pub" -v ~/.ssh/id_dsa.pub:/id_dsa.pub -v  /var/www:/repo pocesar/docker-git-deploy
c48f7b86594953012ca4731b1ec08b053ce5826d3f501ed579c660bec42d2c88

$ docker logs deploy
[+] Created user git
Server listening on 0.0.0.0 port 22.
Server listening on :: port 22.
Accepted publickey for docker from 172.17.42.1 port 53228 ssh2: DSA 15:44:0c:ab:a3:b4:49:30:1c:24:3a:76:28:11:1b:e8
Received disconnect from 172.17.42.1: 11: disconnected by user
```

## Deploy

```bash
git remote add upstream ssh://docker@yourhost:1234/~/repo.git # or /home/docker/repo.git
git commit -m "Behold!"
git push upstream
```