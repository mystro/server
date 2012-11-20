class ComputeWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(options)
      id      = options["id"]
      compute = Compute.find(id)
      raise "could not find compute #{id}" unless compute

      r               = Mystro.compute.create(compute)
      rid             = r.id
      compute.rid     = r.id
      compute.managed = true
      compute.save

      logger.info "compute:#{id}#create waiting for dns"
      wait do
        r = Mystro.compute.find(rid)
        r.dns_name.nil?
      end

      compute.reload

      z    = Mystro.account.dns.zone
      zone = Zone.where(:domain => z).first

      raise "zone '#{z}' not found, could not create dns record" unless zone

      logger.info "compute:#{id}#create queueing record"
      record = compute.records.find_or_create_by(:zone => zone, :name => "#{compute.long}")
      record.update_attributes(
          :type   => "CNAME",
          :ttl    => 300,
          :values => [r.dns_name]
      )
      record.enqueue(:create)

      logger.info "compute:#{id}#create save"
      compute.synced_at = Time.now
      compute.save
    end

    def perform_destroy(options)
      id      = options["id"]
      compute = Compute.unscoped.find(id)
      raise "could not find compute #{id}" unless compute

      logger.info "compute:#{id}#destroy fog destroy"
      Mystro.compute.destroy(compute)
      logger.info "compute:#{id}#destroy queue record destroy"
      compute.records.each { |r| r.enqueue(:destroy) }

      logger.info "compute:#{id}#destroy compute destroy"
      compute.destroy
    end
  end
end
