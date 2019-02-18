cgred_resource = service 'cgred' do
  provider Chef::Provider::Service::Upstart
  supports status: true, start: true, stop: true, reload: true
  action :nothing
end

cgconfig_resource = service 'cgconfig' do
  provider Chef::Provider::Service::Upstart
  supports status: true, start: true, stop: true, reload: true
  ignore_failure true
  action :nothing
end

ruby_block 'control_groups[write configs]' do
  block do
    ControlGroups.config_struct_init(node)
    ControlGroups.rules_struct_init(node)
    c = Chef::Resource::File.new('/etc/cgconfig.conf', run_context)
    c.content ControlGroups.build_config(node.run_state[:control_groups][:config])
    c.notifies :restart, cgconfig_resource, :immediately
    c.run_action(:create)
    r = Chef::Resource::File.new('/etc/cgrules.conf', run_context)
    r.content ControlGroups.build_rules(node.run_state[:control_groups][:rules][:active])
    r.notifies :restart, cgred_resource, :immediately
    r.run_action(:create)
  end
  action :nothing
end

ruby_block 'control_group_configs[notifier]' do
  block do
    Chef::Log.debug 'Sending delayed notification to cgroup config files'
  end
  notifies :create, 'ruby_block[control_groups[write configs]]', :delayed
end
