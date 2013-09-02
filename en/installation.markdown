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

Install `Maven` to later build CloudStacK
	
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

To compile Apache CloudStack, go to the cloudstack source folder and run:

    mvn -Pdeveloper,systemvm clean install

To deploy Apache CloudStack, run:

    mvn -Pdeveloper -pl tools/devcloud -Ddeploysvr

You will have made sure to set the proper db password in `utils/conf/db.properties`
Deploy the database next:

    mvn -P developer -pl developer -Ddeploydb

Run Apache CloudStack with jetty for testing.

    mvn -pl :cloud-client-ui jetty:run

Log Into Apache CloudStack:

Open your Web browser and use this URL to connect to CloudStack:

    http://localhost:8080/client/

or

   http://ip_address_where_cloudstack_is_running:8080/client

**Note**: If you have iptables enabled, you may have to open the ports used by CloudStack. Specifically, ports 8080, 8250, and 9090.

If you've run into any problems with this, please ask on the cloudstack-dev [mailing list](/mailing-lists.html).

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


Using DevCloud
==============


Using Packages
==============

      

            
