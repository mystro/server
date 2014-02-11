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
  embeds_many :volumes
  has_and_belongs_to_many :roles

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
  def set_defaults(org)
    org = org.is_a?(String) ? Organization.named(org) : org
    self.organization ||= org
    ud = Userdata.named(org.mystro.compute.userdata) || nil rescue nil
    ud ||= Userdata.named("default")
    cfg = org.compute_config
    if cfg
      self.image ||= cfg['image']
      self.flavor ||= cfg['flavor']
      self.keypair ||= cfg['keypair']
      self.groups ||= cfg['groups']
      self.region ||= cfg['region']
      self.userdata ||= ud
    end
  end

  def name=(value)
    (s, n) = Compute.name_and_number(value)
    super(s)
    self.num = n
  end

  def roles_string
    (roles||[]).map { |r| r.name }.join(",")
  end

  def long
    if organization
      if environment
        "#{display}.#{environment.name}.#{self.zone}"
      else
        "#{display}.#{self.zone}"
      end
    end
  end

  def short
    if organization
      if environment
        "#{display}.#{environment.name}.#{organization.name}"
      else
        "#{display}.#{organization.name}"
      end
    else
      display
    end
  end

  def display
    #o = organization && organization.name || nil
    #e = environment && environment.name || nil
    return "#{name}#{number}" unless name.blank?
    return rid if rid
    '--not-set--'
  end

  def number
    num > 0 ? "%02d" % num : ""
  end

  def envname
    environment ? environment.name : ""
  end

  def subdomain
    self.zone.split(".")[0] || "" rescue ""
  end

  def zone
    #account && account.mystro.dns && account.mystro.dns.zone ? account.mystro.dns.zone : "unknown"
    organization.record_config['zone'] || 'unknown' #rescue 'unknown'
  end

  #def fog_tags
  #  {
  #      'Name' => display,
  #      'Environment' => envname,
  #      'Roles' => roles_string,
  #      'Account' => account ? account.name : ""
  #  }
  #end
  #
  #def fog_options
  #  u = self.userdata.name || account.mystro.compute.userdata || "default"
  #  z = self.zone
  #  a = account.name || "unknown"
  #  {
  #      image_id: image,
  #      flavor_id: flavor,
  #      key_name: keypair,
  #      groups: groups,
  #      region: region,
  #      user_data: Mystro::Userdata.create(long, roles.map(&:name), envname,
  #                                         nickname: display,
  #                                         package: u,
  #                                         zone: z,
  #                                         account: a)
  #  }
  #end

  def from_cloud(obj)
    name = obj.tags['Name'] || obj.id
    org = obj.tags['Organization'] || obj.tags['Account'] || nil

    self.name = name if name
    self.organization = Organization.named(org) if org

    if self.organization
      self.set_defaults(self.organization)
    end

    self.image = obj.image if obj.image
    self.flavor = obj.flavor if obj.flavor
    self.state = obj.state if obj.state
    self.public_dns = obj.dns if obj.dns
    self.public_ip = obj.ip if obj.ip
    self.private_dns = obj.private_dns if obj.private_dns
    self.private_ip = obj.private_ip if obj.private_ip
    self.availability_zone = obj.zone if obj.zone
    self.groups = obj.groups if obj.groups
    self.keypair = obj.keypair if obj.keypair
    self.region = obj.region if obj.region

    if obj.userdata
      self.userdata = Userdata.named(obj.userdata) || Userdata.named('default')
    end

    list = (obj.tags["Role"]||obj.tags["Roles"]||"").split(",")
    list.each do |r|
      role = Role.find_or_create_by(:name => r)
      self.roles << role
    end
    self.tags = obj.tags if obj.tags && obj.tags.count > 0

    if obj.volumes && obj.volumes.count > 0
      obj.volumes.each do |vol|
        volume = self.volumes.where(device: vol.device, size: vol.size).first || self.volumes.new
        volume.from_cloud(vol)
      end
    end
  end

  def to_cloud
    z = self.zone
    e = self.envname
    u = self.userdata.name || organization.compute_config['userdata'] || 'default'
    o = self.organization.name || 'unknown'
    ud = Mystro::Userdata.create(long, roles.map(&:name), e, nickname: display, package: u, zone: z, organization: o)
    t = self.tags || {}
    t['Name'] = short
    t['Environment'] = e
    t['Organization'] = o
    data = {
        id: self.rid,
        image: self.image,
        flavor: self.flavor,
        state: self.state,
        dns: self.public_dns,
        ip: self.public_ip,
        private_dns: self.private_dns,
        private_ip: self.private_ip,
        zone: self.availability_zone,
        groups: self.groups,
        keypair: self.keypair,
        region: self.region,
        tags: self.tags,
        volumes: self.volumes.map {|e| e.to_cloud},
        userdata: ud,
    }
    Mystro::Cloud::Compute.new(data)
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
        organization: organization ? organization.name : nil,
        balancer: balancer ? balancer.name : nil,
        roles: roles_string,
        user: to_api_image_user
    }
  end

  def to_api_image_user
    if image
      i = Image.remote(image)
      if i
        return i.user
      end
    end
    nil
  end

  #TODO: VOLLEY
  #has_many :installs, class_name: "MystroVolley::Install"

  #def versions
  #  installs.map(&:version).uniq
  #end

  class << self
    def name_and_number(value)
      s = value =~ /\./ ? value.split(".").first : value
      n = 0
      s.match(/^([a-zA-Z]+)([0-9]+)$/) do |m|
        s = m[1]
        n = m[2]
      end
      [s, n]
    end

    def find_by_cloud(obj, env=nil, org=nil)
      name = obj.tags['Name']
      id = obj.id
      (name, num) = name_and_number(name) if name
      byid = Compute.where(rid: id).first if id
      return byid if byid
      byneo = Compute.where(name: name, num: num, environment: env, organization: org).first if name && env && org
      return byneo if byneo
      Compute.where(name: name, num: num, environment: env, organization: org).first if name
    end

    def create_from_cloud(obj)
      compute = Compute.where(:rid => obj.id).first || Compute.create(:rid => obj.id)
      compute.from_cloud(obj)
      compute.synced_at = Time.now
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

    #def new_from_template(environment, tserver_attrs, i=nil)
    #  tserver = tserver_attrs
    #  userdata = Userdata.named(tserver.userdata)
    #  raise "userdata #{tserver.userdata} not found, need to `rake mystro:push`?" unless userdata
    #
    #  o = {
    #      roles: Role.create_from_fog(tserver.roles),
    #      groups: tserver.groups,
    #      image: tserver.image,
    #      flavor: tserver.flavor,
    #      keypair: tserver.keypair,
    #      managed: true,
    #      userdata: userdata,
    #  }.delete_if { |k, v| v.nil? }
    #
    #  name = tserver.name
    #  i = environment.get_next_number(tserver.name) unless i
    #  o.merge!({name: name, num: i})
    #  compute = environment.computes.new(o)
    #  #compute.set_defaults(environment.account) unless compute.synced_at
    #
    #  compute
    #end
    #
    #def create_from_template(environment, tserver_attrs, i=1)
    #  tserver = tserver_attrs
    #  userdata = Userdata.named(tserver.userdata)
    #  raise "userdata #{tserver.userdata} not found, need to `rake mystro:push`?" unless userdata
    #
    #  o = {
    #      roles: Role.create_from_fog(tserver.roles),
    #      groups: tserver.groups,
    #      image: tserver.image,
    #      flavor: tserver.flavor,
    #      keypair: tserver.keypair,
    #      managed: true,
    #      userdata: userdata,
    #  }.delete_if { |k, v| v.nil? }
    #  name = tserver.name
    #  compute = environment.computes.find_or_create_by(name: name, num: i)
    #  compute.set_defaults(environment.account) unless compute.synced_at
    #  compute.update_attributes(o)
    #  compute.save!
    #
    #  compute
    #end

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
