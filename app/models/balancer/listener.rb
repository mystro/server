class Listener
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :balancer

  field :from, type: String
  field :to, type: String
  field :cert, type: String

  def rig_options
    {
        :from => from,
        :to => to,
        :cert => cert,
    }
  end

  class << self
    def create_from_fog(balancer, obj)
      #TODO: show reference to cert
      create(
          balancer:  balancer,
          from:      "#{obj.protocol}:#{obj.lb_port}",
          to:        "#{obj.instance_protocol}:#{obj.instance_port}",
          synced_at: Time.now
      )
    end
  end
end
