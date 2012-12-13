class Balancer
  include Mongoid::Document
  include Mongoid::Timestamps

  include CommonAccount
  include CommonRemote
  include CommonWorker
  include CommonDeleting

  belongs_to :environment, index: true
  belongs_to :account, index: true
  embeds_many :listeners
  has_many :computes
  has_many :records, as: :nameable

  #field :name, type: String # name is stored in the remote id (rid)
  field :environment_id, type: String
  field :primary, type: Boolean

  field :public_dns, type: String

  def name
    rid
  end

  def short
    rid
  end

  def display
    rid
  end

  def add_compute(rid)
    computes << Compute.remote(rid)
  end

  def envname
    environment ? environment.name : "unknown"
  end

  def fog_options
    {
        id: rid,
        "ListenerDescriptions" => listeners.map {|l| l.fog_options},
        availability_zones: zones
    }
  end

  def zones
    computes.collect do |e|
      s = Mystro.compute.find(e.rid)
      s ? s.availability_zone : nil
    end.compact.uniq
  end

  class << self
    def create_from_fog(obj)
      balancer             = Balancer.where(:rid => obj.id).first || Balancer.create(:rid => obj.id)
      balancer.rid         = obj.id
      (e, r)               = obj.id.split(/\-/)
      balancer.environment = Environment.create_from_fog(e)
      balancer.synced_at   = Time.now
      balancer.public_dns  = obj.dns_name

      balancer.listeners = []
      obj.listeners.each do |l|
        Listener.create_from_fog(balancer, l)
      end

      balancer.save
      balancer
    end

    def find_by_record(record)
      if ::IPAddress.valid?(record.long)
        return
      else
        record.values.each do |val|
          o = Balancer.where(:public_dns => val).first
          return o if o
        end
      end

      #long = record.long
      #long.match(/^(\w+)-(\w+)-\d+\./) do
      #  b = Balancer.where(:rid => "#{$1}-#{$2}").first
      #  return b if b
      #end
      #parts = record.parts
      #if parts
      #  e = Environment.where(:name => parts[2]).first
      #  c = e.computes.where(:name => parts[0], :num => parts[1]).first
      #  return c if c
      #end
      #
      #if record.long
      #  c = Compute.where(:public_dns => record.long).first
      #  return c if c
      #end

      nil
    end
  end
end
