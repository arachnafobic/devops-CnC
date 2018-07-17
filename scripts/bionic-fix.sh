#!/usr/bin/env bash

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

# Detect distro and version used.
DISTRO=`cat /etc/os-release | grep ^NAME= | awk -F'=' '{print $2}' | awk -F '"' '{print $2}'`
VERSION=`cat /etc/os-release | grep ^VERSION_ID= | awk -F'=' '{print $2}' | awk -F '"' '{print $2}'`

if [[ $DISTRO == "Ubuntu" ]] && [[ $VERSION == "18.04" ]]
then
  exe "Fixing boottime for Ubuntu Bionic" \
       sh -c 'echo "            optional: yes" >> /etc/netplan/50-cloud-init.yaml && \
              echo "      optional: yes" >> /etc/netplan/50-vagrant.yaml && \
              netplan apply'
fi
