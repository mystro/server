class ComputeWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(compute, mystro)
      r               = mystro.compute.create(compute)
      rid             = r.id
      compute.rid     = r.id
      compute.managed = true
      compute.save

      logger.info "compute:#{compute.id}#create waiting for dns"
      wait do
        r = mystro.compute.find(rid)
        r.dns_name.nil?
      end

      compute.reload

      z    = mystro.data.dns.zone
      zone = Zone.where(:domain => z).first

      raise "zone '#{z}' not found, could not create dns record" unless zone

      logger.info "compute:#{compute.id}#create queueing record"
      record = compute.records.find_or_create_by(:zone => zone, :name => "#{compute.long}")
      record.update_attributes(
          :type   => "CNAME",
          :ttl    => 300,
          :values => [r.dns_name]
      )
      record.account = Account.mystro(mystro)
      record.save
      record.enqueue(:create)

      logger.info "compute:#{compute.id}#create save"
      compute.synced_at = Time.now
      compute.save
    end

    def perform_destroy(compute, mystro)
      logger.info "compute:#{compute.id}#destroy fog destroy"
      mystro.compute.destroy(compute)
      logger.info "compute:#{compute.id}#destroy queue record destroy"
      compute.records.each { |r| r.enqueue(:destroy) }

      logger.info "compute:#{compute.id}#destroy compute destroy"
      compute.destroy
    end
  end
end
