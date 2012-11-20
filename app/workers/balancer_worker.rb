class BalancerWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(options)
      id = options["id"]
      b  = Balancer.find(id)

      wait_for(b.computes)

      balancer = Mystro.balancer.create(b)
      balancer.register_instances(b.computes.collect { |e| e.rid })
      balancer.save

      if b.sticky
        logger.info "  #{id} setting sticky"
        Mystro.balancer.sticky(b.name, b.sticky_type, b.sticky_arg, 443, "AWSConsolePolicy-1")
      end

      if b.primary
        logger.info "  #{id} primary dns"
        z    = Mystro.account.dns.zone
        zone = Zone.where(:domain => z).first
        raise "could not find zone '#{z}' could not create dns record" unless zone

        e = b.environment
        r = b.records.find_or_create_by(:zone => zone, :name => "#{e.name}.#{Mystro.account.dns.subdomain}.#{zone.domain}")
        r.update_attributes(
            :type   => "CNAME",
            :ttl    => 30,
            :values => [balancer.dns_name]
        )
        r.enqueue(:create)
      end

      b.rid       = balancer.id
      b.synced_at = Time.now
      b.save
      logger.info "  #{id} balancer created"
    end

    def perform_destroy(options)
      id = options["id"]
      b  = Balancer.unscoped.find(id)
      raise "could not find balancer #{id}" unless b
      Mystro.balancer.destroy(b) if b.synced_at && b.rid
      b.records.each { |r| r.enqueue(:destroy) }
      b.destroy
    end
  end
end