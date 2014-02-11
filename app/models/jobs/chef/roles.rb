class Jobs::Chef::Roles < Job
  def work
    if Mystro.config.plugins.chef && defined?(Mystro::Plugin::Chef)
      list = Mystro::Plugin::Chef.role_list
      info "found #{list.count} roles"
      list.each do |name, url|
        info ".. #{name}"
        d = {
            description: url,
            internal: false
        }
        r = Role.where(name: name).first || Role.create(name: name)
        r.update_attributes(d)
      end
      info "complete"
    else
      warn "chef plugin disabled"
    end
  end
end