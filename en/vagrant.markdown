Using Veewee and Vagrant in development cycle
=============================================

Automation is key to a reproducible, failure tolerant infrastructure. Cloud administrators should aim to automate all steps of building their infrastructure and be able to re-provision everything with a single click. This is possible through a combination of configuration management, monitoring and provisioning tools. To get started in created appliances that will be automatically configured and provisioned two tools stand out in the arsenal: Veewee and Vagrant.

Veewee
------

[Veewee](https://github.com/jedi4ever/veewee) is a tool to easily create appliances for different hypervisors. It fetches the .iso of the distribution you want and build the machine with a kickstart file. It integrates with providers like VirtualBox so that you can build these appliances on your local machine. It supports most commonly used OS templates. Coupled with virtual box it allows admins and devs to create reproducible base appliances. Getting started with veewee is a 10 minutes exericse. The README is great and there is also a very nice [post](http://cbednarski.com/articles/veewee/) that guides you through your first box building.

Most folks will have no issues cloning Veewee from github and building it, you will need ruby 1.9.2 or above. You can get it via `rvm` or your favorite ruby version manager.
    
	 git clone https://github.com/jedi4ever/veewee
	 gem install bundler
     bundle install
	 
Setting up an alias is handy at this point `alias veewee="bundle exec veewee"`. You will need a virtual machine provider (e.g VirtualBox, VMware Fusion, Parallels, KVM). I personnaly use VirtualBox but pick one and install it if you don't have it already. You will then be able to start using `veewee` on your local machine. Check the sub-commands available (for virtualbox):

    $ veewee vbox
    Commands:
      veewee vbox build [BOX_NAME]                     # Build box
      veewee vbox copy [BOX_NAME] [SRC] [DST]          # Copy a file to the VM
      veewee vbox define [BOX_NAME] [TEMPLATE]         # Define a new basebox starting from a template
      veewee vbox destroy [BOX_NAME]                   # Destroys the virtualmachine that was built
      veewee vbox export [BOX_NAME]                    # Exports the basebox to the vagrant format
      veewee vbox halt [BOX_NAME]                      # Activates a shutdown the virtualmachine
      veewee vbox help [COMMAND]                       # Describe subcommands or one specific subcommand
      veewee vbox list                                 # Lists all defined boxes
      veewee vbox ostypes                              # List the available Operating System types
      veewee vbox screenshot [BOX_NAME] [PNGFILENAME]  # Takes a screenshot of the box
      veewee vbox sendkeys [BOX_NAME] [SEQUENCE]       # Sends the key sequence (comma separated) to the box. E.g for testing the :boot_cmd_sequence
      veewee vbox ssh [BOX_NAME] [COMMAND]             # SSH to box
      veewee vbox templates                            # List the currently available templates
      veewee vbox undefine [BOX_NAME]                  # Removes the definition of a basebox 
      veewee vbox up [BOX_NAME]                        # Starts a Box
      veewee vbox validate [BOX_NAME]                  # Validates a box against vagrant compliancy rules
      veewee vbox winrm [BOX_NAME] [COMMAND]           # Execute command via winrm

    Options:
              [--debug]           # enable debugging
      -w, --workdir, [--cwd=CWD]  # Change the working directory. (The folder containing the definitions folder).
                              # Default: /Users/sebgoa/Documents/gitforks/veewee

Pick a template from the `templates` directory and `define` your first box:

    veewee vbox define myfirstbox CentOS-6.5-x86_64-minimal

You should see that a `defintions/` directory has been created, browse to it and inspect the `definition.rb` file. You might want to comment out some lines, like removing `chef` or `puppet`. If you don't change anything and build the box, you will then be able to `validate` the box with `veewee vbox validate myfirstbox`. To build the box simply do:

    veewee vbox build myfristbox

Everything should be successfull, and you should see a running VM in your virtual box UI. To export it for use with `Vagrant`, `veewee` provides an export mechanism (really a VBoxManage command): `veewee vbox export myfirstbox`. At the end of the export, a .box file should be present in your directory.
	
Vagrant
-------

Picking up from where we left with `veewee`, we can now add the box to [Vagrant](https://github.com/jedi4ever/veewee/blob/master/doc/vagrant.md) and customize it with shell scripts or much better, with Puppet recipes or Chef cookbooks. First let's add the box file to Vagrant:

    vagrant box add 'myfirstbox' '/path/to/box/myfirstbox.box'

Then in a directory of your choice, create the Vagrant "project":
 
    vagrant init 'myfirstbox'
	
This will create a `Vagrantfile` that we will later edit to customize the box. You can boot the machine with `vagrant up` and once it's up , you can ssh to it with `vagrant ssh`.

While `veewee` is used to create a base box with almost no [customization](https://github.com/jedi4ever/veewee/blob/master/doc/customize.md) (except potentially a chef and/or puppet client), `vagrant` is used to customize the box using the Vagrantfile. For example, to customize the `myfirstbox` that we just built, set the memory to 2 GB, add a host-only interface with IP 192.168.56.10, use the apache2 Chef cookbook and finally run a `boostrap.sh` script, we will have the following `Vagrantfile`:

    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

      # Every Vagrant virtual environment requires a box to build off of.
      config.vm.box = "myfirstbox"
      config.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--memory", 2048]
      end

      #host-only network setup
      config.vm.network "private_network", ip: "192.168.56.10"

      # Chef solo provisioning
      config.vm.provision "chef_solo" do |chef|
         chef.add_recipe "apache2"
      end

      #Test script to install CloudStack
      #config.vm.provision :shell, :path => "bootstrap.sh"
  
    end

The cookbook will be in a `cookbooks` directory and the boostrap script will be in the root directory of this vagrant definition. For more information, check the Vagrant [website](http://www.vagrantup.com) and experiment. 

Vagrant CloudStack
------------------

What is very interesting with Vagrant is that you can use various plugins to deploy machines on public clouds. There is a `vagrant-aws` plugin and of course a `vagrant-cloudstack` plugin. You can get the latest CloudStack plugin from [github](https://github.com/klarna/vagrant-cloudstack). You can install it directly with the `vagrant` command line:

    vagrant plugin install vagrant-cloudstack

Or if you are building it from source, clone the git repository, build the gem and install it in `vagrant`

    git clone https://github.com/klarna/vagrant-cloudstack.git
	gem build vagrant-cloudstack.gemspec
	gem install vagrant-cloudstack-0.1.0.gem
    vagrant plugin install /Users/sebgoa/Documents/gitforks/vagrant-cloudstack/vagrant-cloudstack-0.0.7.gem
	
The only drawback that I see is that one would want to upload his local box (created from the previous section) and use it. Instead one has to create `dummy boxes` that use existing templates available on the public cloud. This is easy to do, but creates a gap between local testing and production deployments. To build a dummy box simply create a `Vagrantfile` file and a `metadata.json` file like so:

    $ cat metadata.json 
    {
        "provider": "cloudstack"
    }
    $ cat Vagrantfile 
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    Vagrant.configure("2") do |config|
      config.vm.provider :cloudstack do |cs|
        cs.template_id = "a17b40d6-83e4-4f2a-9ef0-dce6af575789"
      end
    end

Where the `cs.template_id` is a uuid of a CloudStack template in your cloud. CloudStack users will know how to easily get those uuids with `CloudMonkey`. Then create a `box` file with `tar cvzf cloudstack.box ./metadata.json ./Vagrantfile`. Simply add the box in `Vagrant` with:

    vagrant box add ./cloudstack.box

You can now create a new `Vagrant` project:

    mkdir cloudtest
    cd cloudtest
	vagrant init
	
And edit the newly created `Vagrantfile` to use the `cloudstack` box. Add additional parameters like `ssh` configuration, if the box does not use the default from `Vagrant`, plus `service_offering_id` etc. Remember to use your own api and secret keys and change the name of the box to what you created. For example on [exoscale](http://www.exoscale.ch):

    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    # Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
    VAGRANTFILE_API_VERSION = "2"

    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

      # Every Vagrant virtual environment requires a box to build off of.
      config.vm.box = "cloudstack"

      config.vm.provider :cloudstack do |cs, override|
        cs.host = "api.exoscale.ch"
        cs.path = "/compute"
        cs.scheme = "https"
        cs.api_key = "PQogHs2sk_3..."
        cs.secret_key = "...NNRC5NR5cUjEg"
		cs.network_type = "Basic"

        cs.keypair = "exoscale"
        cs.service_offering_id = "71004023-bb72-4a97-b1e9-bc66dfce9470"
        cs.zone_id = "1128bd56-b4d9-4ac6-a7b9-c715b187ce11"

        override.ssh.username = "root" 
        override.ssh.private_key_path = "/path/to/private/key/id_rsa_example"
      end

      # Test bootstrap script
      config.vm.provision :shell, :path => "bootstrap.sh"

    end

The machine is brought up with:

    vagrant up --provider=cloudstack

The following example output will follow:

    $ vagrant up --provider=cloudstack
    Bringing machine 'default' up with 'cloudstack' provider...
    [default] Warning! The Cloudstack provider doesn't support any of the Vagrant
    high-level network configurations (`config.vm.network`). They
    will be silently ignored.
    [default] Launching an instance with the following settings...
    [default]  -- Service offering UUID: 71004023-bb72-4a97-b1e9-bc66dfce9470
    [default]  -- Template UUID: a17b40d6-83e4-4f2a-9ef0-dce6af575789
    [default]  -- Zone UUID: 1128bd56-b4d9-4ac6-a7b9-c715b187ce11
    [default]  -- Keypair: exoscale
    [default] Waiting for instance to become "ready"...
    [default] Waiting for SSH to become available...
    [default] Machine is booted and ready for use!
    [default] Rsyncing folder: /Users/sebgoa/Documents/exovagrant/ => /vagrant
    [default] Running provisioner: shell...
    [default] Running: /var/folders/76/sx82k6cd6cxbp7_djngd17f80000gn/T/vagrant-shell20131203-21441-1ipxq9e
    Tue Dec  3 14:25:49 CET 2013
    This works

Which is a perfect execution of my amazing bootstrap script:

    #!/usr/bin/env bash

    /bin/date
    echo "This works"

You can now start playing with Chef cookbooks or Puppet recipes and automate the configuration of your cloud instances, thanks to [Vagrant](http://vagrantup.com) and [CloudStack](http://cloudstack.apache.org).







