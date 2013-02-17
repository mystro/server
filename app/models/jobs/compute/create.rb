class Jobs::Compute::Create < Job
  def work
    info "model: #{model.inspect}"
    r               = mystro.compute.create(model)
    rid             = r.id
    model.rid     = r.id
    model.managed = true
    model.save

    info "compute:#{model.id}#create waiting for dns"
    wait do
      r = mystro.compute.find(rid)
      r.dns_name.nil?
    end

    model.reload

    if mystro.data.dns
      z    = mystro.data.dns.zone
      zone = Zone.where(:domain => z).first

      raise "zone '#{z}' not found, could not create dns record" unless zone

      info "compute:#{model.id}#create queueing record"
      record = model.records.find_or_create_by(:zone => zone, :name => "#{model.long}")
      record.update_attributes(
          :type   => "CNAME",
          :ttl    => 300,
          :values => [r.dns_name]
      )
      record.account = Account.mystro(mystro)
      record.save
      record.enqueue(:create)
    end

    info "compute:#{model.id}#create save"
    model.synced_at = Time.now
    model.save
  end
end