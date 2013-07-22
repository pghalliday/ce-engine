include_recipe "nodejs"
include_recipe "git"
include_recipe "zeromq"

user node[:ce_engine][:user] do
end

git "#{node[:ce_engine][:destination]}" do
  user node[:ce_engine][:user]
  repository node[:ce_engine][:repository]
  destination node[:ce_engine][:destination]
  not_if { ::FileTest.exists?(node[:ce_engine][:destination]) }
end

file "#{node[:ce_engine][:destination]}/config.json" do
  owner node[:ce_engine][:user]
  content <<-EOH
{
  "commission": {
    "account": "#{node[:ce_engine][:commission][:account]}"
  },
  "ce-operation-hub": {
    "host": "#{node[:ce_engine][:ce_operation_hub][:host]}",
    "stream": #{node[:ce_engine][:ce_operation_hub][:stream]},
    "result": #{node[:ce_engine][:ce_operation_hub][:result]}
  },
  "ce-delta-hub": {
    "host": "#{node[:ce_engine][:ce_delta_hub][:host]}",
    "stream": #{node[:ce_engine][:ce_delta_hub][:stream]},
    "state": #{node[:ce_engine][:ce_delta_hub][:state]}
  }
}
  EOH
end

bash "start ce-engine server" do
  code <<-EOH
    su -l #{node[:ce_engine][:user]} -c "cd #{node[:ce_engine][:destination]} && npm install && npm start"
  EOH
end
