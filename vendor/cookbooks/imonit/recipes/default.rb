if node[:imonit]
  # overriding default cookbook configs
  node.override[:monit][:mailserver][:host] = node[:imonit][:mail_host]
  node.override[:monit][:mailserver][:port] = node[:imonit][:mail_port]
  node.override[:monit][:mailserver][:username] = node[:imonit][:mail_username]
  node.override[:monit][:mailserver][:password] = node[:imonit][:mail_passphrase]
  node.override[:monit][:mail_format][:from] = node[:imonit][:mail_from]
  node.override[:monit][:mail_format][:to] = node[:imonit][:mail_to]
end

include_recipe "monit"
include_recipe "monit::ubuntu12fix"
include_recipe "monit::ssh"

r = resources(:template => "/etc/monit/monitrc")
r.cookbook "imonit"

r = resources(:template => "/etc/monit/conf.d/ssh.conf")
r.cookbook "imonit"

include_recipe "monit::postgresql"
r = resources(:template => "/etc/monit/conf.d/postgresql.conf")
r.cookbook "imonit"

monitrc "monit-nginx"

r = resources(:template => "/etc/monit/conf.d/monit-nginx.conf")
r.cookbook "imonit"


service "monit"
