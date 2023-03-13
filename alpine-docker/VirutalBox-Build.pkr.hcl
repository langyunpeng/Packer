packer {
  required_plugins {
    vagrant  = {
      version = ">= 1.0.3"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

variables {
	#Give a name for this build as your wish
	build_for = "alpine-docker"
	
	#Give a name for vagrant folder, by default it is the name of VM in VirtualBox 
	#vagrant_newvm_dir = "vagrant"
	vagrant_newvm_dir = "docker"

	
	#The source box which this build based on
	base_box = "generic/alpine312"

	#The name of generated box which will be added to vagrant box after the build
	box_name = "alpine-docker"

	
	#------------------------------
	
	#No need change below pre-set values
	build_working_dir = "working"
	

	#The vagrant file used during the build
	build_template = "VirtualBox-Build-Template.tpl"

	#The Vagrant file which will be built into new box as default
	#The values in it could be overridden by values in provided VagrantFile in the folder
	#For example you can give a name for the VM in VirtualBox
	#ENSURE the name of VM is NOT defined in the default file
	#In case another build based on the box, a name will result in SSH config failure during vagrant up
	output_vagrantfile = "VirtualBox-NestVM-Vagrantfile"

}

source "vagrant" "s1" {
  communicator = "ssh"
  
  source_path = "${var.base_box}"

  provider = "virtualbox"
  add_force = false

  output_dir = "${var.build_working_dir}"
  box_name = "${var.box_name}"

  template = "${var.build_template}"
  output_vagrantfile = "${var.output_vagrantfile}"
}


build {
  name = "${var.build_for}"
  
  sources = ["source.vagrant.s1"]


	###########Install Docker################################
    provisioner "shell" {
    pause_before = "3s"
    inline = [
							"sudo apk update",
    					"sudo apk add docker docker-compose",
    					
    					"sudo rc-update add docker boot",
    					
    					"sudo addgroup vagrant docker",
      				"sudo service docker start"
             ]
  }
  ###########Install Docker################################


	###########Enable Portainer################################
  provisioner "shell" {
    inline = [
							"sudo docker pull portainer/portainer-ce:latest",
    					"sudo docker volume create portainer_data",
    					"sudo docker run -d -p 8000:8000 -p 9000:9000 --name=portainer-1 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce"
             ]
  }
  ###########Enable Portainer################################



	###########Add new box to Vagrant & Init new VM############
	#Go to the generated "vagrant" - as
	post-processor "shell-local" {
	  inline = ["vagrant box add --force ${var.box_name} .\\${var.build_working_dir}\\package.box",
	  					"mkdir ${var.vagrant_newvm_dir}",
	  					"cd ${var.vagrant_newvm_dir}",
	  					"vagrant init ${var.box_name}",
	  					"copy /Y ..\\${var.output_vagrantfile} Vagrantfile.default-in-box"
	  					]
	}
	###########Add new box to Vagrant & Init new VM############

}
