# Mystro Server

## Getting Started

### Requirements

The Getting Started guides expect that you have the following already configured and working on your system:

* gcc compiler
* ruby installation (1.9.3+) - for ruby I recommend rvm or chruby
* git
* Redis
* MongoDB

On Mac OSX, this is pretty simple.

* install Xcode
* install command line tools through Xcode
* install brew
* install rvm

* rvm install 1.9.3
* brew install git
* brew install redis-server
* brew install mongodb

### Development Environment

A quick recipe on how to get a Mystro development environment configured.

Create a directory to store the code
```
mkdir mystro && cd mystro
```

Clone this and other Mystro repositories
```
git clone https://github.com/mystro/server.git -b develop
git clone https://github.com/mystro/common.git -b develop
git clone https://github.com/mystro/config.git
```

Create an account for Mystro with your cloud provider.
For AWS, I recommend creating an account called _mystro and giving it admin priviledges.

Add the cloud provider access details into the configuration.
Edit the file common/mystro/config.yml
```
# connection defaults
connect:
  fog:
    provider: AWS
    aws_access_key_id: AKIAXXXXXXXXXXXXXXXX
    aws_secret_access_key: key hash
```

This would be a good time to add any other resource configurations as well. You can add them
to the common/mystro/config.yml file and they will be the default for all mystro accounts.

The defaults for compute are typical for using Mystro with AWS.

You will need to add your domain to the DNS configuration
```
dns:
  domain: sub.domain.com
```

Run the mystro:config rake task to link the configuration data into the rails app directory.
These links exist to keep the company specific and sensitive data out of the source repository.
```
cd server
rake mystro:config[../config]
```

Now, you'll want setup the local database, this requires that you have MongoDB and Redis installed
```rake mystro:setup```

### Server configuration

Quick recipe on getting server setup for deployment

The mystro:bootstrap rake task will instantiate a server with your cloud provider.
This task uses Mystro and Fog to create an instance, inject Userdata information
and install the required packages.
```
rake mystro:bootstrap:server
```

It can take up to 15 minutes for the server to be ready. The bootstrap task will output
connection information for you, so that you can connect to the server.

Once the server is ready, you will need to update the Capistrano configuration files with
the server's host information. Generally, you will also want to create an DNS cname to point
to the EC2 host that is created. If you have Mystro configured with a DNS provider (Route 53, Zerigo, etc)
it will automatically create a DNS record for you.

Edit the config/deploy/stages/production.rb file (this file is part of the mystro config repo)
```
server "mystro.domain.com", :web, :app, :db, :primary => true
```

Change 'mystro.domain.com' to the dns name of the new server that was created during bootstrap.

Also, change this value in the config/webserver/webserver.conf file
```
...
    ServerName mystro.domain.com
    ServerAlias ec2-xxx-xxx-xxx-xxx.compute-1.amazonaws.com
...
```

Now you can deploy the application
*** Make sure you have changed the webserver configuration
```
cap mystro:bootstrap
```

The 'mystro:bootstrap' capistrano task runs the following:
```
# cap mystro:directories # ensure proper directories are created
# cap deploy:setup       # setup deploy directories
# cap deploy:cold        # do a first time deploy
# cap foreman:export     # create upstart scripts
# cap foreman:restart    # start mystro services
# cap mystro:reset       # configure database
```

Once this is complete, you should be able to browse http://mystro.domain.com/
The default user is 'admin@localhost.com' and password is 't0wn3end'

## Using Chef?

Similarly to the mystro:bootstrap:server command, there is a simplified process for building a chef server.

First you will need to create a security group in AWS for the chef server.
Create a group called 'chefserver' and add the following:
Port | Source
--- | ---
22 | 0.0.0.0/0
80 | 0.0.0.0/0
443 | 0.0.0.0/0
4000 | 0.0.0.0/0
4040 | 0.0.0.0/0

Once this is complete, run the following task. Make sure that you set the correct security group.
```
rake mystro:bootstrap:chef

...
Groups (comma separated): |default| chefserver
...
```

Once the server is up and running, you may need to edit the configuration to fix dns.
If chef is detecting the wrong FQDN for your server, try the following:

First, fix the hostname on the server (this is for ubuntu)
```
hostname "chef.domain.com"
echo "chef.domain.com" | sudo tee /etc/hostname
echo -e "127.0.0.1 `hostname` `hostname -s`" | sudo tee -a /etc/hosts
```

Once you've done this, you can try rerunning the chef configuration tool:
```sudo chef-server-ctl reconfigure```

If that doesn't help, you can also do the following, this will force the settings into chef:
```
# /etc/chef-server/chef-server.rb
lb['api_fqdn'] = "chef.domain.com"
lb['web_ui_fqdn'] = "chef.domain.com"
nginx['url'] = "https://chef.domain.com"
nginx['server_name'] = "chef.domain.com"
```

Then reconfigure again:
```sudo chef-server-ctl reconfigure```

## Documentation and Support

This is the only documentation.

## Issues

Lorem ipsum dolor sit amet, consectetur adipiscing elit.

## Similar Projects

Lorem ipsum dolor sit amet, consectetur adipiscing elit.

## Contributing

If you make improvements to this application, please share with others.

* Fork the project on GitHub.
* git clone git@github.com:your/fork
* git checkout -b feature_branch_name
* Make your feature addition or bug fix.
* Commit with Git.
* Send a pull request.

If you add functionality to this application, create an alternative implementation, or build an application that is similar, please contact me and I'll add a note to the README so that others can find your work.

## Credits

Shawn Catanzarite - @shawncatz
INQ Mobile - for allowing me to work on this as part of my day job ;)
RealGravity - for allowing me to work on this as part of my day job ;) ;)

## License

see LICENSE.md