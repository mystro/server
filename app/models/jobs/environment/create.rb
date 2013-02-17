class Jobs::Environment::Create < Job
  def work
    environment = model
    template    = environment.template
    raise "could not find template" unless template
    raise "template has no data" unless template.data
    tdata = Hashie::Mash.new(template.data)

    balancers = {}

    tdata.balancers.each do |tbalancer|
      balancer                  = Balancer.create_from_template(environment, tbalancer)
      balancers[tbalancer.name] = balancer
    end

    tdata.servers.each do |tserver|
      1.upto(tserver.count) do |i|
        compute = Compute.create_from_template(environment, tserver, i)

        if tserver.balancer
          if balancers[tserver.balancer]
            compute.balancer = balancers[tserver.balancer]
          else
            raise "balancer #{tserver.balancer} does not exist in template"
          end
        end

        compute.account = environment.account
        compute.save!
      end
    end

    environment.computes.each do |c|
      info "compute: #{c.inspect}"
      unless c.synced_at
        info "compute enqueue: #{c.enqueue(:create)}"
      end
    end

    environment.balancers.each do |b|
      info "balancer: #{b.inspect}"
      unless b.synced_at
        info "balancer enqueue: #{b.enqueue(:create)}"
      end
    end

    Mystro::Plugin.run "environment:create", environment
  end
end