class Jobs::Balancer::Create < Job
  def work
    wait_for(model.computes)

    balancer = mystro.balancer.create(model)
    balancer.register_instances(model.computes.collect { |e| e.rid })
    balancer.save

    if model.sticky
      info "  #{model.id} setting sticky"
      mystro.balancer.sticky(model.name, model.sticky_type, model.sticky_arg, 443, "AWSConsolePolicy-1")
    end

    if model.primary
      info "  #{model.id} primary dns"
      z    = mystro.data.dns.zone
      zone = Zone.where(:domain => z).first
      raise "could not find zone '#{z}' could not create dns record" unless zone

      e = model.environment
      r = model.records.find_or_create_by(:zone => zone, :name => "#{e.name}.#{zone.domain}")
      r.update_attributes(
          :type   => "CNAME",
          :ttl    => 30,
          :values => [balancer.dns_name]
      )
      r.account = Account.mystro(mystro)
      r.save
      r.enqueue(:create)
    end

    model.rid       = balancer.id
    model.synced_at = Time.now
    model.save
  end
end