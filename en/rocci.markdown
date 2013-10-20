OCCI support in CloudStack
==========================

CloudStack has its own API. Cloud wrappers like libcloud and jclouds work well with this native API, but CloudStack does not expose any standard API like OCCI and CIMI. We started working on a CloudStack backend for rOCCI using our CloudStack ruby gem. The choice of rOCCI was made due to the existence of an Opennebula backend. This is still work in progress and any contributions is welcome.

Install the rOCCI client
========================

rOCCI-cli [website](https://github.com/gwdg/rOCCI-cli)

git clone https://github.com/gwdg/rOCCI-cli.git

    cd rOCCI-cli
    gem install bundler
    bundle install
    bundle exec rake test
    rake install

You will then be able to use the OCCI client:

    occi --help

Install rOCCI server
====================

rOCCI-server [website](https://github.com/gwdg/rOCCI-server)

    git clone https://github.com/isaacchiang/rOCCI-server.git
    bundle install
    cd etc/backend
    cp cloudstack/cloudstack.json default.json

Edit the defautl.json file to contain the information about your CloudStack cloud.
Start the rOCCI server:

    bundle exec passenger start

The server should be running on http://0.0.0.0:3000

Try to run the tests:
	
	 bundle exec rspec

Testing the OCCI client against the server
==========================================

You will need a running CloudStack cloud. Either a production one or a dev instance using DevCloud. The credentials and the endpoint to this cloud will have been entered in `default.json` file that you created in the previous section.

Try a couple OCCI client command:

    $ occi --endpoint http://0.0.0.0:3000/ --action list --resource os_tpl

    Os_tpl locations:
	    os_tpl#6673855d-ce9b-4997-8613-6830de037a8f

    $ occi --endpoint http://0.0.0.0:3000/ --action list --resource resource_tpl

    Resource_tpl locations:
	    resource_tpl##08ba0343-bd39-4bf0-9aab-4953694ae2b4
	    resource_tpl##f78769bd-95ea-4139-ad9b-9dfc1c5cb673
	    resource_tpl##0fd364a9-7e33-4375-9e10-bb861f7c6ee7
		
You will recognize the `uuid` from the templates and service offerings that you have created in CloudStack. To start an instance:

    $ occi --endpoint http://0.0.0.0:3000/ --action create --resource compute --mixin os_tpl#6673855d-ce9b-4997-8613-6830de037a8f --mixin resource_tpl#08ba0343-bd39-4bf0-9aab-4953694ae2b4 --attributes title="My OCCI VM"

