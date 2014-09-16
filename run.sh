#!/bin/bash

if [[ ! -e "$PUBLIC_KEY" ]]; then
    echo "[-] Missing public key"
    exit 1
elif [[ ! -e "$OUT" ]]; then
    echo "[-] Need to set OUT environment variable"
    exit 1
else
    export HOME=/home/$USER
    useradd -s /bin/bash -m -d $HOME -g root $USER
    mkdir -p -m 700 $HOME/.ssh
    cat $PUBLIC_KEY > $HOME/.ssh/authorized_keys
    chmod 600 $HOME/.ssh/authorized_keys
    sed -ri "s@#?AuthorizedKeysFile\s+.*@AuthorizedKeysFile $HOME/.ssh/authorized_keys@" /etc/ssh/sshd_config
    chown -R $USER:root $HOME/.ssh

    echo "[+] Created user $USER"

    if [[ ! -e "$IN" ]]; then
        echo "[+] Creating empty repository"
        export GIT_DIR=$HOME/repo.git
        mkdir -p $GIT_DIR
        chown -R $USER $GIT_DIR
        git init --bare --shared=0660
        touch $GIT_DIR/hooks/post-receive
        chmod +x $GIT_DIR/hooks/post-receive
(
cat <<POSTRECEIVE
#!/bin/bash

GIT_WORK_TREE="$OUT" git checkout -f master
POSTRECEIVE
) > $GIT_DIR/hooks/post-receive
    else
        echo "[+] Using existing repository"
        export GIT_DIR=$IN
    fi

    $(which sshd) -D -E /dev/stderr
fi