About This Book
===============

License
-------
The Little CloudStack Book book is licensed under the Attribution-NonCommercial 3.0 Unported license. **You should not have paid for this book.**

You are basically free to copy, distribute, modify or display the book. However, I ask that you always attribute the book to me, Sebastien Goasguen and do not use it for commercial purposes.

You can see the full text of the license at:

<http://creativecommons.org/licenses/by-nc/3.0/legalcode>

"Apache", "CloudStack", "Apache CloudStack", the Apache CloudStack logo, the Apache CloudStack Cloud Monkey logo and the Apache feather logos are registered trademarks or trademarks of The Apache Software Foundation.


About The Author
----------------
Sebastien Goasguen is an Apache CloudStack committer and member of the CloudStack Project Management Committee (PMC). His day job is to be a Senior Open Source Solutions Architect for the Open Source Business Office at Citrix. He will never call himself an expert or a developer but is a decent Python programmer. He is currently active in Apache Libcloud and SaltStack salt-cloud projects to bring better support for CloudStack. He blogs regularly about cloud technologies and spends lots of time testing and writing about his experiences. Prior to working actively on CloudStack he had a life as an academic, he authored over seventy international publications on grid computing, high performance computing, electromagnetics, nanoelectronics and of course cloud computing. He also taught courses on distributed computing, network programming, ethical hacking and cloud.

His blog can be found at http://sebgoa.blogspot.com and he tweets via @sebgoa. You can find him on github at https://github.com/runseb

Introduction
------------
Clients and high level Wrappers are critical to the ease of use of any API, even more
so Cloud APIs. In this book we present the basics of the CloudStack API and introduce some low level clients before diving into more advanced wrappers.
The first chapter is dedicated to clients and the second chapter to wrappers or what I considered to be high level tools built on top of a CloudStack client.

In the first chapter, we start by illustrating how to sign requests with the native API -in the sake of completeness- and
because it is a very nice exercise for beginners. We then introduce CloudMonkey the CloudStack CLI and shell which boasts a 100% coverage of
the API. Then jclouds is discussed. While jclouds is a java library, it can also be used as a cli or interactive shell, we present jclouds-cli to contrast it to
CloudMonkey and introduce jclouds. Apache libcloud is a Python module that provides a common API on top of many Cloud providers API, once installed, a developer can use libcloud to talk to multiple cloud providers and cloud APIs, it serves a similar role as jclouds but in Python. Finally, we present Boto, the well-known Python Amazon Web Service interface, and show how it can be used with a CloudStack cloud running the AWS interface.

In the second chapter we introduce several high level wrappers for configuration management and automated provisioning.
The presentation of these wrappers aim to answer the question "I have a cloud now what ?". Starting and stoping virtual machines is the core functionality of a cloud, 
but it empowers users to do much more. Automation is the key of today's IT infrastructure. The wrappers presented here show you how you can automate configuration management and automate provisioning of infrastructures that lie within your cloud. We introduce Salt-cloud for Saltstack, a Python alternative to the well known Chef and Puppet systems. We then introduce the knife CloudStack plugin for Chef and show you how easy it is to deploy machines in a cloud and configure them, we finish with another Apache project based on jclouds: Whirr. Apache Whirr simplifies the on-demand provisioning of clusters of virtual machine instances, hence it allows you to easily provision big data infrastructure on-demand, whether you need a *HADOOP* cluster, an *Elasticsearch* cluster or even a *Cassandra* cluster.

The CloudStack API
==================
All functionalities of the CloudStack data center orchestrator are exposed
via an API server. Github currently has over twenty clients for this
API, in various languages. In this section we introduce this API and the
signing mechanism. The follow on sections will introduce clients that
already contain a signing method. The signing process is only
highlighted for completeness.

Basics of the API
-----------------
The CloudStack API is a query based API using http which returns results in XML or JSON. It is used to implement the default web UI. This API is not a standard like [OGF OCCI](http://www.ogf.org/gf/group_info/view.php?group=occi-wg) or [DMTF CIMI](http://dmtf.org/standards/cloud) but is easy to learn. A mapping exists between the AWS API and the CloudStack API as will be seen in the next section. Recently a Google Compute Engine interface was also developed that maps the GCE REST API to the CloudStack API described here. The API [docs](http://cloudstack.apache.org/docs/api/) are a good start to learn the extent of the API. Multiple clients exist on [github](https://github.com/search?q=cloudstack+client&ref=cmdform) to use this API, you should be able to find one in your favorite language. The reference documentation for the API and changes that might occur from version to version is availble [on-line](http://cloudstack.apache.org/docs/en-US/Apache_CloudStack/4.1.1/html/Developers_Guide/index.html). This short section is aimed at providing a quick summary to give you a base understanding of how to use this API. As a quick start, a good way to explore the API is to navigate the dashboard with a firebug console (or similar developer console) to study the queries.

In a succint statement, the CloudStack query API can be used via http GET requests made against your cloud endpoint (e.g http://localhost:8080/client/api). The API name is passed using the `command` key and the various parameters for this API call are passed as key value pairs. The request is signed using the secret key of the user making the call. Some calls are synchronous while some are asynchronous, this is documented in the API [docs](http://cloudstack.apache.org/docs/api/). Asynchronous calls return a `jobid`, the status and result of a job can be queried with the `queryAsyncJobResult` call. Let's get started and give an example of calling the `listUsers` API in Python.

First you will need to generate keys to make requests. Going through the dashboard, go under `Accounts` select the appropriate account then click on `Show Users` select the intended user and generate keys using the `Generate Keys` icon. You will see an `API Key` and `Secret Key` field being generated. The keys will be of the form:

    API Key : XzAz0uC0t888gOzPs3HchY72qwDc7pUPIO8LxC-VkIHo4C3fvbEBY_Ccj8fo3mBapN5qRDg_0_EbGdbxi8oy1A
	Secret Key: zmBOXAXPlfb-LIygOxUVblAbz7E47eukDS_0JYUxP3JAmknOYo56T0R-AcM7rK7SMyo11Y6XW22gyuXzOdiybQ

Open a Python shell and import the basic modules necessary to make the request. Do note that this request could be made many different ways, this is just a low level example. The `urllib*` modules are used to make the http request and do url encoding. The `hashlib` module gives us the sha1 hash function. It is used to generate the `hmac` (Keyed Hashing for Message Authentication) using the secretkey. The result is encoded using the `base64` module.

    $python
    Python 2.7.3 (default, Nov 17 2012, 19:54:34) 
    [GCC 4.2.1 Compatible Apple Clang 4.1 ((tags/Apple/clang-421.11.66))] on darwin
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import urllib2
    >>> import urllib
    >>> import hashlib
    >>> import hmac
    >>> import base64

Define the endpoint of the Cloud, the command that you want to execute, the type of the response (i.e XML or JSON) and the keys of the user. Note that we do not put the secretkey in our request dictionary because it is only used to compute the hmac.

    >>> baseurl='http://localhost:8080/client/api?'
    >>> request={}
    >>> request['command']='listUsers'
    >>> request['response']='json'
    >>> request['apikey']='plgWJfZK4gyS3mOMTVmjUVg-X-jlWlnfaUJ9GAbBbf9EdM-kAYMmAiLqzzq1ElZLYq_u38zCm0bewzGUdP66mg'
    >>> secretkey='VDaACYb0LV9eNjTetIOElcVQkvJck_J_QljX_FcHRj87ZKiy0z0ty0ZsYBkoXkY9b7EhwJaw7FF3akA3KBQ'

Build the base request string, the combination of all the key/pairs of the request, url encoded and joined with ampersand.

    >>> request_str='&'.join(['='.join([k,urllib.quote_plus(request[k])]) for k in request.keys()])
    >>> request_str
    'apikey=plgWJfZK4gyS3mOMTVmjUVg-X-jlWlnfaUJ9GAbBbf9EdM-kAYMmAiLqzzq1ElZLYq_u38zCm0bewzGUdP66mg&command=listUsers&response=json'

Compute the signature with hmac, do a 64 bit encoding and a url encoding, the string used for the signature is similar to the base request string shown above but the keys/values are lower cased and joined in a sorted order

    >>> sig_str='&'.join(['='.join([k.lower(),urllib.quote_plus(request[k].lower().replace('+','%20'))])for k in sorted(request.iterkeys())]) 
    >>> sig_str
    'apikey=plgwjfzk4gys3momtvmjuvg-x-jlwlnfauj9gabbbf9edm-kaymmailqzzq1elzlyq_u38zcm0bewzgudp66mg&command=listusers&response=json'
    >>> sig=hmac.new(secretkey,sig_str,hashlib.sha1).digest()
    >>> sig
    'M:]\x0e\xaf\xfb\x8f\xf2y\xf1p\x91\x1e\x89\x8a\xa1\x05\xc4A\xdb'
    >>> sig=base64.encodestring(hmac.new(secretkey,sig_str,hashlib.sha1).digest())
    >>> sig
    'TTpdDq/7j/J58XCRHomKoQXEQds=\n'
    >>> sig=base64.encodestring(hmac.new(secretkey,sig_str,hashlib.sha1).digest()).strip()
    >>> sig
    'TTpdDq/7j/J58XCRHomKoQXEQds='
    >>> sig=urllib.quote_plus(base64.encodestring(hmac.new(secretkey,sig_str,hashlib.sha1).digest()).strip())

Finally, build the entire string by joining the baseurl, the request str and the signature. Then do an http GET:

    >>> req=baseurl+request_str+'&signature='+sig
    >>> req
    'http://localhost:8080/client/api?apikey=plgWJfZK4gyS3mOMTVmjUVg-X-jlWlnfaUJ9GAbBbf9EdM-kAYMmAiLqzzq1ElZLYq_u38zCm0bewzGUdP66mg&command=listUsers&response=json&signature=TTpdDq%2F7j%2FJ58XCRHomKoQXEQds%3D'
    >>> res=urllib2.urlopen(req)
    >>> res.read()
    '{ "listusersresponse" : { "count":1 ,"user" : [  {"id":"7ed6d5da-93b2-4545-a502-23d20b48ef2a","username":"admin","firstname":"admin",
	   "lastname":"cloud","created":"2012-07-05T12:18:27-0700","state":"enabled","account":"admin",
       "accounttype":1,"domainid":"8a111e58-e155-4482-93ce-84efff3c7c77","domain":"ROOT",
	   "apikey":"plgWJfZK4gyS3mOMTVmjUVg-X-jlWlnfaUJ9GAbBbf9EdM-kAYMmAiLqzzq1ElZLYq_u38zCm0bewzGUdP66mg",
	   "secretkey":"VDaACYb0LV9eNjTetIOElcVQkvJck_J_QljX_FcHRj87ZKiy0z0ty0ZshwJaw7FF3akA3KBQ",
	   "accountid":"7548ac03-af1d-4c1c-9064-2f3e2c0eda0d"}]}}
													   
All the clients that you will find on github will implement this signature technique, you should not have to do it by hand. Now that you have explored the API through the UI and that you understand how to make low level calls, pick your favorite client or use [CloudMonkey](https://pypi.python.org/pypi/cloudmonkey/). CloudMonkey is a sub-project of Apache CloudStack and gives operators/developers the ability to use any of the API methods. It has nice auto-completion, history and help features as well as an API discovery mechanism since 4.2.

CloudMonkey
===========
CloudMonkey is the CloudStack Command Line Interface (CLI). It is written
in Python. CloudMonkey can be used both as an interactive shell and as a
command line tool which simplifies CloudStack configuration and management.
It can be used with CloudStack 4.0-incubating and above


Installing CloudMonkey
----------------------
CloudMonkey is dependent on *readline, pygments, prettytable*, when
installing from source you will need to resolve those dependencies.
Using the cheese shop, the dependencies will be automatically installed.

There are two ways to get CloudMonkey. Via the official CloudStack source
releases or via a community maintained distribution at [the cheese
shop](http://pypi.python.org/pypi/cloudmonkey/). CloudMonkey now lives within its own repository but it used to be part of the CloudStack release. Developers could get
it directly from the CloudStack git repository in *tools/cli/*. Now, it is better to use the CloudMonkey specific repository.

-   Via the official Apache CloudStack-CloudMonkey git
    repository.

            
        $ git clone https://git-wip-us.apache.org/repos/asf/cloudstack-cloudmonkey.git
        $ sudo python setup.py install
            

-   Via a community maintained package on [Cheese Shop](https://pypi.python.org/pypi/cloudmonkey/)

        pip install cloudmonkey

Configuration
-------------
To configure CloudMonkey you can edit the `~/.cloudmonkey/config` file in
the user's home directory as shown below. The values can also be set
interactively at the cloudmonkey prompt. Logs are kept in
`~/.cloudmonkey/log`, and history is stored in `~/.cloudmonkey/history`.
Discovered apis are listed in `~/.cloudmonkey/cache`. Only the log and
history files can be custom paths and can be configured by setting
appropriate file paths in `~/.cloudmonkey/config`

    $ cat ~/.cloudmonkey/config 
    [core]
    log_file = /Users/sebastiengoasguen/.cloudmonkey/log
    asyncblock = true
    paramcompletion = false
    history_file = /Users/sebastiengoasguen/.cloudmonkey/history

    [ui]
    color = true
    prompt = > 
    display = table

    [user]
    secretkey =VDaACYb0LV9eNjTetIOElcVQkvJck_J_QljX_FcHRj87ZKiy0z0ty0ZsYBkoXkY9b7eq1EhwJaw7FF3akA3KBQ 
    apikey = plgWJfZK4gyS3mOMTVmjUVg-X-jlWlnfaUJ9GAbBbf9EdMkAYMmAiLqzzq1ElZLYq_u38zCm0bewzGUdP66mg

    [server]
    path = /client/api
    host = localhost
    protocol = http
    port = 8080
    timeout = 3600        

The values can also be set at the CloudMonkey prompt. The API and secret
keys are obtained via the CloudStack UI or via a raw api call.

    $ cloudmonkey
    ☁ Apache CloudStack cloudmonkey 4.1.0-snapshot. Type help or ? to list commands.

    > set prompt myprompt>
    myprompt> set host localhost
    myprompt> set port 8080
    myprompt> set apikey <your api key>
    myprompt> set secretkey <your secret key>

You can use CloudMonkey to interact with a local cloud, and even with a
remote public cloud. You just need to set the host value properly and
obtain the keys from the cloud administrator.

API Discovery
-------------
> **Note**
>
> In CloudStack 4.0.\* releases, the list of api calls available will be
> pre-cached, while starting with CloudStack 4.1 releases and above an API
> discovery service is enabled. CloudMonkey will discover automatically
> the api calls available on the management server. The sync command in
> CloudMonkey pulls a list of apis which are accessible to your user
> role. This allows cloudmonkey to be adaptable to
> changes in mgmt server, so in case the sysadmin enables a plugin such
> as Nicira NVP for that user role, the users can get those changes.

To discover the APIs available do:

     > sync
    324 APIs discovered and cached

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
    > list users filter=id,domain,account
    count = 1
    user:
    +--------------------------------------+--------+---------+
    |                  id                  | domain | account |
    +--------------------------------------+--------+---------+
    | 7ed6d5da-93b2-4545-a502-23d20b48ef2a |  ROOT  |  admin  |
    +--------------------------------------+--------+---------+
        

Interactive Shell Usage
-----------------------
To start learning CloudMonkey, the best is to use the interactive shell.
Simply type CloudMonkey at the prompt and you should get the interactive
shell.

At the CloudMonkey prompt press the tab key twice, you will see all
potential verbs available. Pick one, enter a space and then press tab
twice. You will see all actions available for that verb

    cloudmonkey>
    EOF        assign     cancel     create     detach     extract    ldap       prepare    reconnect  restart    shell      update     
    ...    
    cloudmonkey>create 
    account                diskoffering           loadbalancerrule       portforwardingrule     snapshot               tags                   vpc
    ...
        
Picking one action and entering a space plus the tab key, you will
obtain the list of parameters for that specific api call.

    cloudmonkey>create network 
    account=            domainid=           isAsync=            networkdomain=      projectid=          vlan=               
    acltype=            endip=              name=               networkofferingid=  startip=            vpcid=              
    displaytext=        gateway=            netmask=            physicalnetworkid=  subdomainaccess=    zoneid=                     

To get additional help on that specific api call you can use the
following:

    cloudmonkey>create network -h
    Creates a network
    Required args: displaytext name networkofferingid zoneid
    Args: account acltype displaytext domainid endip gateway isAsync name netmask networkdomain networkofferingid physicalnetworkid projectid startip subdomainaccess vlan vpcid zoneid

    cloudmonkey>create network -help
    Creates a network
    Required args: displaytext name networkofferingid zoneid
    Args: account acltype displaytext domainid endip gateway isAsync name netmask networkdomain networkofferingid physicalnetworkid projectid startip subdomainaccess vlan vpcid zoneid

    cloudmonkey>create network --help
    Creates a network
    Required args: displaytext name networkofferingid zoneid
    Args: account acltype displaytext domainid endip gateway isAsync name netmask networkdomain networkofferingid physicalnetworkid projectid startip subdomainaccess vlan vpcid zoneid
    cloudmonkey>        

Note the required arguments necessary for the calls.

> **Note**
>
> To find out the required parameters value, using a debugger console on
> the CloudStack UI might be very useful. For instance using Firebug on
> Firefox, you can navigate the UI and check the parameters values for
> each call you are making as you navigate the UI.

Starting a Virtual Machine instance with CloudMonkey
----------------------------------------------------
To start a virtual machine instance we will use the *deploy
virtualmachine* call.

    cloudmonkey>deploy virtualmachine -h
    Creates and automatically starts a virtual machine based on a service offering, disk offering, and template.
    Required args: serviceofferingid templateid zoneid
    Args: account diskofferingid displayname domainid group hostid hypervisor ipaddress iptonetworklist isAsync keyboard keypair name networkids projectid securitygroupids securitygroupnames serviceofferingid size startvm templateid userdata zoneid

The required arguments are *serviceofferingid, templateid and zoneid*

In order to specify the template that we want to use, we can list all
available templates with the following call:

    cloudmonkey>list templates templatefilter=all
    count = 2
    template:
    ========
    domain = ROOT
    domainid = 8a111e58-e155-4482-93ce-84efff3c7c77
    zoneid = e1bfdfaf-3d9b-43d4-9aea-2c9f173a1ae7
    displaytext = SystemVM Template (XenServer)
    ostypeid = 849d7d0a-9fbe-452a-85aa-70e0a0cbc688
    passwordenabled = False
    id = 6d360f79-4de9-468c-82f8-a348135d298e
    size = 2101252608
    isready = True
    templatetype = SYSTEM
    zonename = devcloud
    ...<snipped>

In this snippet, I used DevCloud and only showed the beginning output of
the first template, the SystemVM template

Similarly to get the *serviceofferingid* you would do:

    cloudmonkey>list serviceofferings | grep id
    id = ef2537ad-c70f-11e1-821b-0800277e749c
    id = c66c2557-12a7-4b32-94f4-48837da3fa84
    id = 3d8b82e5-d8e7-48d5-a554-cf853111bc50

Note that we can use the linux pipe as well as standard linux commands
within the interactive shell. Finally we would start an instance with
the following call:

    cloudmonkey>deploy virtualmachine templateid=13ccff62-132b-4caf-b456-e8ef20cbff0e zoneid=e1bfdfaf-3d9b-43d4-9aea-2c9f173a1ae7 serviceofferingid=ef2537ad-c70f-11e1-821b-0800277e749c
    jobprocstatus = 0
    created = 2013-03-05T13:04:51-0800
    cmd = com.cloud.api.commands.DeployVMCmd
    userid = 7ed6d5da-93b2-4545-a502-23d20b48ef2a
    jobstatus = 1
    jobid = c441d894-e116-402d-aa36-fdb45adb16b7
    jobresultcode = 0
    jobresulttype = object
    jobresult:
    =========
    virtualmachine:
    ==============
    domain = ROOT
    domainid = 8a111e58-e155-4482-93ce-84efff3c7c77
    haenable = False
    templatename = tiny Linux
    ...<snipped>

The instance would be stopped with:

    cloudmonkey>stop virtualmachine id=7efe0377-4102-4193-bff8-c706909cc2d2
        
> **Note**
>
> The *ids* that you will use will differ from this example. Make sure
> you use the ones that corresponds to your CloudStack cloud.

Scripting with CloudMonkey
--------------------------
All previous examples use CloudMonkey via the interactive shell, however
it can be used as a straightfoward CLI, passing the commands to the
*cloudmonkey* command like shown below.

    $cloudmonkey list users

As such it can be used in shell scripts, it can received commands via
stdin and its output can be parsed like any other unix commands as
mentioned before.

jClouds CLI
===========
jclouds is a Java wrapper for many Cloud Providers APIs, it used in a
large number of Cloud application to access providers that do not offer
a standard APIs. jclouds-cli is the command line interface to jclouds
and in CloudStack terminology could be seen as an equivalent to
CloudMonkey.

However CloudMonkey covers the entire CloudStack API and jclouds-cli does
not. Management of virtual machines, blobstore (i.e S3 like) and
configuration management via chef are the main features.

> **Warning**
>
> jclouds is under going incubation at the Apache Software Foundation,
> jclouds-cli is available on github. Changes may occur in the sofware
> from the time of this writing to the time of you reading it.

Installation and Configuration
------------------------------
First install jclouds-cli via github and build it with maven:

    $git clone https://github.com/jclouds/jclouds-cli.git
    $cd jclouds-cli
    $mvn install       

Locate the tarball generated by the build in *assembly/target*, extract
the tarball in the directory of your choice and add the bin directory to
your path. For instance:

    export PATH=/Users/sebastiengoasguen/Documents/jclouds-cli-1.7.0/bin        

Define a few environmental variables to set your endpoint and your
credentials, the ones listed below are just examples. Adapt to your own
endpoint and keys.

    export JCLOUDS_COMPUTE_API=cloudstack
    export JCLOUDS_COMPUTE_ENDPOINT=http://localhost:8080/client/api
    export JCLOUDS_COMPUTE_CREDENTIAL=_UKIzPgw7BneOyJO621Tdlslicg
    export JCLOUDS_COMPUTE_IDENTITY=mnH5EbKcKeJdJrvguEIwQG_Fn-N0l        

You should now be able to use jclouds-cli, check that it is in your path
and runs, you should see the following output:

    sebmini:jclouds-cli-1.7.0-SNAPSHOT sebastiengoasguen$ jclouds-cli
       _       _                 _      
      (_)     | |               | |     
       _  ____| | ___  _   _  _ | | ___ 
      | |/ ___) |/ _ \| | | |/ || |/___)
      | ( (___| | |_| | |_| ( (_| |___ |
     _| |\____)_|\___/ \____|\____(___/ 
    (__/                                 

      jclouds cli (1.7.0-SNAPSHOT)
      http://jclouds.org

    Hit '<tab>' for a list of available commands
    and '[cmd] --help' for help on a specific command.
    Hit '<ctrl-d>' to shutdown jclouds cli.

    jclouds> features:list
    State         Version          Name                                    Repository             Description
    [installed  ] [1.7.0-SNAPSHOT] jclouds-guice                           jclouds-1.7.0-SNAPSHOT Jclouds - Google Guice
    [installed  ] [1.7.0-SNAPSHOT] jclouds                                 jclouds-1.7.0-SNAPSHOT JClouds
    [installed  ] [1.7.0-SNAPSHOT] jclouds-blobstore                       jclouds-1.7.0-SNAPSHOT JClouds Blobstore
    [installed  ] [1.7.0-SNAPSHOT] jclouds-compute                         jclouds-1.7.0-SNAPSHOT JClouds Compute
    [installed  ] [1.7.0-SNAPSHOT] jclouds-management                      jclouds-1.7.0-SNAPSHOT JClouds Management
    [uninstalled] [1.7.0-SNAPSHOT] jclouds-api-filesystem                  jclouds-1.7.0-SNAPSHOT JClouds - API - FileSystem
    [installed  ] [1.7.0-SNAPSHOT] jclouds-aws-ec2                         jclouds-1.7.0-SNAPSHOT Amazon Web Service - EC2
    [uninstalled] [1.7.0-SNAPSHOT] jclouds-aws-route53                     jclouds-1.7.0-SNAPSHOT Amazon Web Service - Route 53
    [installed  ] [1.7.0-SNAPSHOT] jclouds-aws-s3                          jclouds-1.7.0-SNAPSHOT Amazon Web Service - S3
    [uninstalled] [1.7.0-SNAPSHOT] jclouds-aws-sqs                         jclouds-1.7.0-SNAPSHOT Amazon Web Service - SQS
    [uninstalled] [1.7.0-SNAPSHOT] jclouds-aws-sts                         jclouds-1.7.0-SNAPSHOT Amazon Web Service - STS
    ...<snip>        

> **Note**
>
> I edited the output of jclouds-cli to gain some space, there a lot
> more providers available

Using jclouds CLI
-----------------
The CloudStack API driver is not installed by default. Install it with:

    jclouds> features:install jclouds-api-cloudstack        

For now we will only test the virtual machine management functionality.
Pretty basic but that's what we want to do to get a feel for
jclouds-cli. If you have set your endpoint and keys properly, you should
be able to list the location of your cloud like so:

    $ jclouds location list
    [id]                                 [scope]  [description]                   [parent]  
    cloudstack                           PROVIDER https://api.exoscale.ch/compute           
    1128bd56-b4d9-4ac6-a7b9-c715b187ce11 ZONE     CH-GV2                          cloudstack        

Again this is an example, you will see something different depending on
your endpoint.

You can list the service offerings with:

    $ jclouds hardware list
    [id]                                 [ram]   [cpu] [cores]
    71004023-bb72-4a97-b1e9-bc66dfce9470   512  2198.0     1.0
    b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8  1024  2198.0     1.0
    21624abb-764e-4def-81d7-9fc54b5957fb  2048  4396.0     2.0
    b6e9d1e8-89fc-4db3-aaa4-9b4c5b1d0844  4096  4396.0     2.0
    c6f99499-7f59-4138-9427-a09db13af2bc  8182  8792.0     4.0
    350dc5ea-fe6d-42ba-b6c0-efb8b75617ad 16384  8792.0     4.0
    a216b0d1-370f-4e21-a0eb-3dfc6302b564 32184 17584.0     8.0
        

List the images available with:

    $ jclouds image list
    [id]                                 [location] [os family]  [os version] [status] 
    0f9f4f49-afc2-4139-b26b-b05a9f51ea74            windows      null         AVAILABLE
    1d16c78d-268f-47d0-be0c-b80d31e765d2            unrecognized null         AVAILABLE
    3cfd96dc-acce-4423-a095-e558f740db5c            unrecognized null         AVAILABLE
    ...<snip>        

We see that the os family is not listed properly, this is probably due
to some regex used by jclouds to guess the OS type. Unfortunately the
name key is not given.

To start an instance we can check the syntax of *jclouds node create*

    $ jclouds node create --help
    DESCRIPTION
            jclouds:node-create

        Creates a node.

    SYNTAX
            jclouds:node-create [options] group [number] 

    ARGUMENTS
            group
                    Node group.
            number
                    Number of nodes to create.
                    (defaults to 1)        

We need to define the name of a group and give the number of instance
that we want to start. Plus the hardware and image id. In terms of
hardware, we are going to use the smallest possible hardware and for image we give a uuid from the previous list.

    $ jclouds node list
    [id]                                 [location]                           [hardware]                           [group] [status]
    4e733609-4c4a-4de1-9063-6fe5800ccb10 1128bd56-b4d9-4ac6-a7b9-c715b187ce11 71004023-bb72-4a97-b1e9-bc66dfce9470 foobar  RUNNING 
    $ jclouds node info 4e733609-4c4a-4de1-9063-6fe5800ccb10
    [id]                                 [location]                           [hardware]                           [group] [status]
    4e733609-4c4a-4de1-9063-6fe5800ccb10 1128bd56-b4d9-4ac6-a7b9-c715b187ce11 71004023-bb72-4a97-b1e9-bc66dfce9470 foobar  RUNNING 

       Operating System: unrecognized null null                                      
        Configured User: root                                                        
         Public Address: 9.9.9.9                                                
        Private Address:                                                             
               Image Id: 1d16c78d-268f-47d0-be0c-b80d31e765d2    
        

With this short intro, you are well on your way to using jclouds-cli.
Check out the interactive shell, the blobstore and the chef facility to automate VM configuration. Remember that jclouds is also and actually foremost a java library that you can use to write other applications.

Apache Libcloud
===============
There are many tools available to interface with the CloudStack API, we just saw jClouds. Apache
Libcloud is another one, but this time Python based. In this section we provide a basic example of
how to use Libcloud with CloudStack. It assumes that you have access to a
CloudStack endpoint and that you have the API access key and secret key of
a user.

Installation
------------
To install Libcloud refer to the libcloud
[website](http://libcloud.apache.org). If you are familiar with Pypi
simply do:

    pip install apache-libcloud

You should see the following output:

    pip install apache-libcloud
    Downloading/unpacking apache-libcloud
    Downloading apache-libcloud-0.12.4.tar.bz2 (376kB): 376kB downloaded
    Running setup.py egg_info for package apache-libcloud
        
    Installing collected packages: apache-libcloud
    Running setup.py install for apache-libcloud
        
    Successfully installed apache-libcloud
    Cleaning up...
        
Developers will want to clone the repository, for example from the
github mirror:

    git clone https://github.com/apache/libcloud.git
        
To install libcloud from the cloned repo, simply do the following from
within the clone repository directory:

    sudo python ./setup.py install        

> **Note**
>
> The CloudStack driver is located in
> */path/to/libcloud/source/libcloud/compute/drivers/cloudstack.py*.
> file bugs on the libcloud JIRA and submit your patches as an attached
> file to the JIRA entry.

Using Libcloud
--------------
With libcloud installed either via PyPi or via the source, you can now
open a Python interactive shell, create an instance of a CloudStack driver
and call the available methods via the libcloud API.

First you need to import the libcloud modules and create a CloudStack
driver.

    >>> from libcloud.compute.types import Provider
    >>> from libcloud.compute.providers import get_driver
    >>> Driver = get_driver(Provider.CLOUDSTACK)


Then, using your keys and endpoint, create a connection object. Note
that this is a local test and thus not secured. If you use a CloudStack
public cloud, make sure to use SSL properly (i.e `secure=True`).

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
	
Keypairs and Security Groups
----------------------------
I recently added support for keypair management in libcloud. For
instance, given a conn object obtained from the previous interactive
session:

    conn.ex_list_keypairs()
    conn.ex_create_keypair(name='foobar')
    conn.ex_delete_keypair(name='foobar')        

Management of security groups was also added. Below we show how to list,
create and delete security groups. As well as add an ingree rule to open
port 22 to the world. Both keypair and security groups are key for
access to a CloudStack Basic zone like [Exoscale](http://www.exoscale.ch).

    conn.ex_list_security_groups()
    conn.ex_create_security_group(name='libcloud')
    conn.ex_authorize_security_group_ingress(securitygroupname='llibcloud',protocol='TCP',startport=22,cidrlist='0.0.0.0/0')
    conn.ex_delete_security_group('llibcloud')

Development of the CloudStack driver in Libcloud is very active, there is also support for advanced zone via calls to do SourceNAT and StaticNAT.

Multiple Clouds
---------------
One of the interesting use cases of Libcloud is that you can use
multiple Cloud Providers, such as AWS, Rackspace, OpenNebula, vCloud and
so on. You can then create Driver instances to each of these clouds and
create your own multi cloud application. In the example below we
instantiate to libcloud CloudStack driver, one on
[Exoscale](http://exoscale.ch) and the other one on
[Ikoula](http://ikoula.com).
     
    import libcloud.security as sec

    Driver = get_driver(Provider.CLOUDSTACK)

    apikey=os.getenv('EXOSCALE_API_KEY')
    secretkey=os.getenv('EXOSCALE_SECRET_KEY')
    endpoint=os.getenv('EXOSCALE_ENDPOINT')
    host=urlparse.urlparse(endpoint).netloc
    path=urlparse.urlparse(endpoint).path

    exoconn=Driver(key=apikey,secret=secretkey,secure=True,host=host,path=path)

    Driver = get_driver(Provider.CLOUDSTACK)

    apikey=os.getenv('IKOULA_API_KEY')
    secretkey=os.getenv('IKOULA_SECRET_KEY')
    endpoint=os.getenv('IKOULA_ENDPOINT')
    host=urlparse.urlparse(endpoint).netloc
    print host
    path=urlparse.urlparse(endpoint).path
    print path

    sec.VERIFY_SSL_CERT = False

    ikoulaconn=Driver(key=apikey,secret=secretkey,secure=True,host=host,path=path)

    drivers = [exoconn, ikoulaconn]

            for driver in drivers:
                print driver.list_locations()

> **Note**
>
> In the example above, I set my access and secret keys as well as the
> endpoints as environment variable. Also note the libcloud security
> module and the VERIFY\_SSL\_CERT. In the case of iKoula the SSL
> certificate used was not verifiable by the CERTS that libcloud checks.
> Especially if you use a self-signed SSL certificate for testing, you
> might have to disable this check as well.

From this basic setup you can imagine how you would write an application
that would manage instances in different Cloud Providers. Providing more
resiliency to your overall infrastructure.

Pyton Boto
==========
There are many tools available to interface with a AWS compatible API.
In this section we provide a short example that users of CloudStack can
build upon using the AWS interface to CloudStack.
Boto Examples
-------------
Boto is one of them. It is a Python package available at
https://github.com/boto/boto. In this section we provide two examples of
Python scripts that use Boto and have been tested with the CloudStack AWS
API Interface.

First is an EC2 example. Replace the Access and Secret Keys with your
own and update the endpoint.

    #!/usr/bin/env python

    import sys
    import os
    import boto
    import boto.ec2

    region = boto.ec2.regioninfo.RegionInfo(name="ROOT",endpoint="localhost")
    apikey='GwNnpUPrO6KgIdZu01z_ZhhZnKjtSdRwuYd4DvpzvFpyxGMvrzno2q05MB0ViBoFYtdqKd'
    secretkey='t4eXLEYWw7chBhDlaKf38adCMSHx_wlds6JfSx3z9fSpSOm0AbP9Moj0oGIzy2LSC8iw'

    def main():
        '''Establish connection to EC2 cloud'''
            conn =boto.connect_ec2(aws_access_key_id=apikey,
                           aws_secret_access_key=secretkey,
                           is_secure=False,
                           region=region,
                           port=7080,
                           path="/awsapi",
                           api_version="2012-08-15")

            '''Get list of images that I own'''
        images = conn.get_all_images()
        print images
        myimage = images[0]
        '''Pick an instance type'''
        vm_type='m1.small'
        reservation = myimage.run(instance_type=vm_type,security_groups=['default'])

    if __name__ == '__main__':
        main()                    

With boto you can also interact with other AWS services like S3. CloudStack has an S3 tech preview but it
is backed by a standard NFS server and therefore is not a true scalable distributed block store. To provide an S3
service in your Cloud I recommend to use other software like RiakCS, Ceph radosgw or Glusterfs S3 interface. These
systems handle large scale, chunking and replication.

Wrappers
========
In this paragraph we introduce several CloudStack *wrappers*. These tools
are using client libraries presented in the previous chapter (or their own built-in request mechanisms) and add
additional functionality that involve some high-level orchestration. For
instance *knife-cloudstack* uses the power of
[Chef](http://opscode.com), the configuration management system, to
seamlessly bootstrap instances running in a CloudStack cloud. Apache
[Whirr](http://whirr.apache.org) uses
[jclouds](http://jclouds.incubator.apache.org) to boostrap
[Hadoop](http://hadoop.apache.org) clusters in the cloud and [SaltStack](http://saltstack.com) does configuration management in the Cloud using Apache libcloud.

Knife CloudStack
=============
Knife is a command line utility for Chef, the configuration management system from OpsCode.

Install, Configure and Feel
---------------------------
The Knife family of tools are drivers that automate the provisioning and
configuration of machines in the Cloud. Knife-cloudstack is a CloudStack
plugin for knife. Written in ruby it is used by the Chef community. To
install Knife-CloudStack you can simply install the gem or get it from
github:

    gem install knife-cloudstack

If successfull the *knife* command should now be in your path. Issue
*knife* at the prompt and see the various options and sub-commands
available.

If you want to use the version on github simply clone it:

    git clone https://github.com/CloudStack-extras/knife-cloudstack.git

If you clone the git repo and do changes to the code, you will want to
build and install a new gem. As an example, in the directory where you
cloned the knife-cloudstack repo do:

    $ gem build knife-cloudstack.gemspec 
      Successfully built RubyGem
      Name: knife-cloudstack
      Version: 0.0.14
      File: knife-cloudstack-0.0.14.gem
    $ gem install knife-cloudstack-0.0.14.gem 
      Successfully installed knife-cloudstack-0.0.14
      1 gem installed
      Installing ri documentation for knife-cloudstack-0.0.14...
      Installing RDoc documentation for knife-cloudstack-0.0.14...
            
You will then need to define your CloudStack endpoint and your credentials
in a *knife.rb* file like so:

    knife[:cloudstack_url] = "http://yourcloudstackserver.com:8080/client/api
    knife[:cloudstack_api_key]  = "Your CloudStack API Key"
    knife[:cloudstack_secret_key] = "Your CloudStack Secret Key"
            
With the endpoint and credentials configured as well as knife-cloudstack
installed, you should be able to issue your first command. Remember that
this is simply sending a CloudStack API call to your CloudStack based Cloud
provider. Later in the section we will see how to do more advanced
things with knife-cloudstack. For example, to list the service offerings
(i.e instance types) available on the iKoula Cloud, do:

    $ knife cs service list
    Name           Memory  CPUs  CPU Speed  Created                 
    m1.extralarge  15GB    8     2000 Mhz   2013-05-27T16:00:11+0200
    m1.large       8GB     4     2000 Mhz   2013-05-27T15:59:30+0200
    m1.medium      4GB     2     2000 Mhz   2013-05-27T15:57:46+0200
    m1.small       2GB     1     2000 Mhz   2013-05-27T15:56:49+0200

To list all the *knife-cloudstack* commands available just enter *knife
cs* at the prompt. You will see:

    $ knife cs
    Available cs subcommands: (for details, knife SUB-COMMAND --help)

    ** CS COMMANDS **
    knife cs account list (options)
    knife cs cluster list (options)
    knife cs config list (options)
    knife cs disk list (options)
    knife cs domain list (options)
    knife cs firewallrule list (options)
    knife cs host list (options)
    knife cs hosts
    knife cs iso list (options)
    knife cs template create NAME (options)
    ...
            
> **Note**
>
> If you only have user privileges on the Cloud you are using, as
> opposed to Admin privileges, do note that some commands won't be
> available to you. For instance on the Cloud I am using where I am a
> standard user I cannot access any of the infrastructure type command
> like:
>
>     $ knife cs pod list
>     Error 432: Your account does not have the right to execute this command or the command does not exist.
>                      

Similarly to CloudMonkey, you can pass a list of fields to output. To
find the potential fields enter the *--fieldlist* option at the end of
the command. You can then pick the fields that you want to output by
passing a comma separated list to the *--fields* option like so:

    $ knife cs service list --fieldlist
    Name           Memory  CPUs  CPU Speed  Created                 
    m1.extralarge  15GB    8     2000 Mhz   2013-05-27T16:00:11+0200
    m1.large       8GB     4     2000 Mhz   2013-05-27T15:59:30+0200
    m1.medium      4GB     2     2000 Mhz   2013-05-27T15:57:46+0200
    m1.small       2GB     1     2000 Mhz   2013-05-27T15:56:49+0200

    Key          Type        Value                               
    cpunumber    Fixnum      8                                   
    cpuspeed     Fixnum      2000                                
    created      String      2013-05-27T16:00:11+0200            
    defaultuse   FalseClass  false                               
    displaytext  String      8 Cores CPU with 15.3GB RAM         
    domain       String      ROOT                                
    domainid     String      1                                   
    hosttags     String      ex10                                
    id           String      1412009f-0e89-4cfc-a681-1cda0631094b
    issystem     FalseClass  false                               
    limitcpuuse  TrueClass   true                                
    memory       Fixnum      15360                               
    name         String      m1.extralarge                       
    networkrate  Fixnum      100                                 
    offerha      FalseClass  false                               
    storagetype  String      local                               
    tags         String      ex10 

    $ knife cs service list --fields id,name,memory,cpunumber
    id                                    name           memory  cpunumber
    1412009f-0e89-4cfc-a681-1cda0631094b  m1.extralarge  15360   8        
    d2b2e7b9-4ffa-419e-9ef1-6d413f08deab  m1.large       7680    4        
    8dae8be9-5dae-4f81-89d1-b171f25ef3fd  m1.medium      3840    2        
    c6b89fea-1242-4f54-b15e-9d8ec8a0b7e8  m1.small       1740    1
            

Starting an Instance
--------------------
In order to manage instances *knife* has several commands:

-   *knife cs server list* to list all instances

-   *knife cs server start* to restart a paused instance

-   *knife cs server stop* to suspend a running instance

-   *knife cs server delete* to destroy an instance

-   *knife cs server reboot* to reboot a running instance

And of course to create an instance *knife cs server create*

Knife will automatically allocate a Public IP address and associate it
with your running instance. If you additionally pass some port forwarding
rules and firewall rules it will set those up. You need to specify an
instance type, from the list returned by *knife cs service list* as well
as a template, from the list returned by *knife cs template list*. The
*--no-boostrap* option will tell knife to not install chef on the
deployed instance. Syntax for the port forwarding and firewall rules are
explained on the [knife
cloudstack](https://github.com/CloudStack-extras/knife-cloudstack)
website. Here is an example on the [iKoula cloud](http://www.ikoula.com)
in France:

    $ knife cs server create --no-bootstrap --service m1.small --template "CentOS 6.4 - Minimal - 64bits" foobar

    Waiting for Server to be created.......
    Allocate ip address, create forwarding rules
    params: {"command"=>"associateIpAddress", "zoneId"=>"a41b82a0-78d8-4a8f-bb79-303a791bb8a7", "networkId"=>"df2288bb-26d7-4b2f-bf41-e0fae1c6d198"}.
    Allocated IP Address: 178.170.XX.XX
    ...
    Name:       foobar       
    Public IP:  178.170.XX.XX

    $ knife cs server list
    Name    Public IP      Service   Template                       State    Instance  Hypervisor
    foobar  178.170.XX.XX  m1.small  CentOS 6.4 - Minimal - 64bits  Running  N/A       N/A    
                

Bootstrapping Instances with Hosted-Chef
----------------------------------------
Knife is taking it's full potential when used to bootstrap Chef and use
it for configuration management of the instances. To get started with
Chef, the easiest is to use [Hosted
Chef](http://www.opscode.com/hosted-chef/). There is some great
documentation on
[how](https://learnchef.opscode.com/quickstart/chef-repo/) to do it. The
basic concept is that you will download or create cookbooks locally and
publish them to your own hosted Chef server.

Using Knife with Hosted-Chef
----------------------------
With your *hosted Chef* account created and your local *chef-repo*
setup, you can start instances on your Cloud and specify the *cookbooks*
to use to configure those instances. The boostrapping process will fetch
those cookbooks and configure the node. Below is an example that does
so, it uses the [exoscale](http://www.exoscale.ch) cloud which runs on
CloudStack. This cloud is enabled as a Basic zone and uses ssh keypairs
and security groups for access.

    $ knife cs server create --service Tiny --template "Linux CentOS 6.4 64-bit" --ssh-user root --identity ~/.ssh/id_rsa --run-list "recipe[apache2]" --ssh-keypair foobar --security-group www --no-public-ip foobar

    Waiting for Server to be created....
    Name:       foobar   
    Public IP:  185.19.XX.XX


    Waiting for sshd.....

    Name:         foobar13       
    Public IP:    185.19.XX.XX  
    Environment:  _default       
    Run List:     recipe[apache2]

    Bootstrapping Chef on 185.19.XX.XX  
    185.19.XX.XX  --2013-06-10 11:47:54--  http://opscode.com/chef/install.sh
    185.19.XX.XX  Resolving opscode.com... 
    185.19.XX.XX  184.ZZ.YY.YY
    185.19.XX.XX Connecting to opscode.com|184.ZZ.XX.XX|:80... 
    185.19.XX.XX connected.
    185.19.XX.XX HTTP request sent, awaiting response... 
    185.19.XX.XX 301 Moved Permanently
    185.19.XX.XX Location: http://www.opscode.com/chef/install.sh [following]
    185.19.XX.XX --2013-06-10 11:47:55--  http://www.opscode.com/chef/install.sh
    185.19.XX.XX Resolving www.opscode.com... 
    185.19.XX.XX 184.ZZ.YY.YY
    185.19.XX.XX Reusing existing connection to opscode.com:80.
    185.19.XX.XX HTTP request sent, awaiting response... 
    185.19.XX.XX 200 OK
    185.19.XX.XX Length: 6509 (6.4K) [application/x-sh]
    185.19.XX.XX Saving to: “STDOUT”
    185.19.XX.XX 
     0% [                                       ] 0           --.-K/s              
    100%[======================================>] 6,509       --.-K/s   in 0.1s    
    185.19.XX.XX 
    185.19.XX.XX 2013-06-10 11:47:55 (60.8 KB/s) - written to stdout [6509/6509]
    185.19.XX.XX 
    185.19.XX.XX Downloading Chef 11.4.4 for el...
    185.19.XX.XX Installing Chef 11.4.4
                

Chef will then configure the machine based on the cookbook passed in the
--run-list option, here I setup a simple webserver. Note the keypair
that I used and the security group. I also specify *--no-public-ip*
which disables the IP address allocation and association. This is
specific to the setup of *exoscale* which automatically uses a public IP
address for the instances.

> **Note**
>
> The latest version of knife-cloudstack allows you to manage keypairs
> and securitygroups. For instance listing, creation and deletion of
> keypairs is possible, as well as listing of securitygroups:
>
>     $ knife cs securitygroup list
>     Name     Description             Account         
>     default  Default Security Group  runseb@gmail.com
>     www      apache server           runseb@gmail.com
>     $ knife cs keypair list
>     Name      Fingerprint                                    
>     exoscale  xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
>                     

When using a CloudStack based cloud in an Advanced zone setting, *knife*
can automatically allocate and associate an IP address. To illustrate
this slightly different example I use [iKoula](http://www.ikoula.com) a
french Cloud Provider which uses CloudStack. I edit my *knife.rb* file to
setup a different endpoint and the different API and secret keys. I
remove the keypair, security group and public ip option and I do not
specify an identity file as I will retrieve the ssh password with the
*--cloudstack-password* option. The example is as follows:

    $ knife cs server create --service m1.small --template "CentOS 6.4 - Minimal - 64bits" --ssh-user root --cloudstack-password --run-list "recipe[apache2]" foobar

    Waiting for Server to be created........
    Allocate ip address, create forwarding rules
    params: {"command"=>"associateIpAddress", "zoneId"=>"a41b82a0-78d8-4a8f-bb79-303a791bb8a7", "networkId"=>"df2288bb-26d7-4b2f-bf41-e0fae1c6d198"}.
    Allocated IP Address: 178.170.71.148
    ...
    Name:       foobar       
    Password:   $%@#$%#$%#$     
    Public IP:  178.xx.yy.zz


    Waiting for sshd......

    Name:         foobar     
    Public IP:    178.xx.yy.zz 
    Environment:  _default       
    Run List:     recipe[apache2]

    Bootstrapping Chef on 178.xx.yy.zz
    178.xx.yy.zz --2013-06-10 13:24:29--  http://opscode.com/chef/install.sh
    178.xx.yy.zz Resolving opscode.com...
                

> **Warning**
>
> You will want to review the security implications of doing the
> boostrap as root and using the default password to do so.
>
> In Advanced Zone, your cloud provider may also have decided to block
> all egress traffic to the public internet, which means that contacting
> the hosted Chef server would fail. To configure the egress rules
> properly, CloudMonkey can be used. List the networks to find the id of
> your guest network, then create an egress firewall rule. Review the
> CloudMonkey section to find the proper API calls and their arguments.
>
>     > list networks filter=id,name,netmask
>     count = 1
>     network:
>     +--------------------------------------+------+---------------+
>     |                  id                  | name |    netmask    |
>     +--------------------------------------+------+---------------+
>     | df2288bb-26d7-4b2f-bf41-e0fae1c6d198 | test | 255.255.255.0 |
>     +--------------------------------------+------+---------------+
>
>     > create egressfirewallrule networkid=df2288bb-26d7-4b2f-bf41-e0fae1c6d198 startport=80 endport=80 protocol=TCP cidrlist=10.1.1.0/24
>     id = b775f1cb-a0b3-4977-90b0-643b01198367
>     jobid = 8a5b735c-6aab-45f8-b687-0a1150a66e0f
>
>     > list egressfirewallrules
>     count = 1
>     firewallrule:
>     +-----------+-----------+---------+------+-------------+--------+----------+--------------------------------------+
>     | networkid | startport | endport | tags |   cidrlist  | state  | protocol |                  id                  |
>     +-----------+-----------+---------+------+-------------+--------+----------+--------------------------------------+
>     |    326    |     80    |    80   |  []  | 10.1.1.0/24 | Active |   tcp    | baf8d072-7814-4b75-bc8e-a47bfc306eb1 |
>     +-----------+-----------+---------+------+-------------+--------+----------+--------------------------------------+
>
>                     

Salt
====
[Salt](http://saltstack.com) is a configuration management system
written in Python. It can be seen as an alternative to Chef and Puppet.
Its concept is similar with a master node holding states called *salt
states (SLS)* and minions that get their configuration from the master.
A nice difference with Chef and Puppet is that Salt is also a remote
execution engine and can be used to execute commands on the minions by
specifying a set of targets. In this chapter we dive straight
into [SaltCloud](http://saltcloud.org), an open source software to
provision *Salt* masters and minions in the Cloud. *SaltCloud* can be
looked at as an alternative to *knife-cs* but certainly with less
functionality. In this short walkthrough we intend to boostrap a Salt master (equivalent to a Chef server) in the cloud and then add minions that will get their configuration from the master.

SaltCloud installation and usage.
---------------------------------
To install Saltcloud one simply clones the git repository. To develop
Saltcloud, just fork it on github and clone your fork, then commit
patches and submit pull request. SaltCloud depends on libcloud,
therefore you will need libcloud installed as well. See the previous
chapter to setup libcloud. With Saltcloud installed and in your path,
you need to define a Cloud provider in *\~/.saltcloud/cloud*. For
example:
        
    providers:
      exoscale:
        apikey: <your api key> 
        secretkey: <your secret key>
        host: api.exoscale.ch
        path: /compute
        securitygroup: default
        user: root
        private_key: ~/.ssh/id_rsa
        provider: cloudstack
        
The apikey, secretkey, host, path and provider keys are mandatory. The
securitygroup key will specify which security group to use when starting
the instances in that cloud. The user will be the username used to
connect to the instances via ssh and the private\_key is the ssh key to
use. Note that the optional parameter are specific to the Cloud that
this was tested on. Cloud in advanced zones especially will need a
different setup.

> Warning
>
> Saltcloud used libcloud. Support for advanced zones in libcloud is
> still experimental, therefore using SaltCloud in advanced zone will
> likely need some development of libcloud.

Once a provider is defined, we can start using saltcloud to list the
zones, the service offerings and the templates available on that cloud
provider. So far nothing more than what libcloud provides. For example:

    #salt-cloud –list-locations exoscale
	[INFO    ] salt-cloud starting
	exoscale:
	    ----------
	    cloudstack:
	        ----------
	        CH-GV2:
	            ----------
	            country:
	                AU
	            driver:
	            id:
	                1128bd56-b4d9-4ac6-a7b9-c715b187ce11
	            name:
	                CH-GV2
    #salt-cloud –list-images exoscale
    #salt-cloud –list-sizes exoscale
            
To start creating instances and configuring them with Salt, we need to
define node profiles in *\~/.saltcloud/config*. To illustrate two
different profiles we show a Salt Master and a Minion. The Master would
need a specific template (image:uuid), a service offering or instance
type (size:uuid). In a basic zone with keypair access and security
groups, one would also need to specify which keypair to use, where to
listen for ssh connections and of course you would need to define the
provider (e.g exoscale in our case, defined above). Below if the node
profile for a Salt Master deployed in the Cloud:
        
    ubuntu-exoscale-master:
        provider: exoscale
        image: 1d16c78d-268f-47d0-be0c-b80d31e765d2 
        size: b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8 
        ssh_interface: public
        ssh_username: root
        keypair: exoscale
        make_master: True
        master:
           user: root
           interface: 0.0.0.0
        
The master key shows which user to use and what interface, the
make\_master key if set to true will boostrap this node as a Salt
Master. To create it on our cloud provider simply enter:

    $salt-cloud –p ubuntu-exoscale-master mymaster
            
Where *mymaster* is going to be the instance name. To create a minion,
add a minion node profile in the config file:
        
    ubuntu-exoscale-minion:
        provider: exoscale
        image: 1d16c78d-268f-47d0-be0c-b80d31e765d2
        size: b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8
        ssh_interface: public
        ssh_username: root
        keypair: exoscale
	    minion:
	      master: W.X.Y.Z
        
you would then start it with:

    $salt-cloud –p ubuntu-exoscale-minion myminion
            
The W.X.Y.Z IP address above should be the IP address of the master that was deployed previously. On the master you will need to have port 4505 and 4506 opened, this is best done in basic zone using security groups. Once this security group is properly setup the minions will be able to contact the master. You will then accept the keys from the minion and be able to talk to them from your Salt master.

    root@mymaster11:~# salt-key -L
    Accepted Keys:
    minion001
    minion002
    Unaccepted Keys:
    minion003
    Rejected Keys:
    root@mymaster11:~# salt-key -A
    The following keys are going to be accepted:
    Unaccepted Keys:
    minion003
    Proceed? [n/Y] Y
    Key for minion minion003 accepted.
    root@mymaster11:~# salt '*' test.ping
    minion002:
       True
    minion001:
       True
    root@mymaster11:~# salt '*' test.ping
    minion003:
        True
    minion002:
        True
    minion001:
        True

Apache Whirr
============
[Apache Whirr](http://whirr.apache.org) is a set of libraries to run
cloud services, internally it uses
[jclouds](http://jclouds.incubator.apache.org) that we introduced
earlier via the jclouds-cli interface to CloudStack, it is java based and
of interest to provision clusters of virtual machines on cloud
providers. Historically it started as a set of scripts to deploy
[Hadoop](http://hadoop.apache.org) clusters on Amazon EC2. We introduce
Whirr has a potential CloudStack tool to provision Hadoop cluster on
CloudStack based clouds.

Installing Apache Whirr
-----------------------
To install Whirr you can follow the [Quick Start
Guide](http://whirr.apache.org/docs/0.8.1/quick-start-guide.html),
download a tarball or clone the git repository. In the spirit of this
document we clone the repo:

    git clone git://git.apache.org/whirr.git
            
And build the source with maven that we now know and love...:

    mvn install        
            
The whirr binary will be available in the *bin* directory that we can
add to our path

    export PATH=$PATH:/Users/sebgoa/Documents/whirr/bin
            
If all went well you should now be able to get the usage of *whirr*:

    $ whirr --help
    Unrecognized command '--help'

    Usage: whirr COMMAND [ARGS]
    where COMMAND may be one of:

      launch-cluster  Launch a new cluster running a service.
      start-services  Start the cluster services.
       stop-services  Stop the cluster services.
    restart-services  Restart the cluster services.
     destroy-cluster  Terminate and cleanup resources for a running cluster.
    destroy-instance  Terminate and cleanup resources for a single instance.
        list-cluster  List the nodes in a cluster.
      list-providers  Show a list of the supported providers
          run-script  Run a script on a specific instance or a group of instances matching a role name
             version  Print the version number and exit.
                help  Show help about an action

    Available roles for instances:
      cassandra
      elasticsearch
      ganglia-metad
      ganglia-monitor
      hadoop-datanode
      ...

From the look of the usage you clearly see that *whirr* is about more
than just *hadoop* and that it can be used to configure *elasticsearch*
clusters, *cassandra* databases as well as the entire *hadoop* ecosystem
with *mahout*, *pig*, *hbase*, *hama*, *mapreduce* and *yarn*.

Using Apache Whirr
------------------
To get started with Whirr you need to setup the credentials and endpoint
of your CloudStack based cloud that you will be using. Edit the
*\~/.whirr/credentials* file to include a PROVIDER, IDENTITY, CREDENTIAL
and ENDPOINT. The PROVIDER needs to be set to *cloudstack*, the IDENTITY
is your API key, the CREDENTIAL is your secret key and the ENDPPOINT is
the endpoint url. For instance:

    PROVIDER=cloudstack
    IDENTITY=mnH5EbKc4534592347523486724389673248AZW4kYV5gdsfgdfsgdsfg87sdfohrjktn5Q
    CREDENTIAL=Hv97W58iby5PWL1ylC4oJls46456435634564537sdfgdfhrteydfg87sdf89gysdfjhlicg
    ENDPOINT=https://api.exoscale.ch/compute

With the credentials and endpoint defined you can create a *properties*
file that describes the cluster you want to launch on your cloud. The
file contains information such as the cluster name, the number of
instances and their type, the distribution of hadoop you want to use,
the service offering id and the template id of the instances. It also
defines the ssh keys to be used for accessing the virtual machines. In
the case of a cloud that uses security groups, you may also need to
specify it. A tricky point is the handling of DNS name resolution. You
might have to use the *whirr.store-cluster-in-etc-hosts* key to bypass
any DNS issues. For a full description of the whirr property keys, see
the
[documentation](http://whirr.apache.org/docs/0.8.1/configuration-guide.html).

    $ more whirr.properties 

    #
    # Setup an Apache Hadoop Cluster
    # 

    # Change the cluster name here
    whirr.cluster-name=hadoop

    whirr.store-cluster-in-etc-hosts=true

    whirr.use-cloudstack-security-group=true

    # Change the name of cluster admin user
    whirr.cluster-user=${sys:user.name}

    # Change the number of machines in the cluster here
    whirr.instance-templates=1 hadoop-namenode+hadoop-jobtracker,3 hadoop-datanode+hadoop-tasktracker

    # Uncomment out the following two lines to run CDH
    whirr.env.repo=cdh4
    whirr.hadoop.install-function=install_cdh_hadoop
    whirr.hadoop.configure-function=configure_cdh_hadoop

    whirr.hardware-id=b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8

    whirr.private-key-file=/path/to/ssh/key/
    whirr.public-key-file=/path/to/ssh/public/key/

    whirr.provider=cloudstack
    whirr.endpoint=https://the/endpoint/url
    whirr.image-id=1d16c78d-268f-47d0-be0c-b80d31e765d2
            

> **Warning**
>
> The example shown above is specific to a CloudStackion
> [Cloud](http://exoscale.ch) setup as a basic zone. This cloud uses
> security groups for isolation between instances. The proper rules had
> to be setup by hand. Also note the use of
> *whirr.store-cluster-in-etc-hosts*. If set to true whirr will edit the
> */etc/hosts* file of the nodes and enter the IP adresses. This is
> handy in the case where DNS resolution is problematic.

> **Note**
>
> To use the Cloudera Hadoop distribution (CDH) like in the example
> above, you will need to copy the
> *services/cdh/src/main/resources/functions* directory to the root of
> your Whirr source. In this directory you will find the bash scripts
> used to bootstrap the instances. It may be handy to edit those
> scripts.

You are now ready to launch an hadoop cluster:

    $ whirr launch-cluster --config hadoop.properties 
    Running on provider cloudstack using identity mnH5EbKcKeJd456456345634563456345654634563456345
    Bootstrapping cluster
    Configuring template for bootstrap-hadoop-datanode_hadoop-tasktracker
    Configuring template for bootstrap-hadoop-namenode_hadoop-jobtracker
    Starting 3 node(s) with roles [hadoop-datanode, hadoop-tasktracker]
    Starting 1 node(s) with roles [hadoop-namenode, hadoop-jobtracker]
    >> running InitScript{INSTANCE_NAME=bootstrap-hadoop-datanode_hadoop-tasktracker} on node(b9457a87-5890-4b6f-9cf3-1ebd1581f725)
    >> running InitScript{INSTANCE_NAME=bootstrap-hadoop-datanode_hadoop-tasktracker} on node(9d5c46f8-003d-4368-aabf-9402af7f8321)
    >> running InitScript{INSTANCE_NAME=bootstrap-hadoop-datanode_hadoop-tasktracker} on node(6727950e-ea43-488d-8d5a-6f3ef3018b0f)
    >> running InitScript{INSTANCE_NAME=bootstrap-hadoop-namenode_hadoop-jobtracker} on node(6a643851-2034-4e82-b735-2de3f125c437)
    << success executing InitScript{INSTANCE_NAME=bootstrap-hadoop-datanode_hadoop-tasktracker} on node(b9457a87-5890-4b6f-9cf3-1ebd1581f725): {output=This function does nothing. It just needs to exist so Statements.call("retry_helpers") doesn't call something which doesn't exist
    Get:1 http://security.ubuntu.com precise-security Release.gpg [198 B]
    Get:2 http://security.ubuntu.com precise-security Release [49.6 kB]
    Hit http://ch.archive.ubuntu.com precise Release.gpg
    Get:3 http://ch.archive.ubuntu.com precise-updates Release.gpg [198 B]
    Get:4 http://ch.archive.ubuntu.com precise-backports Release.gpg [198 B]
    Hit http://ch.archive.ubuntu.com precise Release
    ..../snip/.....
    You can log into instances using the following ssh commands:
    [hadoop-datanode+hadoop-tasktracker]: ssh -i /Users/sebastiengoasguen/.ssh/id_rsa -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no sebastiengoasguen@185.xx.yy.zz
    [hadoop-datanode+hadoop-tasktracker]: ssh -i /Users/sebastiengoasguen/.ssh/id_rsa -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no sebastiengoasguen@185.zz.zz.rr
    [hadoop-datanode+hadoop-tasktracker]: ssh -i /Users/sebastiengoasguen/.ssh/id_rsa -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no sebastiengoasguen@185.tt.yy.uu
    [hadoop-namenode+hadoop-jobtracker]: ssh -i /Users/sebastiengoasguen/.ssh/id_rsa -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no sebastiengoasguen@185.ii.oo.pp
    To destroy cluster, run 'whirr destroy-cluster' with the same options used to launch it.
            

After the boostrapping process finishes, you should be able to login to
your instances and use *hadoop* or if you are running a proxy on your
machine, you will be able to access your hadoop cluster locally. Testing
of Whirr for CloudStack is still under
[investigation](https://issues.apache.org/jira/browse/WHIRR-725) and the
subject of a Google Summer of Code 2013 project. We currently identified
issues with the use of security groups. Moreover this was tested on a
basic zone. Complete testing on an advanced zone is future work.

Running Map-Reduce jobs on Hadoop
---------------------------------
Whirr gives you the ssh command to connect to the instances of your
hadoop cluster, login to the namenode and browse the hadoop file system
that was created:

    $ hadoop fs -ls /
    Found 5 items
    drwxrwxrwx   - hdfs supergroup          0 2013-06-21 20:11 /hadoop
    drwxrwxrwx   - hdfs supergroup          0 2013-06-21 20:10 /hbase
    drwxrwxrwx   - hdfs supergroup          0 2013-06-21 20:10 /mnt
    drwxrwxrwx   - hdfs supergroup          0 2013-06-21 20:11 /tmp
    drwxrwxrwx   - hdfs supergroup          0 2013-06-21 20:11 /user            

Create a directory to put your input data

    $ hadoop fs -mkdir input
    $ hadoop fs -ls /user/sebastiengoasguen
    Found 1 items
    drwxr-xr-x   - sebastiengoasguen supergroup          0 2013-06-21 20:15 /user/sebastiengoasguen/input            

Create a test input file and put in the hadoop file system:

    $ cat foobar 
    this is a test to count the words
    $ hadoop fs -put ./foobar input
    $ hadoop fs -ls /user/sebastiengoasguen/input
    Found 1 items
    -rw-r--r--   3 sebastiengoasguen supergroup         34 2013-06-21 20:17 /user/sebastiengoasguen/input/foobar            

Define the map-reduce environment. Note that this default Cloudera
distribution installation uses MRv1. To use Yarn one would have to edit
the hadoop.properties file.

    $ export HADOOP_MAPRED_HOME=/usr/lib/hadoop-0.20-mapreduce            

Start the map-reduce job:

                $ hadoop jar $HADOOP_MAPRED_HOME/hadoop-examples.jar wordcount input output
                13/06/21 20:19:59 WARN mapred.JobClient: Use GenericOptionsParser for parsing the arguments. Applications should implement Tool for the same.
                13/06/21 20:20:00 INFO input.FileInputFormat: Total input paths to process : 1
                13/06/21 20:20:00 INFO mapred.JobClient: Running job: job_201306212011_0001
                13/06/21 20:20:01 INFO mapred.JobClient:  map 0% reduce 0%
                13/06/21 20:20:11 INFO mapred.JobClient:  map 100% reduce 0%
                13/06/21 20:20:17 INFO mapred.JobClient:  map 100% reduce 33%
                13/06/21 20:20:18 INFO mapred.JobClient:  map 100% reduce 100%
                13/06/21 20:20:21 INFO mapred.JobClient: Job complete: job_201306212011_0001
                13/06/21 20:20:22 INFO mapred.JobClient: Counters: 32
                13/06/21 20:20:22 INFO mapred.JobClient:   File System Counters
                13/06/21 20:20:22 INFO mapred.JobClient:     FILE: Number of bytes read=133
                13/06/21 20:20:22 INFO mapred.JobClient:     FILE: Number of bytes written=766347
                ...           

And you can finally check the output:

    $ hadoop fs -cat output/part-* | head
    this    1
    to      1
    the     1
    a       1
    count   1
    is      1
    test    1
    words   1
            
Conclusions
===========
The CloudStack API is very rich and easy to use. You can write your own client by following the section on how to sign requests, or you can use an existing client in the language of your choice. Well known libraries developed by the community work well with CloudStack, such as Apache libcloud and Apache jclouds. Configuration management systems also have plugins to work transparently with CloudStack, in this little book we presented SaltStack and Knife-cs. Finally, going a bit beyond simple clients we presented Apache Whirr that allows you to create Hadoop clusters on-demand (e.g elasticsearch, cassandra also work). Take your pick and write your applications on top of CloudStack using one of those tools. Based on these tools you will be able to deploy infrastructure easily, quickly and in a reproducible manner. Lately CloudStack has seen the number of tools grow, just today I learned about a Fluentd plugin and last week a Cloudfoundry BOSH interface was released. I also committed a straightforward dynamic inventory script for Ansible and a tweet just flew by about a vagrant-cloudstack plugin. The list goes on, pick what suits you and answers your need, then have fun.