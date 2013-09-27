* CloudStack Installation

This book is aimed at CloudStack users who need to install CloudStack from the community provided packages. These instructions are valid on a Ubuntu 12.04 system, please adapt them if you are on a different operating system. In this book we will setup a management server and one Hypervisor with KVM. We will setup a `basic` networking zone.

1. Installation of the prerequisites
2. Setting up the management server
2. Setting up a KVM hypervisor

* Prerequisites

In this section we'll look at installing the dependencies you'll need for Apache CloudStack development.

First update and upgrade your system:

    apt-get update 
    apt-get upgrade
	
Install NTP to synchronize thc clocks:

    apt-get install openntpd

Install `openjdk`. As we're using Linux, OpenJDK is our first choice. 

	apt-get install openjdk-6-jdk

Install `tomcat6`, note that the new version of tomcat on [Ubuntu](http://packages.ubuntu.com/precise/all/tomcat6) is the 6.0.35 version.

    apt-get install tomcat6

Next, we'll install MySQL if it's not already present on the system.

    apt-get install mysql-server

Remember to set the correct `mysql` password in the CloudStack properties file. Mysql should be running but you can check it's status with:

    service mysql status

** Optional

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
	
* Setting up the management server

** Add the community hosted packages repo

Packages are being hosted in a community repo. To get the packages, add the CloudStack repo to your list:

Edit `/etc/apt/sources.list.d/cloudstack.list` and add:

    deb http://cloudstack.apt-get.eu/ubuntu precise 4.1

Replace 4.1 with 4.2 once 4.2 is out

Add the public keys to the trusted keys:

    wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -

Update your local apt cache

    apt-get update

** Install the management server package
	
    apt-get install cloudstack-management

You can check the status or restart the management server with:

	service cloudstack-management <status|restart>

You should now be able to login to the management server UI at `http://localhost:8080/client`. Replace `localhost` with the appropriate IP address if needed. At this stage you have the CloudStack management server running but no hypervisors and no storage configured.

** Prepare the Secondary storage and seed the SystemVM template

CloudStack has two types of storage: `Primary` and `Secondary`. The `Primary` storage is defined at the cluster level and avaialable on the hypervisors that make up a cluster. In this installation we will use local storage for `Primary` storage. The `Secondary` storage is shared zone wide and hosts the image templates and snapshots. In this installation we will use an NFS server running on the same node that we used to run the management server. In terms of networking we will setup a `Basic` zone with no VLANs, `Advanced` zones that use VLANs or `SDN` solutions for isolations of guest networks will be covered in another book. In our setup the management server has the address `192.168.56.100` and the hypervisor has the address `192.168.56.101`

Install NFS packages

    apt-get install nfs-kernel-server portmap

	mkdir -p /export/secondary
	chown nobody:nogroup /export/secondary
	
Edit /etc/exports and add the following line
	
	/export/secondary 192.168.56.101(rw,sync,no_subtree_check)

Then start the export

    exportfs -a
	
We now need to seed this secondary storage with `SystemVM` templates. SystemVMs are small appliances that run on one of the hypervisor of your infrastructure and help orchestrate the cloud. We have the `Secondary storage VM` which manages image placement and snapshots, the 'Proxy VM' which handles VNC connections to the instances and the 'Virtual Route` which provides network services. To seed the secondary storage with the system VM template on Ubuntu for a KVM hypervisor:

	/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary -u http://download.cloud.com/templates/acton/acton-systemvm-02062012.qcow2.bz2 -h kvm

Note that you will need at least 5GB of disk space on the secondary storage.


	
* Preparing an Hypervisor and setting up a Basic Zone

In this section we will setup an Ubuntu 12.04 KVM hypervisor. The `Secondary` storage setup in the previous section needs to be mounted on this node. Let's start by making this mount.

** Install the packages and mount the secondary storage

First install openntpd on this server as well as the nfs packages for the client

    apt-get install openntpd
    apt-get install nfs-common portmap

Then make the mount

    mkdir -p /mnt/export/secondary
    mount 192.168.56.100:/export/secondary /mnt/export/secondary
	
Check that the mount is successfull with the `df -h` or the `mount` command. Then try to create a file in the mounted directory `touch /mnt/export/secondary`. Verify that you can also edit the file from the management server.

Add the CloudStack repository as was done in the `Using Packages`. Install the CloudStack agent

    apt-get install cloudstack-agent

** Configuring libvirt

You will see that `libvirt` is a dependency of the CloudStack agent package. Once the agent is installed, configure libvirt.

Edit `/etc/libvirt/libvirt.conf` to include:

    listen_tls = 0
    listen_tcp = 1
    tcp_port = "16509"
    auth_tcp = "none"
    mdns_adv = 0
	
In addition edit `/etc/init/libvirt-bin.conf` to modify the libvirt options like so:

    env libvirtd_opts="-d -l"

Then restart libvirt
	
    service libvirt-bin restart

Security Policies needs to be configure properly, check that `apparmor` is running with `dpkg --list 'apparmor'`, if it's not then you have nothing to do, if it is then enter the following commands:

    ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable
    ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable
    apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
    apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper 


** Network bridge setup

We are now going to setup the network bridges, these are used to give network connectivity to the instances that will run on this hypervisor. This configuration can change depending on the number of network interfaces you have, whether or not you use vlans etc. In our simple case, we only have one network interface on the hypervisor and no VLANs. The setup consists in editing `/etc/network/interfaces` and creating two bridges `cloudbr0` and `cloudbr1`


** Firewall settings

For `libvirt` to work you need to open port 16509 and 49512-49216 to enable migration. You can skip those ports if you are not going to do any migraiton. Open port 5900:6100 for VNC sessions to your instances, open port 1798 for the management server communication and 22 so you can ssh to your hypervisor.

The default firewall under Ubuntu is UFW (Uncomplicated FireWall). To open the required ports, execute the following commands:

    ufw allow proto tcp from any to any port 22
    ufw allow proto tcp from any to any port 1798
    ufw allow proto tcp from any to any port 16509
    ufw allow proto tcp from any to any port 5900:6100
    ufw allow proto tcp from any to any port 49152:49216

By default the firewall on Ubuntu 12.04 is disabled. You will need to activate it with `ufw enable`


* Conclusions

CloudStack is a mostly Java application running with Tomcat and Mysql. It consists of a management server and depending on the hypervisors being used, an agent installed on the hypervisor farm. To complete a Cloud infrastructure however you will also need some Zone wide storage a.k.a Secondary Storage and some Cluster wide storage a.k.a Primary storage. The choice of hypervisor, storage solution and type of Zone (i.e Basic vs. Advanced) will dictate how complex your installation can be. As a quick start, you might want to consider KVM+NFS and a Basic Zone.

If you've run into any problems with this, please ask on the cloudstack-dev [mailing list](/mailing-lists.html).
            
