if node[:iptables]

  diptables_rule 'ssh' do
    rule [
          "--proto tcp --dport 47865"
    ]
  end
  

  diptables_rule 'http' do
    rule [
            "--proto tcp --dport 80",
            "--proto tcp --dport 443"
    ]
  end
end
