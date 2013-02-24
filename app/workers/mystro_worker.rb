class MystroWorker < BaseWorker
  @queue = :low

  class << self
    def perform
      logger.info "#{self.name} running perform"
      Account.all.each do |account|
        logger.info ".. account: #{account.name}"
        data   = Hashie::Mash.new(account.data)
        mystro = Mystro::Account.list[account.name]

        next unless mystro && data

        if mystro.compute
          computes = mystro.compute.running
          if computes.count > 0
            computes.each do |compute|
              t = compute.tags
              logger.info "  compute: #{t.inspect}"
              e = Environment.create_from_fog(t)
              c = Compute.create_from_fog(compute)

              if e && e.account && c.account != e.account
                c.account = e.account
              else
                c.account = account
              end
              c.environment = e

              logger.info "  compute: #{c.short} account:#{c.account ? c.account.name : "no"} environment:#{e ? e.name : "no"}"
              c.save
            end
          end
        end

        if mystro.balancer
          balancers = mystro.balancer.all
          if balancers.count > 0
            balancers.each do |balancer|
              b = Balancer.create_from_fog(balancer)
              if b.environment && b.environment.account && b.account != b.environment.account
                b.account = b.environment.account
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
              z = Zone.create_from_fog(zone)
              z.save

              z.records.each do |record|
                o = Compute.find_by_record(record) || Balancer.find_by_record(record) || Record.find_by_record(record) || nil
                if o
                  if o.account && !record.account
                    logger.info ".. .. assigning record #{record.name} to account: #{o.account.name}"
                    record.account = o.account
                  end
                  record.nameable = o
                  record.save
                else
                  logger.info "RECORD SEARCH name:#{record.name} long:#{record.long} short:#{record.short}"
                end
              end
            end
          end
        end

        logger.info "#{self.name} complete"
        true
      end
    rescue => e
      logger.info "fail: #{e.message} at #{e.backtrace.first}"
      logger.info "#{e.backtrace.join("\n")}"
      false
    end
  end
end