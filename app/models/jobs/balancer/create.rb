class Jobs::Balancer::Create < Job
  def work
    raise "model is not set" unless model

    wait_for(model.computes)

    # force reload from database
    #model = model.reload.reload_relations

    info model.fog_options

    e = model.environment
    z    = mystro.data.dns.zone
    zone = Zone.where(:domain => z).first
    raise "could not find zone '#{z}' could not create dns record" unless zone

    balancer = mystro.balancer.create(model)

    if model.sticky
      info "  #{model.id} setting sticky"
      mystro.balancer.sticky(model.name, model.sticky_type, model.sticky_arg, 443, "AWSConsolePolicy-1")
    end

    r = model.records.find_or_create_by(zone: zone, name: "#{model.name}.#{e.name}.#{zone.domain}")
    r.update_attributes(
        :type   => "CNAME",
        :ttl    => 30,
        :values => [balancer.dns_name]
    )
    r.account = model.account
    r.save!
    r.enqueue(:create)

    if model.primary
      info "  #{model.id} primary dns"
      p = model.records.find_or_create_by(:zone => zone, :name => "#{e.name}.#{zone.domain}")
      p.update_attributes(
          :type   => "CNAME",
          :ttl    => 30,
          :values => [balancer.dns_name]
      )
      p.account = model.account
      p.save!
      p.enqueue(:create)
    end

    model.rid       = balancer.id
    model.synced_at = Time.now
    model.save
  end
end