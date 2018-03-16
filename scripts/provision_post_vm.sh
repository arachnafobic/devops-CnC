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

whoami > shared/dump.$1.whoami
pwd > shared/dump.$1.pwd
env > shared/dump.$1.env

if [[ $1 == "CnC" ]]
then

exe "Fetching Keyprints for known hosts" \
     sh -c '/usr/bin/ssh-keyscan -t rsa localhost               >  /root/.ssh/known_hosts && \
            /usr/bin/ssh-keyscan -t rsa vm-clinux               >> /root/.ssh/known_hosts && \
            /usr/bin/ssh-keyscan -t rsa vm-clinux.example.com   >> /root/.ssh/known_hosts && \
            /usr/bin/ssh-keyscan -t rsa vm-ubuntu               >> /root/.ssh/known_hosts && \
            /usr/bin/ssh-keyscan -t rsa vm-ubuntu.example.com   >> /root/.ssh/known_hosts && \
            mkdir -p /home/vagrant/.ssh && \
            chmod 700 /home/vagrant/.ssh && \
            cp /root/.ssh/known_hosts /home/vagrant/.ssh/known_hosts && \
            chown -R vagrant:vagrant /home/vagrant/.ssh/'

exe "Cloning devops-CnC-ansible into ~/ansible/" \
     sh -c 'cd /home/vagrant && \
            git clone https://github.com/arachnafobic/devops-CnC-ansible.git ansible && \
            chown -R vagrant:vagrant ansible/'

exe "Setting Keybased SSH for vm(s)" \
     sh -c 'mv -f shared/vm-*.id_rsa /home/vagrant/.ssh/ && \
            chmod 600 /home/vagrant/.ssh/vm-*.id_rsa && \
            chown vagrant:vagrant /home/vagrant/.ssh/vm-*.id_rsa'

diff shared/hosts ansible/inventories/hosts.vm/hosts 1>/dev/null 2>/dev/null
if [[ ! $? ]]
then
  exe "Copying new generated hosts inventory file to ansible" \
       sh -c 'cp -f shared/hosts ansible/inventories/hosts.vm/hosts'
fi

exe "Setting up git config" \
     sudo -H -u vagrant sh -c 'mkdir -p ~/.git/ && \
                               git config --global push.default matching && \
                               git config --global user.name "`cat ~/shared/git_user`" && \
                               git config --global user.email "`cat ~/shared/git_email`"'

source /opt/ansible/hacking/env-setup 1>/dev/null 2>&1

mkdir -p /home/vagrant/.log

cd /home/vagrant/ansible
# exe "Running initialize-vm playbook on vm-ubuntu" \
#      bash -c 'ansible-playbook -v -i inventories/hosts.vm playbooks/initialize-vms.yml 1>/home/vagrant/.log/ansible-vm.vm 2>&1'

exe "Running initialize-vm playbook on CnC" \
     bash -c 'ansible-playbook -v -i inventories/hosts.devops-CnC playbooks/initialize-vms.yml 1>/home/vagrant/.log/ansible-vm.cnc 2>&1'

exe "Running ansible setup playbook on CnC" \
     bash -c 'ansible-playbook -v -i inventories/hosts.devops-CnC playbooks/setup-cnc.yml 1>/home/vagrant/.log/ansible.cnc 2>&1'

chown -R vagrant:vagrant /opt/ansible/
chown -R vagrant:vagrant /home/vagrant/.log
fi
