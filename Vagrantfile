required_plugins = %w(vagrant-vbguest vagrant-vbox-snapshot tamtam-vagrant-reload vagrant-hostmanager)

if Vagrant.plugins_enabled?
  plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  if not plugins_to_install.empty?
    puts "Installing plugins: #{plugins_to_install.join(' ')}"
    system "vagrant plugin install #{plugins_to_install.join(' ')} --local"
    exec "vagrant #{ARGV.join(' ')}"
  end
end

module LocalCommand
    class Config < Vagrant.plugin("2", :config)
        attr_accessor :command
    end

    class Plugin < Vagrant.plugin("2")
        name "local_shell"

        config(:local_shell, :provisioner) do
            Config
        end

        provisioner(:local_shell) do
            Provisioner
        end
    end

    class Provisioner < Vagrant.plugin("2", :provisioner)
        def provision
            result = system "#{config.command}"
        end
    end
end

base_cfg = {
  name:       'vm-xenial',
  os:         'ubuntu',
  release:    'xenial',
  host:       'vm-xenial.example.com',
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
  autostart:  true,
}

# ALWAYS place CnC LAST so it can execute playbooks against the other vm(s) during "vagrant up" creation.
boxes = [
  {
    name:       'vm-centos',
    os:         'centos',
    release:    'centos/7',
    host:       'vm-centos.example.com',
    ip:         '172.28.128.4',
    sshport:    '2320',
    memory:     '2048',
    sshagent:   false,
    autostart:  false,
  },
  {
    name:       'vm-xenial',
    release:    'xenial',
    host:       'vm-xenial.example.com',
    ip:         '172.28.128.6',
    sshport:    '2120',
    memory:     '2048',
    sshagent:   false,
    autostart:  false,
  },
  {
    name:       'vm-bionic',
    release:    'bionic',
    host:       'vm-bionic.example.com',
    ip:         '172.28.128.7',
    sshport:    '2420',
    memory:     '2048',
    sshagent:   false,
    autostart:  false,
  },
  {
    name:       'CnC',
    release:    'bionic',
    host:       'CnC-monitor.ictmaatwerk.com',
    ip:         '172.28.128.3',
    sshport:    '2020',
    memory:     '1024',
    defaultvm:  true,
  },
]

Vagrant::Config.run('2') do |config|
  boxes.each do |box|
    cfg   = base_cfg.merge box
    name  = ENV['CURRENT_BOX'] = cfg[:name]

    # Configure, but DISable HostManager Plugin, we'll run it as provisioner
    config.hostmanager.enabled = false
    config.hostmanager.manage_host = false
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = true
    config.hostmanager.include_offline = false

    config.vm.define name, primary: cfg[:defaultvm], autostart: cfg[:autostart] do |config|

      # Turn virtualbox guestutil auto update/install off
      # We'll handle it during provisioning, except for centos,
      # which doesn't come with any guestutils by default
      if cfg[:os] == 'centos'
        config.vbguest.auto_update = true
      else
        config.vbguest.auto_update = false
      end

      # Set Box
      if cfg[:os] == 'centos'
        boxname = "#{cfg[:release]}"
        config.vm.box = boxname
        config.vm.box_check_update = true
        config.vm.hostname = cfg[:host]
        config.vm.base_mac = ''
      else
        # ubuntu = default
        boxname = "#{cfg[:release]}64-cloud"
        config.vm.box = boxname
        config.vm.box_url = ["https://cloud-images.ubuntu.com/vagrant/#{cfg[:release]}/current/#{cfg[:release]}-server-cloudimg-amd64-vagrant-disk1.box",
                             "https://cloud-images.ubuntu.com/#{cfg[:release]}/current/#{cfg[:release]}-server-cloudimg-amd64-vagrant.box"]
        config.vm.box_check_update = true
        config.vm.hostname = cfg[:host]
      end

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
        vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4" ]
        vb.customize ["modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, "logs/console-#{cfg[:os]}-#{cfg[:name]}.log") ]
        if cfg[:os] == 'ubuntu'
          vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_shared", "1"]
        end
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

      # Update /etc/hosts inside VMs
      cached_addresses = {}
      config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
        if cached_addresses[vm.name].nil?
          if hostname = (vm.ssh_info && vm.ssh_info[:host])
            if cfg[:os] == 'centos'
              result = ""
              vm.communicate.execute("ip addr | grep 'eth1'") do |type, data|
                result << data if type == :stdout
              end
              (ip = /inet (\d+\.\d+\.\d+\.\d+)/.match(result)) && ip[1]
              cached_addresses[vm.name] = ip[1]
            else
              if cfg[:release] == 'bionic'
                vm.communicate.execute("/sbin/ifconfig | grep 'inet ' | head -n 2 | tail -n 1 | egrep -o '[0-9\.]+' | head -n 1 2>&1") do |type, contents|
                  cached_addresses[vm.name] = contents.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
                end
              else
                vm.communicate.execute("/sbin/ifconfig | grep 'inet addr' | head -n 2 | tail -n 1 | egrep -o '[0-9\.]+' | head -n 1 2>&1") do |type, contents|
                  cached_addresses[vm.name] = contents.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
                end
              end
            end
          end
        end
        cached_addresses[vm.name]
      end
      config.hostmanager.aliases = cfg[:name]

      # Provisions, pre reboot
      config.vm.provision :local_shell, command: "scripts/provision_pre_host.sh #{cfg[:name]}"
      config.vm.provision :shell, path: "scripts/provision_pre_vm.sh", args: "#{cfg[:name]}"
      config.vm.provision :shell, path: "scripts/bionic-fix.sh", args: "#{cfg[:name]}", run: "always"

      # Auto Reboot after Provisions only, first run usually.
      config.vm.provision :reload

      # Always update the /etc/hosts on the VMs between reloads and on up/create
      config.vm.provision :hostmanager, run: "always"

      # Provisions, more of them, post reboot
      config.vm.provision :local_shell, command: "scripts/provision_post_host.sh #{cfg[:name]}"
      config.vm.provision :shell, path: "scripts/provision_post_vm.sh", args: "#{cfg[:name]}"
      if cfg[:os] != 'centos'
        config.vm.provision :local_shell, command: "scripts/provision_vbguest.sh #{cfg[:name]}"
      end

      # Auto Reboot after all Provisions have run.
      config.vm.provision :reload

    end
  end
end
