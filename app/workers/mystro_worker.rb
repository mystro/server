class MystroWorker < BaseWorker
  @queue = :low

  class << self
    def perform
      logger.info "#{self.name} running perform"
      computes = Mystro.compute.running
      if computes.count > 0
        computes.each do |compute|
          e             = Environment.create_from_fog(compute.tags['Environment'])
          c             = Compute.create_from_fog(compute)
          c.environment = e
          c.save
        end
      end

      balancers = Mystro.balancer.all
      if balancers.count > 0
        balancers.each do |balancer|
          b = Balancer.create_from_fog(balancer)
          b.save

          balancer.instances.each do |i|
            b.add_compute(i)
          end
        end
      end

      zones = Mystro.dns.zones
      if zones.count > 0
        zones.each do |zone|
          z = Zone.create_from_fog(zone)
          z.save

          z.records.each do |record|
            o = Compute.find_by_record(record) || Balancer.find_by_record(record) || Record.find_by_record(record) || nil
            if o
              record.nameable = o
              record.save
            else
              puts "RECORD SEARCH name:#{record.name} long:#{record.long} short:#{record.short}"
            end
          end
        end
      end

      logger.info "#{self.name} complete"
      true
    rescue => e
      puts "fail: #{e.message} at #{e.backtrace.first}"
      puts "#{e.backtrace.join("\n")}"
      false
    end
  end
end