### Chef Playbook 


Integrating Chef to your project.

#####Assumptions:
* Your server ip address is : *IPADDRESS*

######Option 1 (The easy way) :

1. Clone chef-repo from [multunus/chef-repo](https://github.com/multunus/chef-repo) into your project.

2. Remove any traces of git from this directory by doing [rm -rf .git](http://stackoverflow.com/questions/3212459/is-there-a-command-to-undo-git-init)

3. Check in the directory into parent projects version control.

######Option 2 (The hard way) :

1. Clone chef-repo as a git submodule.

2. Write scripts to copy in:

    1. *IPADDRESS.json *

    2. *SSL Certificates*

every time chef-solo is invoked (remove these files once this is done).

###General Steps

####Get a server

1. While getting a server from any vendor, make sure to[ set it up with pem file access](http://serverfault.com/questions/546033/how-do-i-set-up-a-pem-login-for-my-servers), for a detailed how-to, head over to *["How will I set up ssh-access for my server*"](http://www.beginninglinux.com/home/server-administration/openssh-keys-certificates-authentication-pem-pub-crt)

2. While getting a server from amazon, make sure to open default port 22 in amazon firewall. (The firewall restricts inbound traffic. Even if you did set up your server, unless you open port 80, you wont be able to see your server in action.). For a detailed how to, head over to *["How do i authorize inbound traffic in aws-ec2*"](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/authorizing-access-to-an-instance.html)

Now we have got a server with ip *IPADRESS, *lets take a detour and take a look at some tools which makes working with chef-projects a piece of cake.

####Meet knife solo.
[Knife-solo](http://matschaffer.github.io/knife-solo/) is a tool that helps to run Chef-solo in a remote server in a way similar to a Chef-server. It also helps set up our remote server with chef-solo. 

Knife-solo should not be confused with Knife, a command-line-tool that comes with Chef which is used to *"provide an interface between a local chef-repo and Chef-server".*

#### Librarian-chef

The bundler of Chef projects. Librarian-chef, like bundler, has a Cheffile which is very similar to Gemfile where we declare the external cookbooks that we use. Hey, also like [rubygems.org](https://rubygems.org/), chef has [supermarket.getchef.com](https://supermarket.getchef.com/).

######Here's an example Cheffile: 

```ruby
site "https://supermarket.getchef.com/api/v1"   

cookbook "ntp"
cookbook "timezone", "0.0.1"

cookbook "rvm",
  :git => "https://github.com/fnichol/chef-rvm",
  :ref => "v0.7.1"

cookbook "cloudera",
  :path => "vendor/cookbooks/cloudera-cookbook"
```
###### Some useful commands:

`bundle exec librarian-chef install --clean` : This command does a clean install (clears teh cache) of cookbooks to the cookbooks-path, defined in knife.rb.

`bundle exec librarian-chef install --clean --verbose` : This command can come in handy while debugging a misbehaving cookbook installation.

For more detailed reading, visit  [librarian-chef home page](https://github.com/applicationsonline/librarian-chef).

Now that we had our introductions, lets see how to set up a server.

#### Knife solo prepare

1. Inside *"chef-repo"* folder, 
    1. Run 

        1. "bundle install", for installing Chef-project dependencies. A separate gemset would be ideal for this.

        2. "bundle exec knife solo prepare root@IPADDRESS -i <path to the pemfile for the server>"

           
This will create *IPADDRESS.json *file inside *chef-repo/nodes *directory. During this step knife installs Chef-solo on the remote machine and configures it.

#### What should I do with *IPADDRESS.json* file?

For each server (a node), knife-solo creates a json file with the ipaddress of the server. This file in essence contains values with which Chef-solo will be executed in the server. These values are called *"node variables". *[It is highly recommended to read about node variables at this time](https://docs.getchef.com/chef_overview_attributes.html).

Navigate to *"chef-repo/node" *and open 127.0.0.1.json.

1. *run_list*: The sequence in which cookbooks/roles will be run

2. *postgres: *Configurations for [postgresql server external cookbook](https://supermarket.getchef.com/cookbooks/postgresql).

3. nginx: Settings for compiling nginx from source. If you remove this key, nginx will be installed from package control (*eg: apt*). * *For available setting options, visit [nginx external cookbook](https://github.com/midhunkrishna/nginx).

4. *authorization:* The values is used by recipe in "*chef-repo/vendor/cookbooks/rails/recipe/setup*" for setting up a deploy user.

5. *newrelic*: Licence key for newrelic, consult Cheffile for cookbok source.

6. *sshd*: Configurations for ssh. Disables root login altogether. Removes password login too. Enables user *"deploy"* for ssh login.

7. *ssh_deply_keys*: This will be copied into */home/deploy/.ssh/known_hosts *of the remote server. This avoids manual configuration of keys for deploy user.

8. *active_applications*:

    1. *rewrite_to_https*: This key when set to true, rewrites connections at http to https. This will be configured in site specific configuration in "*nginx/sites-available"*.

    2. *domain_names*: Will be added as parameters to "server_name" directive in nginx/sites-available.

#### Set up my server

1. Inside chef-repo folder do,
  1. run `bundle exec knife solo cook root@IPADDRESS -i <path_to_pem_file>`

This will install all that you have specified in the `<your host/ip>.json` file. Once Chef has completed, you need to deploy your application code. 

#### Deployment

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
#### Creating ssl certificates
  
  If you have already bought SSL certificates, do 
*   Copy the contents of `crt` and `key` file into `templates/default/ app_cert.crt.erb` and  `templates/default/app_cert.key.erb` under `vendor/cookbook/rails`.
*   These will be copied to remote server and configured to be used with nginx.

If you want to go with self-signed certificate, you can find a fantastic [how-to](https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04) written by Etel Sverdlov of DigitalOcean.
