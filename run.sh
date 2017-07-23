#!/bin/bash

initGit() {
    mkdir -p -m 660 $GIT_DIR
    chown -R $USER:root $GIT_DIR
    git init --bare --shared=0660
    [[ -z $(git config --get receive.denyNonFastForwards) ]] && (git config --add receive.denyNonFastForwards false)
    [[ -z $(git config --get receive.denyCurrentBranch) ]] && (git config --add receive.denyCurrentBranch ignore)
}

FORMAT='%Y-%m-%dT%H:%M:%SZ'

log() {
    echo -e "\e[93m[+] $(date -u +$FORMAT): \e[32m$1\e[0m"
}

wideenv() {
    # no duplicated env vars
    [ $(cat /etc/environment | grep "$1" -c) == "0" ] && ( echo "$1=$2" >> /etc/environment )
}

MEM_LOG=/dev/shm/$USER
wideenv MEM_LOG "$MEM_LOG"
touch $MEM_LOG
chmod 0777 $MEM_LOG

branches=$(env | grep BRANCH_)

[ $(echo $branches | grep "BRANCH_" -c) != "0" ] || ( echo "Must set a BRANCH variable (at least BRANCH_MASTER)" && exit 1 )
echo "$branches" >> /etc/environment
log "Using branches: \n\e[36m$(echo "$branches" | sed -e 's/^/\t - \0/g' )\n"

if [[ -e "/setup" ]]; then
    chmod +x /setup
    log "Executing setup script"
    /setup
    chmod -x /setup
fi

if [[ -e "/userscript" ]]; then
    if [[ ! -d "/userscript" ]]; then
        USERSCRIPT=/userscript
        log "Using $USERSCRIPT"
        chmod +x /userscript
    else
        log "Skipping /userscript because its a folder"
    fi
fi

wideenv IN "$IN"
wideenv USERSCRIPT "$USERSCRIPT"

export HOME=/home/$USER
wideenv HOME "$HOME"

useradd -s /bin/bash -m -d $HOME -g root $USER
mkdir -p -m 700 $HOME/.ssh

if [[ -e "$PUBLIC_KEY" ]]; then
    log "Reading public key mount"
    cat $PUBLIC_KEY >> $HOME/.ssh/authorized_keys
else
    log "Appending raw key"
    echo $PUBLIC_KEY >> $HOME/.ssh/authorized_keys
fi

unset PUBLIC_KEY

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

wideenv GIT_DIR "$GIT_DIR"

initGit

if [[ $(cd $GIT_DIR && git rev-parse --is-inside-work-tree) ]]
then
    if [[ $(cd $GIT_DIR && git rev-parse --is-bare-repository) ]]
    then
        touch $GIT_DIR/hooks/post-receive
        chmod +x $GIT_DIR/hooks/post-receive
(
cat <<POSTRECEIVE
#!/bin/bash

while read oldrev newrev refname
do
    branch=\$(git rev-parse --symbolic --abbrev-ref \$refname)
    loc="BRANCH_\$(echo "\${branch^^}")"
    path=\${!loc}

    if [[ -d \$path ]]
    then
        GIT_WORK_TREE="\$path" git checkout -f \$branch
        echo -e "\e[93m[^] $(date -u +$FORMAT): \e[32mUpdated sources on \$loc:\$path\e[0m" >> \$MEM_LOG
        git log -1 --pretty=format:"%h - %an, %ar: %s" | xargs -I {} echo -e "-------------\n\e[35m\$branch\e[0m \e[32m{}\e[0m\n-------------" >> \$MEM_LOG

        if [ \${USERSCRIPT} ]
        then
            \$USERSCRIPT \$branch \$refname \$path
        fi
    else
        echo -e "\e[93m[^] $(date -u +$FORMAT): \e[32mIgnoring push to \$branch as it isnt defined or not a folder\e[0m" >> \$MEM_LOG
    fi
done
POSTRECEIVE
) > $GIT_DIR/hooks/post-receive

    else
        log "Invalid git bare repo"
        exit 3
    fi
fi

log "Deploy using this git remote url: ssh://$USER@host:port$GIT_DIR"

tail -f $MEM_LOG & $(which sshd) -D -E $MEM_LOG

