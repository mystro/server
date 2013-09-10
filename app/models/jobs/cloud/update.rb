class Jobs::Cloud::Update < Job
  def work
    ::Organization.all.each do |organization|
      info ".. organization: #{organization.name}"
      data   = ::Hashie::Mash.new(organization.data)
      mystro = ::Mystro::Organization.get(organization.name)

      next unless mystro && data

      if mystro.compute
        computes = mystro.compute.running
        if computes.count > 0
          computes.each do |compute|
            t = compute.tags
            e = ::Environment.create_from_fog(t)
            c = ::Compute.create_from_fog(compute)
            c.tags = t

            if e && e.organization && c.organization != e.organization
              c.organization = e.organization
            else
              c.organization = organization
            end
            c.environment = e

            info "  compute: #{c.short} organization:#{c.organization ? c.organization.name : "no"} environment:#{e ? e.name : "no"}"
            c.save
          end
        end
      end

      if mystro.balancer
        balancers = mystro.balancer.all
        if balancers.count > 0
          balancers.each do |balancer|
            b = ::Balancer.create_from_fog(balancer)
            if b.environment && b.environment.organization && b.organization != b.environment.organization
              b.organization = b.environment.organization
            end
            b.save

            balancer.instances.each do |i|
              b.add_compute(i)
            end
            b.save
          end
        end
      end

      if mystro.dns
        zones = mystro.dns.zones
        if zones.count > 0
          zones.each do |zone|
            z = ::Zone.create_from_fog(zone)
            z.save

            z.records.each do |record|
              o = ::Balancer.find_by_record(record) || ::Compute.find_by_record(record) || ::Record.find_by_record(record) || nil
              if o
                if o.organization && !record.organization
                  info ".. .. assigning record #{record.name} to organization: #{o.organization.name}"
                  record.organization = o.organization
                end
                record.nameable = o
                record.save
              else
                warn "RECORD SEARCH name:#{record.name} long:#{record.long} short:#{record.short}"
              end
            end
          end
        end
      end
    end

    info "clean up"
    yesterday = Time.now - 24.hours
    computes = ::Compute.where(:synced_at.lte => yesterday)
    computes.each do |c|
      info "remove compute #{c.short}"
      c.destroy
    end

    balancers = ::Balancer.where(:synced_at.lte => yesterday)
    balancers.each do |b|
      info "remove balancer #{b.name}"
      b.destroy
    end

    records = ::Record.where(:synced_at.lte => yesterday)
    records.each do |r|
      info "remove record #{r.long}"
      r.destroy
    end
  end
end
