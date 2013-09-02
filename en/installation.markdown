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

Installing OpenJDK
------------------

Install `openjdk`. As we're using Linux, OpenJDK is our first choice. You can install it using Yum or APT, depending on which Linux distribution you use one of these commands:

`apt-get install package_name_of_openjdk`

If you're unsure of the name for the OpenJDK package, use `apt-cache search`, or use your distribution's GUI-based tools for installing and managing packages.

Note that you are free to install another JVM if you have special needs.

Installing Apache Tomcat 6
--------------------------

Install `tomcat6`. Apache CloudStack developers use the tarball from the Tomcat 6 download page, as it's the easiest and fastest way.

Here we'll download Apache Tomcat 6 and uncompress the tarball:

`wget http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.33/bin/apache-tomcat-6.0.33.tar.gz`

`tar xzf apache-tomcat-6.0.33.tar.gz`

**Note** we specifically recommend Apache Tomcat version 6.0.33 at this time. The 6.0.35 release has some issues with Apache CloudStack at this time, thus we recommend avoiding it for CloudStack development.

Now we set the environment variables:

`export CATALINA_HOME=/your_path/apache-tomcat-6.0.33/`

`export CATALINA_BASE=/your_path/apache-tomcat-6.0.33/`
 
**Note**: we usually set them in `~/.bashrc` for convenience.

Install MySQL
-------------

Next, we'll install MySQL if it's not already present on the system.

`apt-get install mysql-server`

Installing from Source
======================


Getting Source
--------------

CloudStack uses git for source version control, if you know little about git, http://book.git-scm.com/ is a good start. Once you have git setup on your machine, pull source with:

    git clone https://git-wip-us.apache.org/repos/asf/cloudstack.git

Compile and Deploy
------------------

Maven procedure developed for Cloudstack 4.1.0 and later:

To compile Apache CloudStack, go to the cloudstack source folder and run:

    mvn -P developer clean install

To deploy Apache CloudStack, run:

    mvn -P developer -pl developer,tools/devcloud -Ddeploydb

Deploy the database next:

    mvn -P developer -pl tools/devcloud -Ddeploysvr

Run Apache CloudStack
---------------------

To start CloudStack, run:

    mvn -pl :cloud-client-ui jetty:run

Log Into Apache CloudStack
--------------------------

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

    nohup mvn -pl client jetty:run &
    sleep 60

Setup a basic zone with Marvin

    mvn -Pdeveloper,marvin.setup -Dmarvin.config=setup/dev/basic.cfg -pl :cloud-marvin integration-test

At this stage log in the CloudStack management server at http://localhost:8080/client with the credentials admin/password, you should see a fully configured basic zone infrastructure. To simulate an advanced zone replace `basic.cfg` with `advanced.cfg`.


Using DevCloud
==============


Using Packages
==============

      

            
