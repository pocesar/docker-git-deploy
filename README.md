Docker Git Deploy
================

Dockerized Git deploy through SSH service, built on top of [official Ubuntu](https://registry.hub.docker.com/_/ubuntu/) trusty image.

Accepts an `IN`, `OUT`, `USER` and `PUBLIC_KEY` settings, if the git history doesn't matter to you, pass only the `OUT` and `PUBLIC_KEY` settings

Doesn't allow user logins, only public keys.

## Defaults

```
USER = git # The user used in the git push
PUBLIC_KEY = "" # Your mounted public key path inside the container
IN = "" # The folder that holds the git bare repo
OUT = "" # The folder that receives the git checkout
```

## Setup

```bash
$ docker run -d -p 1234:22 \
    --name deploy \
    -e PUBLIC_KEY="/id_dsa.pub" \
    -v ~/.ssh/id_dsa.pub:/id_dsa.pub \
    -e OUT="/repo" \
    -v  /var/www:/repo \
    pocesar/docker-git-deploy
c48f7b86594953012ca4731b1ec08b053ce5826d3f501ed579c660bec42d2c88
```

## Deploy

```bash
git remote add upstream ssh://docker@yourhost:1234/~/repo.git # or /home/docker/repo.git
git commit -m "Behold!"
git push upstream
```

## Get logs (with colors!)

```
$ docker logs deploy
[+] 2014-09-17T08:35:03Z: Created user docker
[+] 2014-09-17T08:35:03Z: Using existing path
Initialized empty shared Git repository in /in/
[+] 2014-09-17T08:35:03Z: Will deploy to /out. Deploy using this git remote url: ssh://docker@host:port/in
Server listening on 0.0.0.0 port 22.
Server listening on :: port 22.
Accepted publickey for docker from 172.17.42.1 port 45608 ssh2: RSA 79:4f:46:33:1f:39:25:6d:0d:37:e1:e0:d2:42:5c:0e
[^] 2014-09-17T08:35:03Z: Updated sources on /out
-------------
51da9c1 - Paulo Cesar, 24 hours ago: need to fix permissions
-------------
Received disconnect from 172.17.42.1: 11: disconnected by user
```

