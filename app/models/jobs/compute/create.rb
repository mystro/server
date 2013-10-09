class Jobs::Compute::Create < Job
  def work
    compute = model
    organization = Organization.mystro(mystro)
    remote = mystro.compute.create(compute.to_cloud)

    compute.rid = remote.identity
    compute.from_cloud(remote)
    compute.managed = true
    compute.synced_at = Time.now
    compute.save!
    #info ".. #{compute.inspect}"

    wait do
      #info ".. waiting for dns"
      remote = mystro.compute.find(remote.id)
      remote.dns.nil?
    end

    #info ".. #{remote.inspect}"

    if mystro.record
      cfg = organization.record_config
      z = cfg['zone']
      zone = Zone.where(:domain => z).first
      raise "zone not found: #{z.inspect}" unless zone

      record = compute.records.find_or_create_by(:zone => zone, :name => compute.long)
      record.update_attributes(
          :type => "CNAME",
          :ttl => 300,
          :values => [remote.dns]
      )
      record.organization = organization
      record.save!
      record.enqueue(:create)

      if compute.num == 1
        #debug "compute.num == 1"
        e = compute.environment
        if e.computes.select { |c| c.name == compute.name }.count == 1
          #debug "computes.count == 1"
          if compute.balancer == nil
            n = "#{compute.name}.#{e.name}.#{z}"
            #debug "compute#create queueing solo record (single compute - num == 1 - with no balancer) #{n}"
            record2 = compute.records.find_or_create_by(zone: zone, name: n)
            record2.update_attributes(
                :type => "CNAME",
                :ttl => 300,
                :values => [r.dns_name]
            )
            record2.organization = organization
            record2.save!
            record2.enqueue(:create)
          end
        end
      end
    end

    compute.save!
  end

  #def work
  #  r = mystro.compute.create(model)
  #  rid = r.id
  #  compute = model
  #  compute.rid = r.id
  #  compute.managed = true
  #  compute.save
  #
  #  info "compute#create waiting for dns"
  #  r = nil
  #  wait do
  #    r = mystro.compute.find(rid)
  #    r.dns_name.nil?
  #  end
  #
  #  compute = ::Compute.create_from_fog(r)
  #
  #  if mystro.data.dns && data["dns"] != false
  #    z = mystro.data.dns.zone
  #    zone = Zone.where(:domain => z).first
  #
  #    raise "zone '#{z}' not found, could not create dns record" unless zone
  #
  #    info "compute#create queueing record"
  #    record = compute.records.find_or_create_by(:zone => zone, :name => compute.long)
  #    record.update_attributes(
  #        :type => "CNAME",
  #        :ttl => 300,
  #        :values => [r.dns_name]
  #    )
  #    record.organization = Organization.mystro(mystro)
  #    record.save
  #    record.enqueue(:create)
  #
  #    if compute.num == 1
  #      info "compute.num == 1"
  #      e = compute.environment
  #      if e.computes.select { |e| e.name == compute.name }.count == 1
  #        info "computes.count == 1"
  #        if compute.balancer == nil
  #          n = "#{compute.name}.#{e.name}.#{z}"
  #          debug "compute#create queueing solo record (single compute - num == 1 - with no balancer) #{n}"
  #          record2 = compute.records.find_or_create_by(zone: zone, name: n)
  #          record2.update_attributes(
  #              :type => "CNAME",
  #              :ttl => 300,
  #              :values => [r.dns_name]
  #          )
  #          record2.organization = Organization.mystro(mystro)
  #          record2.save
  #          record2.enqueue(:create)
  #        end
  #      end
  #    end
  #
  #  end
  #
  #  #info "compute:#{compute.id}#create save"
  #  compute.synced_at = Time.now
  #  compute.save
  #end
end
