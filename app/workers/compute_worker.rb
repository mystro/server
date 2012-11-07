class ComputeWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(options)
      #id = options["id"]
      #compute = Compute.find(id)
      #
      #unless compute
      #  logger.warn "could not find compute #{id}"
      #  return
      #end
      #
      #o = compute.rig_options
      #t = compute.rig_tags
      #
      #r = Rig::Model::Instance.create(o, t)
      #rid = r.id
      #compute.rid = r.id
      #compute.managed = true
      #compute.save
      #
      ##waiting = true
      ##while waiting do
      ##  sleep 3
      ##  r = Rig::Model::Instance.find(rid)
      ##  waiting = false if r.dns_name
      ##end
      #
      #wait do
      #  r = Rig::Model::Instance.find(rid)
      #  r.dns_name.nil?
      #end
      #
      #compute.reload
      #
      #z = Rig.account[:dns_zone]
      #zone = Zone.where(:domain => z).first
      #
      #if zone
      #  record = compute.records.find_or_create_by(:zone => zone, :name => "#{t['Name']}.#{zone.domain}")
      #  record.update_attributes(
      #      :type => "CNAME",
      #      :ttl => 300,
      #      :values => [r.dns_name]
      #  )
      #  record.enqueue(:create)
      #else
      #  logger.error "zone '#{z}' not found, could not create dns record"
      #end
      #
      #compute.synced_at = Time.now
      #compute.save
    end

    def perform_destroy(options)
      #id = options["id"]
      #compute = Compute.unscoped.find(id)
      #
      #unless compute
      #  logger.warn "could not find compute #{id}"
      #  return
      #end
      #
      #rid = compute.rid
      #list = Rig::Model::Instance.find(rid)
      #Rig::Model::Instance.destroy(list)
      #compute.records.each {|r| r.enqueue(:destroy) }
      #
      #logger.info "  compute destroy"
      #compute.destroy
    end
  end
end
