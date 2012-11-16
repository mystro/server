class RigWorker < BaseWorker
  @queue = :low

  class << self
    def perform
      logger.info "#{self.name} running perform"
      rigsrvs = Mystro::Model::Instance.running
      if rigsrvs.count > 0
        rigsrvs.each do |rigsrv|
          env                 = Environment.create_from_fog(rigsrv.tags['Environment'])
          compute             = Compute.create_from_fog(rigsrv)
          compute.environment = env
          compute.save
        end
      end

      rigelbs = Mystro::Model::Balancer.all
      if rigelbs.count > 0
        rigelbs.each do |rigelb|
          balancer = Balancer.create_from_fog(rigelb)
          balancer.save

          rigelb.instances.each do |riginst|
            balancer.add_compute(riginst)
          end
        end
      end

      rigzones = Mystro::Model::Dns.all
      if rigzones.count > 0
        rigzones.each do |rigzone|
          zone = Zone.create_from_fog(rigzone)
          zone.save

          zone.records.each do |record|
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