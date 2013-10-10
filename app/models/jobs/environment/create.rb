class Jobs::Environment::Create < Job
  def work
    env = model
    raise "model not set" unless env

    template = env.template
    raise "template not set" unless template
    raise "template has no data" unless template.data

    tf = template.load
    computes = []
    balancers = {}

    actions = tf.actions
    puts "ACTIONS:"
    actions.each do |a|
      puts "a: #{a.model.inspect}"
      puts "   #{action_to_cloud(a).inspect}"
    end
    bactions = actions.select {|action| action.model == 'Balancer'}
    cactions = actions.select {|action| action.model == 'Compute'}

    bactions.each do |action|
      (balancer, options) = do_action(action)
      balancer.save!
      balancers[balancer.name] = [action.action, balancer]
    end

    cactions.each do |action|
      (compute, options) = do_action(action)
      if options[:balancer]
        compute.balancer = balancers[options[:balancer]]
      end
      compute.save!
      computes << [action.action, compute]
    end

    computes.each do |a, c|
      unless c.synced_at
        info ".. enqueue: #{c}"
        c.enqueue(a)
      end
    end

    balancers.each do |n, l|
      (a, b) = l
      unless b.synced_at
        info ".. enqueue: #{a} #{b}"
        b.enqueue(a)
      end
    end

    #info "actions"
    #tf.actions.each do |action|
    #  model = action.model
    #  cloud = action_to_cloud(action)
    #  options = action.options
    #  info "action:#{model}"
    #  info ".. #{cloud.inspect}"
    #  k = model.constantize
    #  object = k.find_by_cloud(cloud, env, org) || k.new
    #  object.environment = env
    #  object.organization = org
    #  object.from_cloud(cloud)
    #  object.save
    #
    #  if model == Compute
    #    computes << [action.action, object]
    #  elsif model == Balancer
    #    balancers << [action.action, object]
    #  end
    #
    #  #if options[:balancer]
    #  #  computes[object.rid] = options[:balancer]
    #  #end
    #  #
    #  #if model == Balancer
    #  #  balancers[object.name] = object
    #  #end
    #end
    #
    #computes.each do |b|
    #  c = Compute.remote(id)
    #  raise "balancer #{b} does not exist" unless balancers[b]
    #  c.balancer = balancers[b]
    #  c.save
    #end
  end

  def action_to_cloud(action)
    klass = action.class
    klass.constantize.new(action.data)
  end

  def do_action(action)
    env = model
    org = env.organization
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

    info ".. #{object.inspect}"

    [object, options]
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
