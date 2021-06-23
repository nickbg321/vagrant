Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.network "private_network", ip: "192.168.83.137"
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "forwarded_port", guest: 443, host: 443
  config.vm.network "forwarded_port", guest: 3306, host: 3306

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    v.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  config.vm.synced_folder "./", "/vagrant", id: "vagrant-root"

  config.vm.provision "shell", path: "./vagrant/provision.sh"
  config.vm.provision "shell", privileged: false, run: "always", inline: <<-SHELL
    mailcatcher
  SHELL
end
