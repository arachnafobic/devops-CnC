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

exe "Setting up swapfile" \
     sh -c 'dd if=/dev/zero of=/swap bs=1024 count=2097152 && \
            mkswap /swap && chown root. /swap && chmod 0600 /swap && swapon /swap && \
            sh -c "echo /swap swap swap defaults 0 0 >> /etc/fstab" && \
            sh -c "echo vm.swappiness = 0 >> /etc/sysctl.conf && sysctl -p"'

exe "Updating system" \
     sh -c 'export DEBIAN_FRONTEND=noninteractive && \
            aptitude update && \
            aptitude -y install git python-jinja2 python-setuptools whois && \
            aptitude -y safe-upgrade && \
            aptitude -y autoclean'

if [[ $1 == "CnC" ]]
then
  exe "Preparing ansible 2.3.x" \
       sh -c 'mkdir -p /opt && \
              cd /opt && \
              git clone --recursive -b v2.3.1.0-1 https://github.com/ansible/ansible.git ansible-2.3.x && \
              ln -s ansible-2.3.x ansible && \
              chown -R vagrant.vagrant /opt/ansible/ && \
              chown -R vagrant.vagrant /opt/ansible-2.3.x/ && \
              echo "source /opt/ansible/hacking/env-setup 1>/dev/null 2>&1" >> /home/vagrant/.profile'
fi
