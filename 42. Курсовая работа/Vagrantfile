# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :AppSrv => {
        :box_name => "centos/7",
        :ip_addr => '192.168.10.10'
  },
  :DBServer => {
        :box_name => "centos/7",
        :ip_addr => '192.168.10.11'
  },
  :MonSrv => {
        :box_name => "centos/7",
        :ip_addr => '192.168.10.12'
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          #box.vm.network "forwarded_port", guest: 3260, host: 3260+offset

          config.vm.synced_folder ".", "/vagrant", disabled: true

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "200"]
            # Подключаем дополнительные диски
            #vb.customize ['createhd', '--filename', second_disk, '--format', 'VDI', '--size', 5 * 1024]
            #vb.customize ['storageattach', :id, '--storagectl', 'IDE', '--port', 0, '--device', 1, '--type', 'hdd', '--medium', second_disk]
          end

          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
            yum install wget -y
          SHELL
          
          case boxname.to_s
          when "AppSrv"
            box.vm.provision "ansible" do |ansible|
              ansible.verbose = "vv"
              ansible.become = "true"
              ansible.playbook = "provision/role_nginx.yml"
              # ansible.playbook = "provision/role_php.yml"
            end
          when "DBServer"
            box.vm.provision "ansible" do |ansible|
              ansible.verbose = "vv"
              ansible.become = "true"
              # ansible.limit = "1"
              ansible.playbook = "provision/dbs_main.yml"
              # ansible.playbook = "provision/dbs_create_wpdb.yml"
            end
          end
      end
  end
end
