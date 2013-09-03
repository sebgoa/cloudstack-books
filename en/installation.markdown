CloudStack Installation
=======================

This book is aimed at CloudStack users and developers who need to build the code. These instructions are valid on a Ubuntu 12.04 system, please adapt them if you are on a different operating system. We go through several scenarios:

1. Installation of the prerequisites
2. Compiling and installation from source
3. Using the CloudStack simulator
4. Installation with DevCloud the CloudStack sandbox
5. Building packages and/or using the community packaged repo.

Prerequisites
=============

In this section we'll look at installing the dependencies you'll need for Apache CloudStack development.

First update and upgrade your system:

    apt-get update 
    apt-get upgrade

Install `git` to later clone the CloudStack source code:

    apt-get install git

Install `Maven` to later build CloudStack
	
	apt-get install maven

This should have installed Maven 3.0, check the version number with `mvn --version`

A little bit of Python can be used (e.g simulator), install the Python package management tools:

    apt-get install python-pip python-setuptools

Install `openjdk`. As we're using Linux, OpenJDK is our first choice. 

    apt-get install openjdk-6-jdk

Install `tomcat6`, note that the new version of tomcat on [Ubuntu](http://packages.ubuntu.com/precise/all/tomcat6) is the 6.0.35 version.

    apt-get install tomcat6

Next, we'll install MySQL if it's not already present on the system.

    apt-get install mysql-server

Remember to set the correct `mysql` password in the CloudStack properties file. Mysql should be running but you can check it's status with:

    service mysql status

Finally install `mkisofs` with:
	
    apt-get install genisoimage

Installing from Source
======================

CloudStack uses git for source version control, if you know little about [git](http://book.git-scm.com/) is a good start. Once you have git setup on your machine, pull the source with:

    git clone https://git-wip-us.apache.org/repos/asf/cloudstack.git
	
To build the latest stable release:
    
    git checkout 4.2

To compile Apache CloudStack, go to the cloudstack source folder and run:

    mvn -Pdeveloper,systemvm clean install

If you want to skip the tests add `-DskipTests` to the command above

You will have made sure to set the proper db password in `utils/conf/db.properties`

Deploy the database next:

    mvn -P developer -pl developer -Ddeploydb

Run Apache CloudStack with jetty for testing. Note that `tomcat` maybe be running on port 8080, stop it before you use `jetty`

    mvn -pl :cloud-client-ui jetty:run

Log Into Apache CloudStack:

Open your Web browser and use this URL to connect to CloudStack:

    http://localhost:8080/client/

Replace `localhost` with the IP of your management server if need be.

**Note**: If you have iptables enabled, you may have to open the ports used by CloudStack. Specifically, ports 8080, 8250, and 9090.

You can now start configuring a Zone, playing with the API. Of course we did not setup any infrastructure, there is no storage, no hypervisors...etc

Using the Simulator
===================

CloudStack comes with a simulator based on Python bindings called *Marvin*. Marvin is available in the CloudStack source code or on Pypi.
With Marvin you can simulate your data center infrastructure by providing CloudStack with a configuration file that defines the number of zones/pods/clusters/hosts, types of storage etc. You can then develop and test the CloudStack management server *as if* it was managing your production infrastructure.

Do a clean build:

    mvn -Pdeveloper -Dsimulator -DskipTests clean install

Deploy the database:

    mvn -Pdeveloper -pl developer -Ddeploydb
    mvn -Pdeveloper -pl developer -Ddeploydb-simulator

Install marvin. Note that you will need to have installed `pip` properly in the prerequisites step.

    pip install tools/marvin/dist/Marvin-0.1.0.tar.gz

Stop jetty (from any previous runs)

    mvn -pl :cloud-client-ui jetty:stop

Start jetty

    mvn -pl client jetty:run
   
Setup a basic zone with Marvin. In a separate shell://

    mvn -Pdeveloper,marvin.setup -Dmarvin.config=setup/dev/basic.cfg -pl :cloud-marvin integration-test

At this stage log in the CloudStack management server at http://localhost:8080/client with the credentials admin/password, you should see a fully configured basic zone infrastructure. To simulate an advanced zone replace `basic.cfg` with `advanced.cfg`.

You can now run integration tests, use the API etc...

Using DevCloud
==============

The Installing from source section will only get you to the point of runnign the management server, it does not get you any hypervisors. 
The simulator section gets you a simulated datacenter for testing. With DevCloud you can run at least one hypervisor and add it to your management server the way you would a real physical machine.

[DevCloud](https://cwiki.apache.org/confluence/display/CLOUDSTACK/DevCloud) is the CloudStack sandbox, the standard version is a VirtualBox based image. There is also a KVM based image for it. Here we only show steps with the VirtualBox image. For KVM see the [wiki](https://cwiki.apache.org/confluence/display/CLOUDSTACK/devcloud-kvm).

DevCloud Pre-requisites
-----------------------

1. Install [VirtualBox](http://www.virtualbox.org) on your machine

2. Run VirtualBox and under >Preferences create a *host-only interface* on which you disable the DHCP server

3. Download the DevCloud [image](http://people.apache.org/~bhaisaab/cloudstack/devcloud/devcloud2.ova)

4. In VirtualBox, under File > Import Appliance import the DevCloud image.

5. Verify the settings under > Settings and check the `enable PAE` option in the processor menu

6. Once the VM has booted try to `ssh` to it with credentials: `root/password`

    ssh root@192.168.56.10

Adding DevCloud as an Hypervisor
--------------------------------

Picking up from a clean build:

    mvn -Pdeveloper,systemvm clean install
    mvn -P developer -pl developer,tools/devcloud -Ddeploydb
	
At this stage install marvin similarly than with the simulator:

    pip install tools/marvin/dist/Marvin-0.1.0.tar.gz

Then you are going to configure CloudStack to use the running DevCloud instance:
	
    cd tools/devcloud
    python ../marvin/marvin/deployDataCenter.py -i devcloud.cfg
	
If you are curious, check the `devcloud.cfg` file and see how the data center is defined: 1 Zone, 1 Pod, 1 Cluster, 1 Host, 1 primary Storage, 1 Seondary Storage, all provided by Devcloud.
	
You can now log in the management server at `http://localhost:8080/client` and start experimenting with the UI or the API.

Do note that the management server is running in your local machine and that DevCloud is used only as a n Hypervisor. You could potentially run the management server within DevCloud as well, or memory granted, run multiple DevClouds.


Testing the AWS API interface
=============================

Starting from a running management server (with DevCloud for instance), start the AWS API interface in a separate shell with:

    mvn -Pawsapi -pl:cloud-awsapi jetty:run

Log into the CloudStack UI `http://localhost:8080/client`, go to *Service Offerings* and edit one of the compute offerings to have the name `m1.small` or any of the other AWS EC2 instance types.

With access and secret keys generated for a user you should now be able to use Python [Boto](http://docs.pythonboto.org/en/latest/) module:

    import boto
    import boto.ec2

    accesskey="2IUSA5xylbsPSnBQFoWXKg3RvjHgsufcKhC1SeiCbeEc0obKwUlwJamB_gFmMJkFHYHTIafpUx0pHcfLvt-dzw"
    secretkey="oxV5Dhhk5ufNowey7OVHgWxCBVS4deTl9qL0EqMthfPBuy3ScHPo2fifDxw1aXeL5cyH10hnLOKjyKphcXGeDA"
 
    region = boto.ec2.regioninfo.RegionInfo(name="ROOT", endpoint="localhost")
    conn = boto.connect_ec2(aws_access_key_id=accesskey, aws_secret_access_key=secretkey, is_secure=False, region=region, port=7080, path="/awsapi", api_version="2012-08-15")

    images=conn.get_all_images()
    print images

    res = images[0].run(instance_type='m1.small',security_groups=['default'])

Note the new `api_version` number in the connection object and also note that there was no user registration to make like in previous CloudStack releases../

Using Packages
==============

If you want you can build your own packages but you can use existing one hosted in a community repo.

To prepare your own .deb packages
---------------------------------

To use hosted packages
----------------------

Edit `/etc/apt/sources.list.d/cloudstack.list` and add:

    deb http://cloudstack.apt-get.eu/ubuntu precise 4.1

Replace 4.1 with 4.2 once 4.2 is out

Add the public keys to the trusted keys:

    wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -

update your local apt cache

    apt-get update

Install the management server package
	
    apt-get install cloudstack-management



Conclusions
===========

CloudStack is a mostly Java applicaton running with Tomcat and Mysql. It consists of a management server and depending on the hypervisors being used, an agent installed on the hypervisor farm. To complete a Cloud infrastructure however you will also need some Zone wide storage a.k.a Secondary Storage and some Cluster wide storage a.k.a Primary storage. The choice of hypervisor, storage solution and type of Zone (i.e Basic vs. Advanced) will dictate how complex your installation can be. As a quick started, you might want to consider KVM+NFS and a Basic Zone.

If you've run into any problems with this, please ask on the cloudstack-dev [mailing list](/mailing-lists.html).
            
