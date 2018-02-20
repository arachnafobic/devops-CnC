required_plugins = %w(vagrant-vbguest vagrant-vbox-snapshot vagrant-triggers tamtam-vagrant-reload vagrant-hostmanager)

plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
if not plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  system "vagrant plugin install #{plugins_to_install.join(' ')}"
  exec "vagrant #{ARGV.join(' ')}"
end

base_cfg = {
  name:       'vm-ubuntu',
  release:    'xenial',
  host:       'vm-ubuntu.example.com',
  ip:         'dhcp',
  sshport:    '2000',
  memory:     '2048',
  shares:   {
    'shared' => '/home/vagrant/shared',
    'scripts' => '/home/vagrant/scripts',
  },
  forwards: {
      # 8080 => 80,
  },
  fwd_x:      false,
  gui:        false,
  sshagent:   true,
  defaultvm:  false,
}

# ALWAYS place CnC LAST so it can execute playbooks against the other vm(s) during "vagrant up" creation.
boxes = [
  {
    name:       'vm-ubuntu',
    release:    'xenial',
    host:       'vm-ubuntu.example.com',
    sshport:    '2120',
    memory:     '512',
    sshagent:   false,
  },
  {
    name:       'CnC',
    release:    'xenial',
    host:       'CnC.example.com',
    sshport:    '2020',
    memory:     '512',
    defaultvm:  true,
  },
]

Vagrant::Config.run('2') do |config|
  boxes.each do |box|
    cfg   = base_cfg.merge box
    name  = ENV['CURRENT_BOX'] = cfg[:name]

    # Turn virtualbox guestutil auto update/install off
    # We'll handle it during provisioning
    config.vbguest.auto_update = false

    # Enable HostManager Plugin
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = false
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = true
    config.hostmanager.include_offline = false

    config.vm.define name, primary: cfg[:defaultvm] do |config|

      # Set Box
      boxname = "#{cfg[:release]}64-cloud"
      config.vm.box = boxname
      config.vm.box_url = ["https://cloud-images.ubuntu.com/vagrant/#{cfg[:release]}/current/#{cfg[:release]}-server-cloudimg-amd64-vagrant-disk1.box",
                           "https://cloud-images.ubuntu.com/#{cfg[:release]}/current/#{cfg[:release]}-server-cloudimg-amd64-vagrant.box"]
      config.vm.box_check_update = true
      config.vm.hostname = cfg[:host]

      # Update /etc/hosts inside VMs
      cached_addresses = {}
      config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
        if cached_addresses[vm.name].nil?
          if hostname = (vm.ssh_info && vm.ssh_info[:host])
            vm.communicate.execute("/sbin/ifconfig | grep 'inet addr' | head -n 2 | tail -n 1 | egrep -o '[0-9\.]+' | head -n 1 2>&1") do |type, contents|
              cached_addresses[vm.name] = contents.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
            end
          end
        end
        cached_addresses[vm.name]
      end
      config.hostmanager.aliases = cfg[:name]

      # SSH Options
      config.ssh.forward_x11 = cfg[:fwd_x]
      config.ssh.forward_agent = cfg[:sshagent]

      # Virtual Box Options
      config.vm.provider :virtualbox do |vb|
        vb.gui = cfg[:gui]
        vb.customize ["modifyvm", :id, "--memory", cfg[:memory]] if cfg[:memory]
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_shared", "1"]
      end

      # Set Network
      if cfg[:ip] == 'dhcp'
        config.vm.network :private_network, type: cfg[:ip]
      elsif cfg[:ip]
        config.vm.network :private_network, ip: cfg[:ip]
      end

      # Disable default ssh forward and set our own
      config.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      config.vm.network :forwarded_port, guest: 22, host: cfg[:sshport], auto_correct: true

      # Set Custom Port Forwards
      cfg[:forwards].each do |k, v|
        config.vm.network :forwarded_port, guest: v, host: k
      end

      # Mount shares (create when missing)
      config.vm.synced_folder '.', '/vagrant', disabled: true
      cfg[:shares].each do |k,v|
        config.vm.synced_folder k, v, create: true
      end

      # Provisions, pre reboot, ON THE HOST
      config.vm.provision "trigger", :stdout => true do |trigger|
        trigger.fire do
          run "scripts/provision_pre_host.sh #{cfg[:name]}"
          run_remote "scripts/provision_pre_vm.sh #{cfg[:name]}"
        end
      end

      # Auto Reboot after Provisions only, first run usually.
      config.vm.provision :reload

      # Provisions, post reboot, ON THE HOST
      config.vm.provision "trigger", :stdout => true do |trigger|
        trigger.fire do
          run "scripts/provision_post_host.sh #{cfg[:name]}"
          run_remote "scripts/provision_post_vm.sh #{cfg[:name]}"
          run "scripts/provision_vbguest.sh #{cfg[:name]}"
        end
      end

      # Auto Reboot after Provisions only, first run usually.
      config.vm.provision :reload

    end
  end
end
