CloudStack tutorial Clients and Tools
=====================================
 
These instructions aim to give an introduction to Apache CloudStack. Accessing a production cloud based on CloudStack, getting a feel for it, then using a few tools to provision and configure machines in the cloud. For a more complete guide see this [Little Book](https://github.com/runseb/cloudstack-books/blob/master/en/clients.markdown)
 
What we will do in this tutorial is:

0. Getting your feet wet with http://exoscale.ch
1. Using CloudMonkey
2. Discovering Apache libcloud
3. Using Vagrant boxes and deploying in the cloud
4. Using Ansible configuration management tool
 
Getting your feet wet with [exoscale.ch](http://exoscale.ch)
============================================================

Start an instance via the UI
----------------------------
 
1. Go to [exoscale.ch](http://exoscale.ch) and click on `free sign-up` in the Open Cloud section
2. Ask me for the voucher code, you will get an additional 15CHF
2. Browse the UI, identify the `security groups` and `keypairs` sections.
3. Create a rule in your default security group to allow inbound traffic on port 22 (ssh)
4. Create a keypair and store the private key on your machine
5. Start an instance
6. ssh to the instance

Find your API Keys and inspect the API calls
--------------------------------------------

7. Inspect the API requests with firebug or dev console of your choice
8. Find your API keys (account section)

Get wordpress installed on an instance
---------------------------------------

Open port 80 on the default security group.
Start an Ubuntu 12.04 instance and in the User-Data tab input:

    #!/bin/sh
    set -e -x

    apt-get --yes --quiet update
    apt-get --yes --quiet install git puppet-common

    #
    # Fetch puppet configuration from public git repository. 
    #

    mv /etc/puppet /etc/puppet.orig
    git clone https://github.com/retrack/exoscale-wordpress.git /etc/puppet
 
    #
    # Run puppet.
    #

    puppet apply /etc/puppet/manifests/init.pp

Now open your browser on port 80 of the IP of your instance and Voila !


CloudMonkey, an interactive shell to your cloud
===============================================

The exoscale cloud is based on CloudStack. It exposes the CloudStack native API. Let's use CloudMonkey, the ACS cli.
 
    pip install cloudmonkey
    cloudmonkey
 
The full documentation for cloudmonkey is on the [wiki](https://cwiki.apache.org/confluence/display/CLOUDSTACK/CloudStack+cloudmonkey+CLI)
 
    set port 443
    set protocol https
    set path /compute
    set host api.exoscale.ch
    set apikey <yourapikey>
    set secretkey <secretkey>
 
Explore the ACS native API with CloudMonkey and tab tab....

Tabular Output
--------------
The number of key/value pairs returned by the api calls can be large
resulting in a very long output. To enable easier viewing of the output,
a tabular formatting can be setup. You may enable tabular listing and
even choose set of column fields, this allows you to create your own
field using the filter param which takes in comma separated argument. If
argument has a space, put them under double quotes. The create table
will have the same sequence of field filters provided

To enable it, use the *set* function and create filters like so:

    > set display table
    > list zones filter=name,id
    count = 1
    zone:
    +--------+--------------------------------------+
    |  name  |                  id                  |
    +--------+--------------------------------------+
    | CH-GV2 | 1128bd56-b4d9-4ac6-a7b9-c715b187ce11 |
    +--------+--------------------------------------+
        
Starting a Virtual Machine instance with CloudMonkey
----------------------------------------------------
To start a virtual machine instance we will use the *deployvirtualmachine* call.

    cloudmonkey>deploy virtualmachine -h
    Creates and automatically starts a virtual machine based on a service offering, disk offering, and template.
    Required args: serviceofferingid templateid zoneid
    Args: account diskofferingid displayname domainid group hostid hypervisor ipaddress iptonetworklist isAsync keyboard keypair name networkids projectid securitygroupids securitygroupnames serviceofferingid size startvm templateid userdata zoneid

The required arguments are *serviceofferingid, templateid and zoneid*

In order to specify the template that we want to use, we can list all
available templates with the following call:

     > list templates filter=id,displaytext templatefilter=executable
    count = 36
    template:
    +--------------------------------------+------------------------------------------+
    |                  id                  |               displaytext                |
    +--------------------------------------+------------------------------------------+
    | 3235e860-2f00-416a-9fac-79a03679ffd8 | Windows Server 2012 R2 WINRM 100GB Disk  |
    | 20d4ebc3-8898-431c-939e-adbcf203acec |   Linux Ubuntu 13.10 64-bit 10 GB Disk   |
    | 70d31a38-c030-490b-bca9-b9383895ade7 |   Linux Ubuntu 13.10 64-bit 50 GB Disk   |
    | 4822b64b-418f-4d6b-b64e-1517bb862511 |  Linux Ubuntu 13.10 64-bit 100 GB Disk   |
    | 39bc3611-5aea-4c83-a29a-7455298241a7 |  Linux Ubuntu 13.10 64-bit 200 GB Disk   |
    ...<snipped>

Similarly to get the *serviceofferingid* you would do:

    > list serviceofferings filter=id,name
    count = 7
    serviceoffering:
    +--------------------------------------+-------------+
    |                  id                  |     name    |
    +--------------------------------------+-------------+
    | 71004023-bb72-4a97-b1e9-bc66dfce9470 |    Micro    |
    | b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8 |     Tiny    |
    | 21624abb-764e-4def-81d7-9fc54b5957fb |    Small    |
    | b6e9d1e8-89fc-4db3-aaa4-9b4c5b1d0844 |    Medium   |
    | c6f99499-7f59-4138-9427-a09db13af2bc |    Large    |
    | 350dc5ea-fe6d-42ba-b6c0-efb8b75617ad | Extra-large |
    | a216b0d1-370f-4e21-a0eb-3dfc6302b564 |     Huge    |
    +--------------------------------------+-------------+

Note that we can use the linux pipe as well as standard linux commands
within the interactive shell. Finally we would start an instance with
the following call:

    cloudmonkey>deploy virtualmachine templateid=20d4ebc3-8898-431c-939e-adbcf203acec zoneid=1128bd56-b4d9-4ac6-a7b9-c715b187ce11 serviceofferingid=71004023-bb72-4a97-b1e9-bc66dfce9470
    id = 5566c27c-e31c-438e-9d97-c5d5904453dc
    jobid = 334fbc33-c720-46ba-a710-182af31e76df

This is an asynchronous job, therefore it returns a `jobid`, you can query the state of this job with:

    > query asyncjobresult jobid=334fbc33-c720-46ba-a710-182af31e76df
    accountid = b8c0baab-18a1-44c0-ab67-e24049212925
    cmd = com.cloud.api.commands.DeployVMCmd
    created = 2014-03-05T13:40:18+0100
    jobid = 334fbc33-c720-46ba-a710-182af31e76df
    jobinstanceid = 5566c27c-e31c-438e-9d97-c5d5904453dc
    jobinstancetype = VirtualMachine
    jobprocstatus = 0
    jobresultcode = 0
    jobstatus = 0
    userid = 968f6b4e-b382-4802-afea-dd731d4cf9b9

Once the machine is started you can list it:

    > list virtualmachines filter=id,displayname
    count = 1
    virtualmachine:
    +--------------------------------------+--------------------------------------+
    |                  id                  |             displayname              |
    +--------------------------------------+--------------------------------------+
    | 5566c27c-e31c-438e-9d97-c5d5904453dc | 5566c27c-e31c-438e-9d97-c5d5904453dc |
    +--------------------------------------+--------------------------------------+

The instance would be stopped with:

    > stop virtualmachine id=5566c27c-e31c-438e-9d97-c5d5904453dc
    jobid = 391b4666-293c-442b-8a16-aeb64eef0246

    > list virtualmachines filter=id,displayname,state
    count = 1
    virtualmachine:
    +--------------------------------------+--------------------------------------+---------+
    |                  id                  |             displayname              |  state  |
    +--------------------------------------+--------------------------------------+---------+
    | 5566c27c-e31c-438e-9d97-c5d5904453dc | 5566c27c-e31c-438e-9d97-c5d5904453dc | Stopped |
    +--------------------------------------+--------------------------------------+---------+
        
The *ids* that you will use will differ from this example. Make sure you use the ones that corresponds to your CloudStack cloud.

Try to create a `sshkeypair` with `create sshkeypair`, a `securitygroup` with `create securitygroup` and add some rules to it.

With CloudMonkey all CloudStack APIs are available.

Apache libcloud
===============

Libcloud is a python module that abstracts the different APIs of most cloud providers. It offers a common API for the basic functionality of clouds list nodes,sizes,templates, create nodes etc...Libcloud can be used with CloudStack, OpenStack, Opennebula, GCE, AWS.

Check the CloudStack driver [documentation](https://libcloud.readthedocs.org/en/latest/compute/drivers/cloudstack.html)

Installation
------------

To install Libcloud refer to the libcloud [website](http://libcloud.apache.org). Or simply do:

    pip install apache-libcloud

Generic use of Libcloud with CloudStack
---------------------------------------

With libcloud installed, you can now open a Python interactive shell, create an instance of a CloudStack driver
and call the available methods via the libcloud API.

First you need to import the libcloud modules and create a CloudStack
driver.

    >>> from libcloud.compute.types import Provider
    >>> from libcloud.compute.providers import get_driver
    >>> Driver = get_driver(Provider.CLOUDSTACK)

Then, using your keys and endpoint, create a connection object. Note
that this is a local test and thus not secured. If you use a CloudStack
public cloud, make sure to use SSL properly (i.e `secure=True`). Replace the host and path with the ones of your public cloud. For exoscale use `host='http://api.exoscale.ch` and `path=/compute`

    >>> apikey='plgWJfZK4gyS3mlZLYq_u38zCm0bewzGUdP66mg'
    >>> secretkey='VDaACYb0LV9eNjeq1EhwJaw7FF3akA3KBQ'
    >>> host='http://localhost:8080'
    >>> path='/client/api'
    >>> conn=Driver(key=apikey,secret=secretkey,secure=False,host='localhost',port='8080',path=path)

With the connection object in hand, you now use the libcloud base api to
list such things as the templates (i.e images), the service offerings
(i.e sizes) and the zones (i.e locations)

    >>> conn.list_images()
    [<NodeImage: id=13ccff62-132b-4caf-b456-e8ef20cbff0e, name=tiny Linux, driver=CloudStack  ...>]
    >>> conn.list_sizes()
    [<NodeSize: id=ef2537ad-c70f-11e1-821b-0800277e749c, name=tinyOffering, ram=100 disk=0 bandwidth=0 price=0 driver=CloudStack ...>,
	<NodeSize: id=c66c2557-12a7-4b32-94f4-48837da3fa84, name=Small Instance, ram=512 disk=0 bandwidth=0 price=0 driver=CloudStack ...>,
	<NodeSize: id=3d8b82e5-d8e7-48d5-a554-cf853111bc50, name=Medium Instance, ram=1024 disk=0 bandwidth=0 price=0 driver=CloudStack ...>]
    >>> images=conn.list_images()
    >>> offerings=conn.list_sizes()

The `create_node` method will take an instance name, a template and an
instance type as arguments. It will return an instance of a
*CloudStackNode* that has additional extensions methods, such as
`ex_stop` and `ex_start`.

    >>> node=conn.create_node(name='toto',image=images[0],size=offerings[0])
    >>> help(node)
    >>> node.get_uuid()
    'b1aa381ba1de7f2d5048e248848993d5a900984f'
    >>> node.name
    u'toto'

libcloud with exoscale
----------------------

Libcloud also has an exoscale specific driver. For complete description see this recent [post](https://www.exoscale.ch/syslog/2014/01/27/licloud-guest-post/) from Tomaz Murauz the VP of Apache Libcloud.

To get you started quickly, save the following script in a .py file.

    #!/usr/bin/env python

    import sys
    import os

    from IPython.terminal.embed import InteractiveShellEmbed
    from libcloud.compute.types import Provider
    from libcloud.compute.providers import get_driver
    from libcloud.compute.deployment import ScriptDeployment
    from libcloud.compute.deployment import MultiStepDeployment

    apikey=os.getenv('EXOSCALE_API_KEY')
    secretkey=os.getenv('EXOSCALE_SECRET_KEY')
    Driver = get_driver(Provider.EXOSCALE)
    conn=Driver(key=apikey,secret=secretkey)

    print conn.list_locations()

    def listimages():
        for i in conn.list_images():
            print i.id, i.extra['displaytext']

    def listsizes():
        for i in conn.list_sizes():
            print i.id, i.name

    def getimage(id):
        return [i for i in conn.list_images() if i.id == id][0]

    def getsize(id):
        return [i for i in conn.list_sizes() if i.id == id][0]

    script=ScriptDeployment("/bin/date")
    image=getimage('2c8bede9-c3b6-4450-9985-7b715d8e58c5')
    size=getsize('71004023-bb72-4a97-b1e9-bc66dfce9470')
    msd = MultiStepDeployment([script])

    # directly open the shell
    shell = InteractiveShellEmbed(banner1="Hello from Libcloud Shell !!")
    shell()

Set your API keys properly and execute the script. You can now explore the libcloud API interactively, try to start a node, and also deploy a node. For instance type `list` and press the tab key.

Vagrant boxes
=============

Install Vagrant and create the exo boxes
----------------------------------------

[Vagrant](http://vagrantup.com) is a tool to create *lightweight, portable and reproducible development environments*. Specifically it allows you to use configuration management tools to configure a virtual machine locally (via virtualbox) and then deploy it *in the cloud* via Vagrant providers. 
In this next exercise we are going to install vagrant on our local machine and use Exoscale vagrant boxes to provision VM in the Cloud using configuration setup in Vagrant. For future reading check this [post](http://sebgoa.blogspot.co.uk/2013/12/veewee-vagrant-and-cloudstack.html)

First install [Vagrant](http://www.vagrantup.com/downloads.html) and then get the cloudstack plugin:

    vagrant plugin install vagrant-cloudstack

Then we are going to clone a small github [project](https://github.com/exoscale/vagrant-exoscale-boxes) from exoscale. This project is going to give us *vagrant boxes*, fake virtual machine images that refer to Exoscale templates available.

    git clone https://github.com/exoscale/vagrant-exoscale-boxes
    cd vagrant-exoscale-boxes

Edit the `config.py` script to specify your API keys, then run:

    python ./make-boxes.py

If you are familiar with Vagrant this will be straightforward, if not, you need to add a box to your local installation for instance:

    vagrant box add Linux-Ubuntu-13.10-64-bit-50-GB-Disk /path/or/url/to/boxes/Linux-Ubuntu-13.10-64-bit-50-GB-Disk.box

Initialize a `Vagrantfile` and start an instance
----------------------------------------------

Now you need to create a *Vagrantfile*. In the directory of you choice  for example `/tutorial` do:

    vagrant init

Then edit the `Vagrantfile` created to contain this:

    Vagrant.configure("2") do |config|
        config.vm.box = "Linux-Ubuntu-13.10-64-bit-50-GB-Disk"
        config.ssh.username = "root"
        config.ssh.private_key_path = "/Users/vagrant/.ssh/id_rsa.vagrant"

        config.vm.provider :cloudstack do |cloudstack, override|
            cloudstack.api_key = "AAAAAAAAAAAAAAAA-aaaaaaaaaaa"
            cloudstack.secret_key = "SSSSSSSSSSSSSSSS-ssssssssss"

            # Uncomment ONE of the following service offerings:
            cloudstack.service_offering_id = "71004023-bb72-4a97-b1e9-bc66dfce9470" # Micro - 512 MB
            #cloudstack.service_offering_id = "b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8" # Tiny - 1GB
            #cloudstack.service_offering_id = "21624abb-764e-4def-81d7-9fc54b5957fb" # Small - 2GB
            #cloudstack.service_offering_id = "b6e9d1e8-89fc-4db3-aaa4-9b4c5b1d0844" # Medium - 4GB
            #cloudstack.service_offering_id = "c6f99499-7f59-4138-9427-a09db13af2bc" # Large - 8GB
            #cloudstack.service_offering_id = "350dc5ea-fe6d-42ba-b6c0-efb8b75617ad" # Extra-large - 16GB
            #cloudstack.service_offering_id = "a216b0d1-370f-4e21-a0eb-3dfc6302b564" # Huge - 32GB

            cloudstack.keypair = "vagrant" # for SSH boxes the name of the public key pushed to the machine
        end
    end

Make sure to set your API keys and your keypair properly. Also edit the `config.vm.box` line to set the name of the box you actually added with `vagrant box add` and edit the `config.ssh.private_key_path` to point to the private key you got from exoscale. In this configuration the default security group will be used.

You are now ready to bring the box up:

    vagrant up --provider=cloudstack

Don't forget to use the `--provider=cloudstack` or the box won't come up. Check the exoscale dashboard to see the machine boot, try to ssh into the box.

Add provisioning steps
----------------------

Once you have successfully started a machine with vagrant, you are ready to specify a provisioning script. Create a `boostrap.sh` bash script in your working directory and make it do whatever your want.

Add this provisioning step in the `Vagrantfile` like so:

    # Test bootstrap script
    config.vm.provision :shell, :path => "bootstrap.sh"

Relaunch the machine with `vagrant up` or `vagrant reload --provision`. To stop a machine `vagrant destroy`

You are now ready to dig deeper into Vagrant provisioning. See the provisioner [documentation](http://docs.vagrantup.com/v2/provisioning/index.html) and pick your favorite configuration management tool. For example with [chef](http://www.getchef.com) you would specify a cookbook like so:

    config.vm.provision "chef_solo" do |chef|
        chef.add_recipe "mycookbook"
    end

Puppet example
---------------

For [Puppet](http://docs.vagrantup.com/v2/provisioning/puppet_apply.html) remember the script that we put in the Userdata of the very first example. We are going to use the same Puppet configuration but via Vagrant.

Edit the `Vagrantfile` to have:

    config.vm.provision "puppet" do |puppet|
        puppet.module_path = "modules"
    end

Vagrant will look for the manifest in the `manifests` directory and for the modules in the `modules` directory.
Now simply clone the repository that we used earlier:

    git clone https://github.com/retrack/exoscale-wordpress

You should now see the `modules` and `manifests` directory in the root of your working directory that contains the `Vagrantfile`.
Remove the shell provisioning step, make sure to use the Ubuntu 12.04 template id and start the instance like before:

    vagrant up --provider=cloudstack

Open your browser and get back to Wordpress ! Of course the whole idea of Vagrant is that you can test all of these provisioning steps on your local machines using VirtualBox. Once you are happy with your recipes you can then move to provision in the cloud. Check out [Packer](http://packer.io) a related project which you can use to generate images for your cloud.

Playing with multi-machines configuration
-----------------------------------------

Vagrant is also very interesting because you can start multiple machines at [once](http://docs.vagrantup.com/v2/multi-machine/index.html). Edit the `Vagrantfile` to add a `web` and a `db` machine. Add the cloudstack specific information and specify different bootstrap scripts.

    config.vm.define "web" do |web|
      web.vm.box = "tutorial"
    end

    config.vm.define "db" do |db|
      db.vm.box = "tutorial"
    end

You can control each machine separately `vagrant up web`, `vagrant up db` or all at once in parallel `vagrant up`

Let the fun begin. Pick your favorite configuration management tool, decide what you want to provision, setup your recipes and launch the instances.

Ansible
=======

Our last exercise for this tutorial will be an introduction to [Ansible](http://ansibleworks.com). Ansible is a new configuration management systems based on ssh communications with the instances and a no-server setup. It is easy to install and get [started](http://docs.ansible.com/intro.html). Of course it can be used in conjunction with Vagrant.

Install and remote execution
----------------------------

First install *ansible*:
    
    pip install ansible

Or get it via packages `yum install ansible`, `apt-get install ansible` if you have set the proper repositories.

If you kept the instances from the previous exercise running, create an *inventory* `inv` file with the IP addresses. Like so

   185.1.2.3
   185.3.4.5

Then run your first ansible command: `ping`:

    ansible all -i inv -m ping

You should see the following output:

    185.1.2.3 | success >> {
        "changed": false, 
        "ping": "pong"
    }

    185.3.4.5 | success >> {
        "changed": false, 
        "ping": "pong"
    }

And see how you can use Ansible as a remote execution framework:

    $ ansible all -i inv -a "/bin/echo hello"
    185.1.2.3 | success | rc=0 >>
    hello

    185.3.4.5 | success | rc=0 >>
    hello

Now check all the great Ansible [examples](https://github.com/ansible/ansible-examples), pick one, download it via github and try to configure your instances with `ansible-playbook`

Provisioning with Playbooks
----------------------------

Clone the `ansible-examples` outside your Vagrant project:

    cd ..
    git clone https://github.com/ansible/ansible-examples.git

Pick the one you want to try, go easy first :) Maybe wordpress or a lamp stack and copy it's content to a `ansible` directory within the root of the Vagrant project.

    cd ./tutorial
    mkdir ansible
    cd ansible
    cp -R ../../ansible-examples/wordpress-nginx/ .

Go back to the Vagrant project directory we have been working on and edit the `Vagrantfile`. Remove the Puppet provisioning or comment it out and add:

    # Ansible test
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/site.yml"
      ansible.verbose = "vvvv"
      ansible.host_key_checking = "false"
      ansible.sudo_user = "root"
    end

And start the instance once again

    vagrant up --provision=cloudstack

Watch the output from the Ansible provisioning and once finished access the wordpress application that was just configured.




