## Name goes here. Come up with a goog one :]

This Chef repository which builds on top of [intercity/chef-repo](https://github.com/intercity/chef-repo) will help you configure your own Rails server to host one or more Ruby on Rails applications using best practices from our community. All you need for that is access to the host and a little bit of patience.

### Features  
  
The listed services/softwares will be automatically installed and configured.

* nginx webserver
* Passenger or Unicorn for running Ruby on Rails
* Database creation and password generation
* Easy SSL configuration
* Configure fail2ban
* Easy configuration of iptables
* Server monitoring with Newrelic
* Deployment with Capistrano
* Configure ENV variables

After a successful run, you will have a decent production ready server up and running.

### Operating Systems  
* Ubuntu 12.04/14.04 recommended

### Databases Supported
* MySQL
* PostgreSQL

*Note* : PostgreSQL is configured to have hstore extension enabled.

## Getting Started 

The following steps wil guide you to set up your own appplication server.

### 1. Set up this repository

Clone this repository to your workstation.

```
mkdir chef-repo
git clone git@github.com:multunus/chef-repo.git chef-repo
```
Create a new gemset if you feel like, then 

```
bundle install 
```

### 2. Set up server for Chef.

Run the following command. This will install Chef on the remote machine and will prepare the server for installation of our cookbooks

```
bundle exec knife solo prepare <your user>@<your host/ip>
```

This command will also generate a file `node/<your host/ip>.json`. Copy the contents of `node/sample_json.json` to this file. 

### 3. Generate ssh-keys
Lets generate ssh keys for this remote host, if you already have this, skip this step

* Please follow this [tutorial by github](https://help.github.com/articles/generating-ssh-keys). 
* Copy the public key into the array under `ssh_deploy_keys` in `<your host/ip>.json`
* This key will be copied over to the remote servers ~/.ssh/authorised_keys file.

### 4. Cook your server with Chef

Replace the values between `<>` with the corresponding values. For more details about the configurations, take a look at **Available Configurations** section.  
Run:
```
bundle exec knife solo cook <your user>@<your host/ip>
```

This will install all that you have specified in the `<your host/ip>.json` file. Once Chef has completed, you need to deploy your application code. 

### 5. Deployment

We have chosen [Capistrano](http://capistranorb.com/) as our deployment tool.
Navgate to your Rails applications folder.  
  
  In Gemfile add: 
```
gem 'capistrano', '~> 3.2.1'
gem 'capistrano-rails', '~> 1.1'
```
Run:
```
$ bundle install
```

Capify: make sure there's no "Capfile" or "capfile" present:

```
$ bundle exec cap install
```

Capify will generate the following files in your directory:  
```
Capfile
config/deploy.rb
config/deploy/production.rb
config/deploy/staging.rb
```

Replace the contents of `Capfile` with:

```
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/rails'

Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
```

Then edit `config/deploy.rb`, replace the contents with:

```
set :application, '<application_name>'
set :deploy_user, '<user you have added to sudoers group in node json file>'

set :deploy_to, "~/#{fetch(:application)}"

set :ssh_options, {
  keys: "path to authorised key",
  forward_agent: true,
  port: <port to be used for deployment.>
}

set :scm, :git
set :repo_url, '<git_repository_url>'
set :branch, "master"
set :pty, true

set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

set :default_env, { path: "/opt/rbenv/shims:$PATH" }
set :keep_releases, 5
namespace :deploy do

  before  'assets:precompile', 'migrate'

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
       execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
  after 'deploy:publishing', 'deploy:restart'
end

```

Replace the contents of `config/deploy/production.rb` with:
```
server '<your server address>', user: 'deploy', roles: %w{web app db}
```
### 7. Creating ssl certificates
  
  If you have already bought SSL certificates, do 
*   Copy the contents of `crt` and `key` file into `templates/default/ app_cert.crt.erb` and  `templates/default/app_cert.key.erb` under `vendor/cookbook/rails`.
*   These will be copied to remote server and configured to be used with nginx.

If you want to go with self-signed certificate, you can find a fantastic [how-to](https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04) written by Etel Sverdlov of DigitalOcean.


### 8. Available Configurations
These are the main configuration options available under `<your host/ip>.json`.
#### run_list
This expects an array of roles or recipes which defines all of the configuration settings that are necessary for a node(machine) that is under management by Chef. The recipes are run in the same order they are added under `run_list`
```
    {
      "run_list" : [
        "role[postgresql]"
        "recipe[newrelic]"
      ]
    }

```
#### authorization
Adding a user under this adds the user to sudoers group.

#### newrelic
Depends on [escapestudios-cookbooks/newrelic](https://github.com/escapestudios-cookbooks/newrelic) and is added to Cheffile. Just adding the **license** setsup newrelic with minimal configurations. For advanced settings refer the above given repository.

#### fail2ban
Depends on [opscode-cookbooks/fail2ban](https://github.com/opscode-cookbooks/fail2ban). Any of the default values given in the above cookbook under default attributes can be overridden by adding it into `fail2ban` key under node json file.

#### iptables
Depends on [wk8/cookbook-diptables](https://github.com/wk8/cookbook-diptables). As mentioned in node json, please refer vendor/cookbooks/iptables/recipes/default.rb

#### sshd
Depends on [chr4-cookbooks/sshd](https://github.com/chr4-cookbooks/sshd). Any configurations under **/etc/ssh/sshd_config** can be overridden by adding it under `sshd[:sshd_config]`.

```
    {
        "sshd":{
            "sshd_config"{
                "Port" : 56987
            }
        }
    }
```
Here it overrides default ssh port 22 with 56987.
#### active_applications
Applications that needs to be started under a host.

### 9. When you run into troubles.
Feel free to **raise an issue**. In an ideal scenario this will help you set up your Rails infrastructure in under 15 minutes. But as always, [*anything that can go wrong, will go wrong*](http://en.wikipedia.org/wiki/Murphy's_law)  
:)
