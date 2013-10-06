class Compute
  include Mongoid::Document
  include Mongoid::Timestamps
  include Qujo::Concerns::Model

  include Cloud
  include Deleting
  include Org

  belongs_to :environment, index: true
  belongs_to :balancer, index: true
  belongs_to :userdata, index: true
  has_many :records, as: :nameable
  has_and_belongs_to_many :roles #TODO: part of chef, shouldn't be included here

  field :name, type: String
  field :num, type: Integer, default: 0
  #[:name, :environment, :roles, :image, :flavor, :keypair, :groups, :region]
  field :image, type: String #, default: Mystro.organization.compute.image
  field :flavor, type: String #, default:  Mystro.organization.compute.flavor
  field :keypair, type: String #, default: Mystro.organization.compute.keypair
  field :groups, type: Array #, default: Mystro.organization.compute.groups
  field :region, type: String #, default: Mystro.organization.compute.region

  cloud do
    provides :state, String
    provides :public_dns, String
    provides :public_ip, String
    provides :private_dns, String
    provides :private_ip, String
    provides :availability_zone, String
    provides :tags, Hash, default: {}
  end

  index({name: 1})
  index({name: 1, num: 1})


  # a bit hacky, but easiest way to make sure we get defaults from current account
  def set_defaults(organization)
    organization = organization.is_a?(String) ? Organization.named(organization) : organization
    self.organization = organization
    ud = Userdata.named(organization.mystro.compute.userdata) || nil rescue nil
    ud ||= Userdata.named("default")
    if organization && organization.mystro
      self.image = organization.mystro.compute.image
      self.flavor = organization.mystro.compute.flavor
      self.keypair = organization.mystro.compute.keypair
      self.groups = organization.mystro.compute.groups
      self.region = organization.mystro.compute.region
      self.userdata = ud
    end
  end

  def name=(value)
    s = value =~ /\./ ? value.split(".").first : value
    n = 0
    s.match(/^([a-zA-Z]+)([0-9]+)$/) do |m|
      s = m[1]
      n = m[2]
    end
    super(s)
    self.num = n
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
    #o = organization && organization.name || nil
    #e = environment && environment.name || nil
    return "#{name}#{number}" unless name.blank?
    return rid if rid
    '--not-set--'
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
        private_dns: private_dns,
        private_ip: private_ip,
        environment: environment ? environment.name : nil,
        account: account ? account.name : nil,
        balancer: balancer ? balancer.name : nil,
        roles: roles_string
    }
  end

  #TODO: VOLLEY
  has_many :installs, class_name: "MystroVolley::Install"

  def versions
    installs.map(&:version).uniq
  end

  class << self
    def create_from_cloud(obj)
      compute = Compute.where(:rid => obj.id).first || Compute.create(:rid => obj.id)
      name = obj.tags['Name'] || obj.id
      org = obj.tags['Organization'] || obj.tags['Account'] || nil

      compute.name = name
      compute.image = obj.image
      compute.organization = org ? Organization.named(org) : nil
      compute.flavor = obj.flavor
      compute.state = obj.state
      compute.public_dns = obj.dns
      compute.public_ip = obj.ip
      compute.private_dns = obj.private_dns
      compute.private_ip = obj.private_ip
      compute.availability_zone = obj.zone
      compute.groups = obj.groups
      compute.keypair = obj.keypair
      compute.region = obj.region
      compute.synced_at = Time.now

      list = (obj.tags["Role"]||obj.tags["Roles"]||"").split(",")
      list.each do |r|
        role = Role.find_or_create_by(:name => r)
        compute.roles << role
      end
      compute.tags = obj.tags || {}
      compute.save
      compute
    end

    #def create_from_fog(obj)
    #  compute = Compute.where(:rid => obj.id).first || Compute.create(:rid => obj.id)
    #  name = obj.tags['Name']||""
    #  num = nil
    #  (name, _, _) = name.split(".") if name =~ /\./
    #  name.match(/^([a-zA-Z]+)([0-9]+)$/) do |m|
    #    name = m[1]
    #    num = m[2]
    #  end
    #  compute.name = name
    #  compute.num = num if num
    #  compute.state = obj.state.to_s.downcase
    #  compute.public_dns = obj.dns_name
    #  compute.public_ip = obj.public_ip_address
    #  compute.private_dns = obj.private_dns_name
    #  compute.private_ip = obj.private_ip_address
    #  compute.availability_zone = obj.availability_zone
    #  compute.synced_at = Time.now
    #
    #  list = (obj.tags["Role"]||obj.tags["Roles"]||"").split(",")
    #  list.each do |r|
    #    role = Role.find_or_create_by(:name => r)
    #    compute.roles << role
    #  end
    #
    #  compute.save
    #  compute
    #end

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
      record.values.each do |val|
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
