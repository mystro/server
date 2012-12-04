class BalancerWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(b, mystro)

      wait_for(b.computes)

      balancer = mystro.balancer.create(b)
      balancer.register_instances(b.computes.collect { |e| e.rid })
      balancer.save

      if b.sticky
        logger.info "  #{b.id} setting sticky"
        mystro.balancer.sticky(b.name, b.sticky_type, b.sticky_arg, 443, "AWSConsolePolicy-1")
      end

      if b.primary
        logger.info "  #{b.id} primary dns"
        z    = mystro.data.dns.zone
        zone = Zone.where(:domain => z).first
        raise "could not find zone '#{z}' could not create dns record" unless zone

        e = b.environment
        r = b.records.find_or_create_by(:zone => zone, :name => "#{e.name}.#{mystro.data.dns.subdomain}.#{zone.domain}")
        r.update_attributes(
            :type   => "CNAME",
            :ttl    => 30,
            :values => [balancer.dns_name]
        )
        r.account = Account.mystro(mystro)
        r.save
        r.enqueue(:create)
      end

      b.rid       = balancer.id
      b.synced_at = Time.now
      b.save
      logger.info "  #{id} balancer created"
    end

    def perform_destroy(b, mystro)
      mystro.balancer.destroy(b) if b.synced_at && b.rid
      b.records.each { |r| r.enqueue(:destroy) }
      b.destroy
    end
  end
end