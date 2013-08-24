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
  embeds_one :health_check
  has_many :computes
  has_many :records, as: :nameable

  #field :name, type: String # name is stored in the remote id (rid)
  field :environment_id, type: String
  field :primary, type: Boolean, default: false

  #TODO: sticky settings are on listeners not balancers.
  field :sticky, type: Boolean, default: false
  field :sticky_type, type: String
  field :sticky_arg, type: String

  field :public_dns, type: String

  scope :for_account, ->(account){ where(:account.in => [nil, Account.named(account)]) }

  def name
    rid
  end

  def short
    rid
  end

  def display
    rid
  end

  def bname
    environment ? rid.gsub(/^#{environment.name}-/, "") : rid
  end

  def add_compute(rid)
    computes << Compute.remote(rid)
    #TODO: Jobs::Balancer::Update to add new compute to balancer on cloud
  end

  def envname
    environment ? environment.name : "unknown"
  end

  def fog_options
    o = {
        id: rid,
        "ListenerDescriptions" => listeners.map {|l| l.fog_options},
        availability_zones: zones
    }
    #azs = zones
    #o.merge!({}) if azs.count > 0
    o
  end

  def to_fog
    a = Mystro::Account.get(account.name).balancer
    a.find(name)
  end

  def zones
    computes.collect do |e|
      s = Mystro.compute.find(e.rid)
      s ? s.availability_zone : nil
    end.compact.uniq
  end

  class << self

    def named(name)
      where(rid: name).first
    end

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

      balancer.health_check = nil
      healthcheck = HealthCheck.create_from_fog(balancer, obj.health_check)

      balancer.save
      balancer
    end

    def create_from_template(environment, tbalancer)
      name     = "#{environment.name}-#{tbalancer.name}"
      balancer = environment.balancers.find_or_create_by(name: name)

      attrs    = {
          rid:     name,
          primary: tbalancer.primary,
          managed: true
      }
      attrs.merge!({
                       sticky:      true,
                       sticky_type: tbalancer.sticky_type,
                       sticky_arg:  tbalancer.sticky_arg,
                   }) if tbalancer.sticky
      balancer.update_attributes(attrs)

      tbalancer.listeners.each do |tlistener|
        listener = Listener.create_from_template(balancer, tlistener)
      end

      if tbalancer.healthcheck
        healthcheck = HealthCheck.create_from_template(balancer, tbalancer.healthcheck)
      end

      balancer.account = environment.account
      balancer.save!

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
