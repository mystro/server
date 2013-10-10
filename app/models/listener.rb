class Listener
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :balancer

  field :from, type: String
  field :to, type: String
  field :cert, type: String

  def fog_options
    (from_proto, from_port) = from.split(':')
    (to_proto, to_port)     = to.split(':')
    sslcert                 = cert || nil
    policies                = [] # TODO: figure how we want to track these
    {
        'Listener'    => {
            "Protocol" => from_proto,
            "LoadBalancerPort" => from_port,
            "InstanceProtocol" => to_proto,
            "InstancePort" => to_port,
            "SSLCertificateId" => sslcert,
            "PolicyNames" => policies
        },
        'PolicyNames' => policies
    }
  end

  class << self
    def create_from_cloud(balancer, obj)
      create(balancer: balancer, from: obj[:from], to: obj[:to], cert: obj[:cert]) if obj
    end
    #def create_from_fog(balancer, obj)
    #  #TODO: show reference to cert
    #  create(
    #      balancer:  balancer,
    #      from:      "#{obj.protocol}:#{obj.lb_port}",
    #      to:        "#{obj.instance_protocol}:#{obj.instance_port}",
    #      synced_at: Time.now
    #  )
    #end

    def create_from_template(balancer, tlistener)
      from = "#{tlistener.from_proto}:#{tlistener.from_port}"
      listener = balancer.listeners.find_or_create_by(from: from)
      lattrs = {
          to: "#{tlistener.to_proto}:#{tlistener.to_port}"
      }
      lattrs.merge!({cert: tlistener.cert}) if tlistener.cert
      listener.update_attributes(lattrs)
      listener.save!
    end
  end
end
