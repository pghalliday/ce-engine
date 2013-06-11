# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # install chef solo on all machines
  config.omnibus.chef_version = "11.4.4"

  # enable berkshelf
  config.berkshelf.enabled = true

  config.vm.define "ce-engine" do |node|
    node.vm.hostname = "ce-engine"
    node.vm.network :private_network, ip: "33.33.33.50"
    node.vm.box = "ubuntu1204"
    node.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/opscode_ubuntu-12.04_provisionerless.box"

    node.vm.provider :virtualbox do |vb|
      # Give enough horsepower to build without taking all day.
      vb.customize [
        "modifyvm", :id,
        "--memory", "1024",
        "--cpus", "2",
      ]
    end

    node.vm.provision :chef_solo do |chef|
      chef.json = {
        "ce_engine" => {
          "destination" => "/vagrant",
          "user" => "vagrant"
        }
      }
      chef.run_list = [
        "recipe[ce-engine]"
      ]
    end
  end
end
