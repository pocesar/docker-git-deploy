#!/bin/bash

function initGit {
    mkdir -p -m 660 $GIT_DIR
    chown -R $USER:root $GIT_DIR
    git init --bare --shared=0660
}

FORMAT='%Y-%m-%dT%H:%M:%SZ'

function log {
    echo -e "\e[93m[+] $(date -u +$FORMAT): \e[32m$1\e[0m"
}

if [[ ! -e "$PUBLIC_KEY" ]]; then
    log "Missing public key"
    exit 1
elif [[ ! -e "$OUT" ]]; then
    log "Need to set OUT environment variable"
    exit 2
else
    export HOME=/home/$USER
    export MEM_LOG=/dev/shm/$USER

    touch $MEM_LOG
    chmod 0777 $MEM_LOG

    useradd -s /bin/bash -m -d $HOME -g root $USER
    mkdir -p -m 700 $HOME/.ssh
    cat $PUBLIC_KEY > $HOME/.ssh/authorized_keys
    chmod 600 $HOME/.ssh/authorized_keys
    sed -ri "s@#?AuthorizedKeysFile\s+.*@AuthorizedKeysFile $HOME/.ssh/authorized_keys@" /etc/ssh/sshd_config
    chown -R $USER:root $HOME/.ssh

    log "Created user $USER"

    if [ ${IN} ]; then
        log "Using existing path"
        export GIT_DIR=$IN
    else
        log "Creating empty repository"
        export GIT_DIR=$HOME/repo.git
    fi

    initGit

    if [[ $(cd $GIT_DIR && git rev-parse --is-inside-work-tree) ]]; then
        if [[ $(cd $GIT_DIR && git rev-parse --is-bare-repository) ]]; then
            touch $GIT_DIR/hooks/post-receive
            chmod +x $GIT_DIR/hooks/post-receive
(
cat <<POSTRECEIVE
#!/bin/bash

GIT_WORK_TREE="$OUT" git checkout -f master
echo -e "\e[93m[^] $(date -u +$FORMAT): \e[32mUpdated sources on $OUT\e[0m" >> $MEM_LOG
git log -1 --decorate --pretty=format:"%h - %an, %ar: %s" | xargs -I {} echo -e "-------------\n\e[32m{}\e[0m\n-------------" >> $MEM_LOG
POSTRECEIVE
) > $GIT_DIR/hooks/post-receive
        else
            log "Invalid git bare repo"
            exit 3
        fi
    else
        echo "[+] $NOW: Trying to re-init bare git repo"
        initGit
    fi

    log "Will deploy to $OUT. Deploy using this git remote url: ssh://$USER@host:port$GIT_DIR"

    tail -f $MEM_LOG & $(which sshd) -D -E $MEM_LOG
fi