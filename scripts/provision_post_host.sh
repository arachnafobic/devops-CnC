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

  [ ! -e shared/hosts ] || rm -f shared/hosts; touch shared/hosts

  find .vagrant/machines/ -name private_key |while read fname; do
    KEY=$fname
    MACHINE=${fname%/*}
    MACHINE=${MACHINE%/*}
    MACHINE=${MACHINE#.vagrant/machines/}

    if [[ $MACHINE != "CnC" ]]
    then
      [ ! -e $KEY ] || cp $KEY shared/$MACHINE.id_rsa
      echo -e "$MACHINE\t\tansible_host=$MACHINE\tansible_port=22\tansible_user=vagrant\tansible_ssh_private_key_file=/home/vagrant/.ssh/$MACHINE.id_rsa" >> shared/hosts
    fi
  done
fi


# vm-ubuntu        ansible_host=vm-ubuntu ansible_port=22 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/vm-ubuntu.id_rsa

