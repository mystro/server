class Compute
  include Mongoid::Document
  include Mongoid::Timestamps

  include CommonAccount
  include CommonRemote
  include CommonWorker
  include CommonDeleting

  belongs_to :environment, index: true
  belongs_to :balancer, index: true
  belongs_to :account, index: true
  belongs_to :userdata, index: true
  has_many :records, as: :nameable
  has_and_belongs_to_many :roles

  field :name, type: String
  field :num, type: Integer, default: 0
  #[:name, :environment, :roles, :image, :flavor, :keypair, :groups, :region]
  field :image, type: String, default: Mystro.account.compute.image
  field :flavor, type: String, default: Mystro.account.compute.flavor
  field :keypair, type: String, default: Mystro.account.compute.keypair
  field :groups, type: Array, default: Mystro.account.compute.groups
  field :region, type: String, default: Mystro.account.compute.region

  field :state, type: String
  field :public_dns, type: String
  field :public_ip, type: String
  field :private_dns, type: String
  field :private_ip, type: String
  field :tags, type: Hash, default: {}

  index({num: 1})

  # a bit hacky, but easiest way to make sure we get defaults from current account
  def set_defaults(account)
    self.account = account
    ud = Userdata.named(account.mystro.compute.userdata) || nil rescue nil
    ud ||= Userdata.named("default")
    if account && account.mystro
      self.image = account.mystro.compute.image
      self.flavor = account.mystro.compute.flavor
      self.keypair = account.mystro.compute.keypair
      self.groups = account.mystro.compute.groups
      self.region = account.mystro.compute.region
      self.userdata = ud
    end
  end

  def roles_string
    (roles||[]).map { |r| r.name }.join(",")
  end

  def long
    "#{short}.#{self.zone}"
  end

  def short
    "#{name}#{number}.#{envname}"
  end

  def display
    a = subdomain
    "#{short}#{a ? ".#{a}" : ""}"
  end

  def number
    num > 0 ? num : ""
  end

  def envname
    environment ? environment.name : ""
  end

  def subdomain
    self.zone.split(".")[0] || "" rescue ""
  end

  def zone
    account && account.mystro.dns && account.mystro.dns.zone ? account.mystro.dns.zone : "unknown"
  end

  def fog_tags
    {
        'Name' => display,
        'Environment' => envname,
        'Roles' => roles_string,
        'Account' => account ? account.name : ""
    }
  end

  def fog_options
    u = self.userdata.name || account.mystro.compute.userdata || "default"
    z = self.zone
    a = account.name || "unknown"
    {
        image_id: image,
        flavor_id: flavor,
        key_name: keypair,
        groups: groups,
        region: region,
        user_data: Mystro::Userdata.create(long, roles.map(&:name), envname,
                                           nickname: display,
                                           package: u,
                                           zone: z,
                                           account: a)
    }
  end

  def to_api
    {
        id: id,
        name: display,
        long: (long rescue nil),
        dns: public_dns,
        ip: public_ip,
        environment: environment ? environment.name : nil,
        account: account ? account.name : nil,
        balancer: balancer ? balancer.name : nil,
        roles: roles_string
    }
  end

  #TODO: VOLLEY
  #has_many :installs, class_name: "MystroVolley::Install"
  #def versions
  #  installs.map(&:version).uniq
  #end

  class << self
    def create_from_fog(obj)
      compute = Compute.where(:rid => obj.id).first || Compute.create(:rid => obj.id)
      name = obj.tags['Name']||""
      num = nil
      (name, _, _) = name.split(".") if name =~ /\./
      name.match(/^([a-zA-Z]+)([0-9]+)$/) do |m|
        name = m[1]
        num = m[2]
      end
      compute.name = name
      compute.num = num if num
      compute.state = obj.state.to_s.downcase
      compute.public_dns = obj.dns_name
      compute.public_ip = obj.public_ip_address
      compute.private_dns = obj.private_dns_name
      compute.private_ip = obj.private_ip_address
      compute.synced_at = Time.now

      list = (obj.tags["Role"]||obj.tags["Roles"]||"").split(",")
      list.each do |r|
        role = Role.find_or_create_by(:name => r)
        compute.roles << role
      end

      compute.save
      compute
    end

    def new_from_template(environment, tserver_attrs, i=nil)
      tserver = tserver_attrs
      userdata = Userdata.named(tserver.userdata)
      raise "userdata #{tserver.userdata} not found, need to `rake mystro:push`?" unless userdata

      o = {
          roles: Role.create_from_fog(tserver.roles),
          groups: tserver.groups,
          image: tserver.image,
          flavor: tserver.flavor,
          keypair: tserver.keypair,
          managed: true,
          userdata: userdata,
      }.delete_if { |k, v| v.nil? }

      name = tserver.name
      i = environment.get_next_number(tserver.name) unless i
      o.merge!({name: name, num: i})
      compute = environment.computes.new(o)
      #compute.set_defaults(environment.account) unless compute.synced_at

      compute
    end

    def create_from_template(environment, tserver_attrs, i=1)
      tserver = tserver_attrs
      userdata = Userdata.named(tserver.userdata)
      raise "userdata #{tserver.userdata} not found, need to `rake mystro:push`?" unless userdata

      o = {
          roles: Role.create_from_fog(tserver.roles),
          groups: tserver.groups,
          image: tserver.image,
          flavor: tserver.flavor,
          keypair: tserver.keypair,
          managed: true,
          userdata: userdata,
      }.delete_if { |k, v| v.nil? }
      name = tserver.name
      compute = environment.computes.find_or_create_by(name: name, num: i)
      compute.set_defaults(environment.account) unless compute.synced_at
      compute.update_attributes(o)
      compute.save!

      compute
    end

    def find_by_record(record)
      list = [record.long, record.values].flatten
      list.each do |val|
        if ::IPAddress.valid?(val)
          o = Compute.where(:public_ip => val).first
          return o if o
        else
          o = Compute.where(:public_dns => val).first
          return o if o
        end
      end

      parts = record.parts
      if parts
        #puts "compute.find_by_record: #{record.short} => #{parts}"
        e = Environment.where(:name => parts[2]).first
        if e
          c = e.computes.where(:name => parts[0], :num => parts[1]).first
          return c if c

          c = e.computes.where(:name => parts[0]).first
          return c if c
        end
      end
    end
  end
end
