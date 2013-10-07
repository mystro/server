class Jobs::Environment::Create < Job
  def work
    env = model
    raise "model not set" unless env
    org = env.organization

    template = env.template
    raise "template not set" unless template
    raise "template has no data" unless template.data

    data = template.data
    tf = template.load

    info "actions"
    tf.actions.each do |action|
      model = action.model
      cloud = action_to_cloud(action)
      options = action.options
      info "action:#{model}"
      info ".. #{cloud.inspect}"
      k = model.constantize
      object = k.find_by_cloud(cloud, env, org) || k.new
      object.environment = env
      object.organization = org
      object.from_cloud(cloud)
      object.save
      info ".. #{object.inspect}"
      unless object.synced_at
        info ".. enqueue: #{action.action}"
        object.enqueue(action.action)
      end
      info ""
    end
  end

  def action_to_cloud(action)
    klass = action.class
    klass.constantize.new(action.data)
  end

  #def work
  #  environment = model
  #  raise "model not set" unless environment
  #
  #  template    = environment.template
  #  raise "could not find template" unless template
  #  raise "template has no data" unless template.data
  #  tdata = Hashie::Mash.new(template.data)
  #
  #  balancers = {}
  #
  #  info "creating balancers"
  #  tdata.balancers.each do |tbalancer|
  #    info ".. #{tbalancer.name}"
  #    balancer                  = Balancer.create_from_template(environment, tbalancer)
  #    balancers[tbalancer.name] = balancer
  #  end
  #
  #  info "creating computes"
  #  tdata.servers.each do |tserver|
  #    tserver = tserver.attrs
  #    info ".. #{tserver.inspect}"
  #    count = tserver["count"] # .count calls the hash#count method
  #    1.upto(count) do |i|
  #      info ".. #{tserver.name} #{i}"
  #      compute = Compute.create_from_template(environment, tserver, i)
  #
  #      if tserver.balancer
  #        info ".. .. associating balancer #{tserver.balancer}"
  #        if balancers[tserver.balancer]
  #          compute.balancer = balancers[tserver.balancer]
  #        else
  #          raise "balancer #{tserver.balancer} does not exist in template"
  #        end
  #      end
  #
  #      info ".. .. setting organization #{environment.organization.name}"
  #      compute.organization = environment.organization
  #      compute.save!
  #    end
  #  end
  #
  #  info "creating compute jobs"
  #  environment.computes.each do |c|
  #    info ".. compute: #{c.inspect}"
  #    unless c.synced_at
  #      info ".. .. compute enqueue: #{c.enqueue(:create)}"
  #    end
  #  end
  #
  #  info "creating balancer jobs"
  #  environment.balancers.each do |b|
  #    info ".. balancer: #{b.inspect}"
  #    unless b.synced_at
  #      info ".. .. balancer enqueue: #{b.enqueue(:create)}"
  #    end
  #  end
  #
  #  Mystro::Plugin.run "environment:create", environment
  #end
end
