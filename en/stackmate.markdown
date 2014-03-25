Stackmate
=========

[Stackmate](https://github.com/stackmate/stackmate) is a client side application to process Amazon Cloud Formation templates. According to the website, AWS [Cloud Formation](http://aws.amazon.com/cloudformation/) is an Amazon Web Service (AWS) service that:

>AWS CloudFormation gives developers and systems administrators an easy way to create and manage a collection of related AWS resources, provisioning and updating them in an orderly and predictable fashion.

With Stackmate you can use Cloud Formation [templates](http://aws.amazon.com/cloudformation/aws-cloudformation-templates/) and feed them to a CloudStack cloud for provisioning and configuration of instances in the cloud.


Installing Stackmate
--------------------

Update your machine and install `git`

    apt-get update
    apt-get -y install git
	
Install `bunlder` and `rubygems`

    apt-get -y install ruby-bundler rubygems

Clone `stackmate` from github and build it

    git clone https://github.com/stackmate/stackmate.git
	cd stackmate
	bundle install

To start a template you will need the `zoneid`, `serviceofferingid` and `templateid` that you want to use on your target CloudStack cloud. You can obtain these from [CloudMonkey](http://pythonhosted.org/cloudmonkey/) or other CloudStack clients. Then issue the following command to deploy a single LAMP stack:

    bin/stackmate MYSTACK01 --template-file=templates/CloudStack/LAMP_Single_Instance_CloudStack.template -p "DBName=cloud;DBUserName=cloud;SSHLocation=0.0.0.0/24;DBUsername=cloud;DBPassword=cloud;DBRootPassword=cloud;KeyName=exoscale;zoneid=1128bd56-b4d9-4ac6-a7b9-c715b187ce11;templateid=35a37ccd-5bf6-4c5f-a9a1-1884f99e1fd3;serviceofferingid=b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8"
    
Note that the template file `templates/CloudStack/LAMP_Single_Instance_CloudStack.template` is aimed at CentOS/RHEL flavor distribution. If you are targeting a different OS like Debian/Ubuntu you will need to update the template. Another critical aspect is the use of AWS CF helper scripts in the templates.

AWS Cloud Formation helper [scripts](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html) are used to configure the instances and orchestrate the members of a `template`. To properly consume a CF on a cloud different than AWS, you will need to use image templates that support cloud-init and then install the AWS CF helper scripts. They are available form source, as rpm or in zip file. Typically if these scripts are not present on the images used in the cloud, they are installed via `userdata` passed to the instance started. Below are two examples of how to install these scripts:

For CentOS

    rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
    yum -y install pystache python-daemon python-requests
    rpm -ivh https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.amzn1.noarch.rpm

On ubuntu 12.04

    apt-get -y install unzip
    cd /opt
    wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.zip
    unzip aws-cfn-bootstrap-latest.zip
    ln -s aws-cfn-bootstrap-1.3 aws

However for `stackmate` and `stacktician` to properly use the metadata that defines the packages to install on the instances, the cfn scripts need to be modified to point to a different metadata server than the AWS one. Therefore we have modified CFN scripts that you can get from `https://github.com/runseb/Cloudworks.git`, just go to the `aws-cfn-boostrap-1.3` directory and run `python ./setup.py install` on the instance. Obivously this needs to be done at instance start up via userdata scripts.

Stacktician
-----------

[Stacktician](https://github.com/stackmate/stacktician) is the web fron-end for `stackmate`. It is a Ruby Rails application that will serve as a web UI for users wanting to deploy templates to a cloud. Stacktician also serves the template metadata to configure the instances.

Installing Stacktician
~~~~~~~~~~~~~~~~~~~~~~

Get ruby 1.9.2 or newer

    apt-get update
	apt-get -y install ruby1.9.3

Get `bundler` and `rubygems`
    
	apt-get -y install rubygems 
	gem1.9.3 install bundler
	
To get `nokogiri` and other gems to install properly you will need a few additional libraries:
 	
	apt-get -y install libxml2-dev libxslt1-dev	
	apt-get -y install libpq-dev
	apt-get -y install libsqlite3-dev
	
Install a javascript runtime

    apt-get -y install nodejs
	
Clone the repo and install

    apt-get -y install git
    git clone https://github.com/stackmate/stacktician.git
    cd stacktician
    bundle install --without=production
	
Setup the database and seed it

    rake db:create
    rake db:migrate
    rake db:seed

If you need to remove the database do a `rake db:drop`. Note that the seeding of the template points to a URL that holds them. In my version I modified `/db/seeds.rb` to point to http://people.apache.org/~sebgoa/templates which holds CloudStack compatible CF templates.

Setup a few environment variables for the Cloud that you will be using to deploy the templates

    export CS_URL=https://api.exoscale.ch/compute
	
If you are an admin of the Cloud set the `CS_ADMIN_APIKEY` and `CS_ADMIN_SECKEY` variables otherwise don't.
	
    export CS_ADMIN_APIKEY=PQogHsbVdNPUn-mg
    export CS_ADMIN_SECKEY=aHuDB2UjEg
    export CS_LOCAL="---\nservice_offerings:\n  m1.small: 1c8db272-f95a-406c-bce3-39192ce965fa\ntemplates:\n  ami-1b814f72: 3ea4563e-c7eb-11e2-b0ed-7f3baba63e45\nzoneid: b3409835-02b0-4d21-bba4-1f659402117e\n"
	
Run `stacktician` rails server

    bundle exec rails server

You should now be able to access the UI on port 3000 of the host you are running `stacktician` on.