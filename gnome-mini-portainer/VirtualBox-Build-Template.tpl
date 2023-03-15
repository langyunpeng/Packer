Vagrant.configure("2") do |config|
  config.vm.define "source", autostart: false do |source|
		source.vm.box = "{{.SourceBox}}"
    config.ssh.insert_key = {{.InsertKey}}

    source.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
			vb.gui = false
      vb.memory = "8192"
      vb.cpus = 4
    end
  end
  
  config.vm.define "output" do |output|
		output.vm.box = "{{.BoxName}}"
		output.vm.box_url = "file://package.box"
		config.ssh.insert_key = {{.InsertKey}}
  end
  
  config.vm.synced_folder ".", "/vagrant", disabled: false
end
