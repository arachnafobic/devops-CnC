#!/usr/bin/env bash

# rsync here if needed
# example:
# rsync -e 'ssh -F .ssh-config.$1 -o StrictHostKeyChecking=no' -av --delete folder/ $1:folder/

exe () {
    # MESSAGE_PREFIX="\b\b\b\b\b\b\b\b\b\b"
    MESSAGE_PREFIX=""
    echo -e "$MESSAGE_PREFIX Execute: $1"
    LOOP=0
    while true;
    do
        # if ! [ $LOOP == 0 ]; then echo -e "$MESSAGE_PREFIX ...     "; fi;
        sleep 3;
        LOOP=$((LOOP+1))
    done & ERROR=$("${@:2}" 2>&1)
    status=$?
    kill $!; trap 'kill $!' SIGTERM

    if [ $status -ne 0 ];
    then
        echo -e "$MESSAGE_PREFIX ✖ Error" >&2
        echo -e "$ERROR" >&2
    else
        echo -e "$MESSAGE_PREFIX ✔ Success"
    fi
    return $status
}

if [[ $1 == "CnC" ]]
then
  # This should be a dynamic loop using find, eventually
  [ ! -e .vagrant/machines/vm-ubuntu/virtualbox/private_key ] ||  cp .vagrant/machines/vm-ubuntu/virtualbox/private_key shared/vm-ubuntu.id_rsa
  [ ! -e .vagrant/machines/vm-clinux/virtualbox/private_key ] ||  cp .vagrant/machines/vm-clinux/virtualbox/private_key shared/vm-clinux.id_rsa
fi
