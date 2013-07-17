class Jobs::Compute::Create < Job
  def work
    r = mystro.compute.create(model)
    rid = r.id
    model.rid = r.id
    model.managed = true
    model.save

    info "compute#create waiting for dns"
    wait do
      r = mystro.compute.find(rid)
      r.dns_name.nil?
    end

    model.reload

    if mystro.data.dns && data["dns"] != false
      z = mystro.data.dns.zone
      zone = Zone.where(:domain => z).first

      raise "zone '#{z}' not found, could not create dns record" unless zone

      info "compute#create queueing record"
      record = model.records.find_or_create_by(:zone => zone, :name => model.long)
      record.update_attributes(
          :type => "CNAME",
          :ttl => 300,
          :values => [r.dns_name]
      )
      record.account = Account.mystro(mystro)
      record.save
      record.enqueue(:create)

      if model.num == 1
        info "model.num == 1"
        e = model.environment
        if e.computes.select { |e| e.name == model.name }.count == 1
          info "computes.count == 1"
          if model.balancer == nil
            n = "#{model.name}.#{e.name}.#{z}"
            debug "compute#create queueing solo record (single compute - num == 1 - with no balancer) #{n}"
            record2 = model.records.find_or_create_by(zone: zone, name: n)
            record2.update_attributes(
                :type => "CNAME",
                :ttl => 300,
                :values => [r.dns_name]
            )
            record2.account = Account.mystro(mystro)
            record2.save
            record2.enqueue(:create)
          end
        end
      end

    end

    #info "compute:#{model.id}#create save"
    model.synced_at = Time.now
    model.save
  end
end