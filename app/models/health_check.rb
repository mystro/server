class HealthCheck
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :balancer

  field :targeturl, type: String
  field :healthy, type: Integer, default: 10
  field :unhealthy, type: Integer, default: 2
  field :interval, type: Integer, default: 30
  field :timeout, type: Integer, default: 5

  #def fog_options
  #  {
  #      'HealthyThreshold'   => healthy,
  #      'UnhealthyThreshold' => unhealthy,
  #      'Interval'           => interval,
  #      'Target'             => targeturl,
  #      'Timeout'            => timeout,
  #  }
  #end

  def to_cloud
    {
        target: targeturl,
        healthy: healthy,
        unhealthy: unhealthy,
        interval: interval,
        time: timeout,
    }
  end

  def from_cloud(obj)
    self.targeturl = obj[:target]
    self.healthy = obj[:healthy]
    self.unhealthy = obj[:unhealthy]
    self.interval = obj[:interval]
    self.timeout = obj[:time]
  end

  class << self
    def create_from_cloud(balancer, obj)
      h = create!(balancer: balancer)
      h.from_cloud(obj)
      h
    end

    #def create_from_fog(balancer, obj)
    #  #TODO: show reference to cert
    #  #obj={"Interval"=>30, "Target"=>"HTTP:8080/INQReaderServer/rest/AjaxConfig/config", "HealthyThreshold"=>10, "Timeout"=>5, "UnhealthyThreshold"=>2},
    #  create!(
    #      balancer: balancer,
    #      targeturl: obj["Target"],
    #      healthy: obj["HealthyThreshold"],
    #      unhealthy: obj["UnhealthyThreshold"],
    #      interval: obj["Interval"],
    #      timeout: obj["Timeout"],
    #  )
    #end

    def create_from_template(balancer, thealth)
      balancer.health_check = nil
      create!(balancer: balancer, targeturl: thealth.target, healthy: thealth.healthy, unhealthy: thealth.unhealthy, interval: thealth.interval, timeout: thealth.timeout)
    end
  end
end
