# CloudStack Installation

* * *

This book is aimed at CloudStack users who need to install CloudStack from the community provided packages. These instructions are valid on a Ubuntu 12.04 system, please adapt them if you are on a different operating system. In this book we will setup a management server and one Hypervisor with KVM. We will setup a `basic` networking zone.

1. Installation of the prerequisites
2. Setting up the management server
3. Setting up a KVM hypervisor
4. Configuring a Basic Zone

# Prerequisites

In this section we'll look at installing the dependencies you'll need for Apache CloudStack development.

First update and upgrade your system:

    apt-get update 
    apt-get upgrade
	
Install NTP to synchronize the clocks:

    apt-get install openntpd

Install `openjdk`. As we're using Linux, OpenJDK is our first choice. 

	apt-get install openjdk-6-jdk

Install `tomcat6`, note that the new version of tomcat on [Ubuntu](http://packages.ubuntu.com/precise/all/tomcat6) is the 6.0.35 version.

    apt-get install tomcat6

Next, we'll install MySQL if it's not already present on the system.

    apt-get install mysql-server

Remember to set the correct `mysql` password in the CloudStack properties file. Mysql should be running but you can check it's status with:

    service mysql status

## Optional

Developers wanting to build CloudStack from source will want to install the following additional packages. If you dont' want to build from source just jump to the next section.

Install `git` to later clone the CloudStack source code:

    apt-get install git

Install `Maven` to later build CloudStack
	
	apt-get install maven

This should have installed Maven 3.0, check the version number with `mvn --version`

A little bit of Python can be used (e.g simulator), install the Python package management tools:

    apt-get install python-pip python-setuptools

Finally install `mkisofs` with:
	
    apt-get install genisoimage
	
# Setting up the management server

## Add the community hosted packages repo

Packages are being hosted in a community repo. To get the packages, add the CloudStack repo to your list:

Edit `/etc/apt/sources.list.d/cloudstack.list` and add:

    deb http://cloudstack.apt-get.eu/ubuntu precise 4.1

Replace 4.1 with 4.2 once 4.2 is out

Add the public keys to the trusted keys:

    wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -

Update your local apt cache

    apt-get update

## Install the management server package
	
Grab the management server package	
	
    apt-get install cloudstack-management

Setup the database

    cloudstack-setup-databases cloud:<dbpassword>@localhost \
    --deploy-as=root:<password> \
    -e <encryption_type> \
    -m <management_server_key> \
    -k <database_key> \
    -i <management_server_ip>

Start the management server

    cloudstack-setup-management

You can check the status or restart the management server with:

	service cloudstack-management <status|restart>

You should now be able to login to the management server UI at `http://localhost:8080/client`. Replace `localhost` with the appropriate IP address if needed. At this stage you have the CloudStack management server running but no hypervisors and no storage configured.

## Prepare the Secondary storage and seed the SystemVM template

CloudStack has two types of storage: `Primary` and `Secondary`. The `Primary` storage is defined at the cluster level and avaialable on the hypervisors that make up a cluster. In this installation we will use local storage for `Primary` storage. The `Secondary` storage is shared zone wide and hosts the image templates and snapshots. In this installation we will use an NFS server running on the same node that we used to run the management server. In terms of networking we will setup a `Basic` zone with no VLANs, `Advanced` zones that use VLANs or `SDN` solutions for isolations of guest networks will be covered in another book. In our setup the management server has the address `192.168.38.100` and the hypervisor has the address `192.168.38.101`

Install NFS packages

    apt-get install nfs-kernel-server portmap

	mkdir -p /export/secondary
	chown nobody:nogroup /export/secondary
	
The hypervisors in your infrastructure as well as the secondary storage VM will mount this secondary storage. Edit `/etc/exports` in such a way that these nodes can mount the share. For instance:
	
	/export/secondary 192.168.38.*(rw,async,no_root_squash,no_subtree_check)

Then start the export

    exportfs -a
	
We now need to seed this secondary storage with `SystemVM` templates. SystemVMs are small appliances that run on one of the hypervisor of your infrastructure and help orchestrate the cloud. We have the `Secondary storage VM` which manages image placement and snapshots, the 'Proxy VM' which handles VNC connections to the instances and the 'Virtual Route` which provides network services. To seed the secondary storage with the system VM template on Ubuntu for a KVM hypervisor:

	/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary -u http://download.cloud.com/templates/acton/acton-systemvm-02062012.qcow2.bz2 -h kvm

Note that you will need at least 5GB of disk space on the secondary storage.
	
# Preparing a KVM Hypervisor

In this section we will setup an Ubuntu 12.04 KVM hypervisor. The `Secondary` storage setup in the previous section needs to be mounted on this node. Let's start by making this mount.

## Install the packages and mount the secondary storage

First install openntpd on this server as well as the nfs packages for the client

    apt-get install openntpd
    apt-get install nfs-common portmap

Then make the mount

    mkdir -p /mnt/export/secondary
    mount 192.168.38.100:/export/secondary /mnt/export/secondary
	
Check that the mount is successfull with the `df -h` or the `mount` command. Then try to create a file in the mounted directory `touch /mnt/export/secondary`. Verify that you can also edit the file from the management server.

Add the CloudStack repository as was done in the `Using Packages`. Install the CloudStack agent

    apt-get install cloudstack-agent

## Configuring libvirt

You will see that `libvirt` is a dependency of the CloudStack agent package. Once the agent is installed, configure libvirt.

Edit `/etc/libvirt/libvirt.conf` to include:

    listen_tls = 0
    listen_tcp = 1
    tcp_port = "16509"
    auth_tcp = "none"
    mdns_adv = 0
	
Edit `/etc/libvirt/qemu.conf` and uncomment:
    
	vnc_listen=0.0.0.0
	
In addition edit `/etc/init/libvirt-bin.conf` to modify the libvirt options like so:

    env libvirtd_opts="-d -l"

Then restart libvirt
	
    service libvirt-bin restart

Security Policies needs to be configure properly, check that `apparmor` is running with `dpkg --list 'apparmor'`, if it's not then you have nothing to do, if it is then enter the following commands:

    ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
    ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
    apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
    apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper 


## Network bridge setup

We are now going to setup the network bridges, these are used to give network connectivity to the instances that will run on this hypervisor. This configuration can change depending on the number of network interfaces you have, whether or not you use vlans etc. In our simple case, we only have one network interface on the hypervisor and no VLANs. In this setup, the bridges will be automatically configured when adding the hypervisor in the infrastructure description on the management server. You should not have anything to do.


## Firewall settings

If you are working on an isolated/safe network and doing a basic proof of concept, you might want to disable the firewall and skip this section. Check the status of the firewall with `ufw status` and if it is running simply disable it with `ufw disable`. Otherwise setup the firewall properly. For `libvirt` to work you need to open port 16509 and 49512-49216 to enable migration. You can skip those ports if you are not going to do any migraiton. Open port 5900:6100 for VNC sessions to your instances, open port 1798 for the management server communication and 22 so you can ssh to your hypervisor.

The default firewall under Ubuntu is UFW (Uncomplicated FireWall). To open the required ports, execute the following commands:

    ufw allow proto tcp from any to any port 22
    ufw allow proto tcp from any to any port 1798
    ufw allow proto tcp from any to any port 16509
    ufw allow proto tcp from any to any port 5900:6100
    ufw allow proto tcp from any to any port 49152:49216

By default the firewall on Ubuntu 12.04 is disabled. You will need to activate it with `ufw enable`.

Now that the management server, secondary storage and hypervisor are all setup, we can configure our infrastructure through the CloudStack dashboard running on the management server.

# Configuring a Basic Zone

With the management server running and a hypervisor setup, you are now ready to configure your first basic zone in CloudStack. Login to the management server UI `http://192.168.38.100:8080/client`. Replace the IP with the IP of your management server. Login with the username `admin` and the password `password`. You can be adventurous and click where you want or keep on following this guide. Click on the button that says `I have used CloudStack before, skip this guide` we are going to bypass the wizard. You will then see the admin view of the dashboard. Click on the `Infrastructure` tab on the left side. Cllick on the `View zones` icon and find and follow the `Add Zone` icon on the top right. You will then follow a series of windows where you have to enter information describing the zone.



Global settings: host, secstorage.use.internal.sites....


Once you are done entering the information, all the steps should have gone `green`, launch the zone. When the hosts was being added the bridge was setup properly on your hypervisor. Since we are using local storage on the hypervisor, we will need to go to the `Global setttings` tab and set that up. In the search icon (top right), enter `system`, you should see the setting `system.vm.use.local.storage`. Set it to true and restart the management server `service cloudstack-management restart`. At this stage CloudStack will start by trying to run the system VMs and you may enter your first troubleshooting issue. Especially if your hypervisor does not have much RAM see the trouble shooting section. If all goes well the systemVMs will start and you should be able to start adding templates and launch instances. On KVM your templates will need to be `qcow2` images with a `qcow2` file extension, you will also need to have this image on a web server that is reachable by your management server.
 
 
# TroubleShooting

## Secondary Storage SystemVM (SSVM)

You can ssh into the systemVM to check their network configuration and connectivity. To do this find the link local address of the secondary storage systemVM in the management server UI. Go to the Infrastructure tab, select `systemVM`, select `secondary storage VM`. You will find the link local address.

    ssh -i /root/.ssh/id_rsa.cloud -p 3922 root@169.254.x.x
	
Then run the SSVM health check script `/usr/local/cloud/systemvm/ssvm-check.sh`. By experience issues arise, with the NFS export not being set properly and ending up not moutned on the SSVM, or having bad privileges. A common issue is also network connectivity, the SSVM needs access to the public internet. To diagnose more you might want to have a look on the [wiki](https://cwiki.apache.org/confluence/display/CLOUDSTACK/SSVM,+templates,+Secondary+storage+troubleshooting)

Also check the logs in `var/log/cloud/systemvm.log` they can help you diagnose other issues such as the NFS secondary storage not mounting which will prevent you from downloading templates. The management server IP needs to be in the same network as the management network of the systemVM. You might want to check the UI, go in Global Settings and search for `host`, you will find a variable `host` which should be an IP reachable form the systemVM. If not edit it and restart the management server. This situation might arise if your management server has multiple interfaces on different networks.

If you are on a private network without public internet connectivity you will need to server your templates/isos from this private network (a.k.a management network), this can be done by putting the template/iso on the management server and using a simple `python -m SimpleHTTPServer 80`, then using the IP of the management server in the url for downloading the templates/iso.

## Unsufficient server capacity error

By default the systemVMs will start with a set memory allocation. The console proxy is set to use 1GB of RAM. In some testing scenarios this could be quite large. You can change this by modifying the database:

    mysql -u root
    mysql> use cloud;
	mysql> select * from service_offering;
    mysql> update service_offering set ram_size=256 where id=10;

Then restart the management server with `service cloudstack-management restart`

If instances don't start due to this issue, it may be that your hosts don't have enough RAM to start the instances or that the service offering that the service offering that you are using is too `big`. Try to create a service offering that requires less RAM and storage. Alternatively increase the RAM of your hypervisors.

Be also mindfull of disk offerings, by default they are created using a `shared` storage pool. In this deployment, the primary storage is using local storage and this may cause some issues. Either do not use any data disks when starting an instance or create a data disk offering which uses local storage.

## Other useful settings

If you need to purge instances quickly, edit the global settings `expunge.delay` and `expunge.interval` and restart the management server `service cloudstack-management restart`


# Upgrading from 4.1.1 to 4.2

While writing this tutorial CloudStack 4.2 came out, it seems appropriate to also go through the upgrade procedure. The official procedure is documented in the [release notes](http://cloudstack.apache.org/docs/en-US/Apache_CloudStack/4.2.0/html/Release_Notes/upgrade-instructions.html#upgrade-from-4.0-to-4.1) but here we focus on our setup: Ubuntu 12.04, KVM and upgrading from 4.1.1 to 4.2. Other upgrade paths are possible but the community recommends to stay close to the latest release. In the future expect upgrade paths only from the latest bug fix release to the next major release and between bug fix releases.

A summary of the overall procedure is as follows:
1. Stop the management server and the agent
2. Edit your repository to point to the 4.2 release and update the packages
3. Backup your management server database for safety
4. Restart the management server and the agent


# Conclusions

CloudStack is a mostly Java application running with Tomcat and Mysql. It consists of a management server and depending on the hypervisors being used, an agent installed on the hypervisor farm. To complete a Cloud infrastructure however you will also need some Zone wide storage a.k.a Secondary Storage and some Cluster wide storage a.k.a Primary storage. The choice of hypervisor, storage solution and type of Zone (i.e Basic vs. Advanced) will dictate how complex your installation can be. As a quick start, KVM+NFS on Ubuntu 12.04 and a Basic Zone was illustrated in this book.

If you've run into any problems with this, please ask on the cloudstack-dev [mailing list](/mailing-lists.html).