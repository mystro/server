class Jobs::Balancer::Create < Job
  def work
    wait_for(model.computes)

    env = model.environment
    o = Organization.mystro(mystro)
    z = o.record_config['zone']
    zone = Zone.where(domain: z).first
    raise "could not find zone '#{z}' could not create dns record" unless zone

    balancer = mystro.balancer.create(model.to_cloud)

    if model.sticky
      info "  setting sticky"
      mystro.balancer.sticky(model.name, model.sticky_type, model.sticky_arg, 443, "AWSConsolePolicy-1")
    end

    name = model.name
    record = model.records.find_or_create_by(zone: zone, name: "#{name}.#{env.name}.#{zone.domain}")
    record.update_attributes(
        type: "CNAME",
        ttl: 30,
        values: [balancer.dns]
    )
    record.organization = model.organization
    record.save!
    record.enqueue(:create)

    if model.primary
      primary = model.records.find_or_create_by(zone: zone, name: "#{env.name}.#{zone.domain}")
      primary.update_attributes(
          type: "CNAME",
          ttl: 30,
          values: [balancer.dns]
      )
      primary.organization = model.organization
      primary.save!
      primary.enqueue(:create)
    end

    model.rid = balancer.id
    model.synced_at = Time.now
    model.save!
  end

  #def work
  #  raise "model is not set" unless model
  #
  #  wait_for(model.computes)
  #
  #  # force reload from database
  #  #model = model.reload.reload_relations
  #
  #  info model.fog_options
  #
  #  e = model.environment
  #  z    = mystro.data.dns.zone
  #  zone = Zone.where(:domain => z).first
  #  raise "could not find zone '#{z}' could not create dns record" unless zone
  #
  #  balancer = mystro.balancer.create(model)
  #
  #  if model.sticky
  #    info "  setting sticky"
  #    mystro.balancer.sticky(model.name, model.sticky_type, model.sticky_arg, 443, "AWSConsolePolicy-1")
  #  end
  #
  #  n = model.bname
  #  info "  create record: #{n}.#{e.name}.#{zone.domain}"
  #  r = model.records.find_or_create_by(zone: zone, name: "#{n}.#{e.name}.#{zone.domain}")
  #  r.update_attributes(
  #      :type   => "CNAME",
  #      :ttl    => 30,
  #      :values => [balancer.dns_name]
  #  )
  #  r.organization = model.organization
  #  r.save!
  #  r.enqueue(:create)
  #
  #  if model.primary
  #    info "  create record (primary): #{e.name}.#{zone.domain}"
  #    p = model.records.find_or_create_by(:zone => zone, :name => "#{e.name}.#{zone.domain}")
  #    p.update_attributes(
  #        :type   => "CNAME",
  #        :ttl    => 30,
  #        :values => [balancer.dns_name]
  #    )
  #    p.organization = model.organization
  #    p.save!
  #    p.enqueue(:create)
  #  end
  #
  #  if model.health_check
  #    info "  create health check: #{model.health_check.inspect}"
  #    mystro.balancer.health_check(model.rid, model.health_check)
  #  end
  #
  #  model.rid       = balancer.id
  #  model.synced_at = Time.now
  #  model.save
  #end
end
