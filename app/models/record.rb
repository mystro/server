class Record
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Symbolize
  include Qujo::Concerns::Model

  include Cloud
  include Deleting
  include Org

  belongs_to :zone, index: true
  belongs_to :nameable, polymorphic: true
  belongs_to :organization, index: true

  field :name, type: String
  #symbolize :type, in: [:CNAME, :A], scopes: true, default: :CNAME
  #field :ttl, type: Integer, default: 300
  #field :values, type: Array

  cloud do
    provides :type, :symbolize, in: [:CNAME, :A], scopes: true, default: :CNAME
    provides :ttl, Integer, default: 300
    provides :values, Array
  end

  validates_presence_of :name
  validates_presence_of :values
  validates_numericality_of :ttl, only_integer: true, greater_than: 0

  def long
    name
  end

  def short
    name.gsub(/\.#{zone.domain}$/, "")
  end

  def parts
    short.match(/^([^\d]+)(\d+)*\.(\w+)\.*/) do
      r = $1
      n = $2
      e = $3
      return [r, n, e]
    end
    nil
  end

  def fog_options
  end

  def to_cloud
    if ::IPAddress.valid?(values.first)
      #A record
      data = {:id => rid, :name => name, :values => values, :type => 'A', :ttl => ttl || 86400}
    else
      #CNAME record
      data = {:id => rid, :name => name, :values => values, :type => 'CNAME', :ttl => ttl || 300}
    end
    Mystro::Cloud::Record.new(data)
  end

  def from_cloud(obj)
    self.rid = obj.identity if obj.identity
    self.ttl = obj.ttl if obj.ttl
    self.type = obj.type if obj.type
    self.values = obj.values if obj.values
    self.name = obj.name if obj.name
  end

  class << self
    #def create_from_fog(zone, obj)
    #  n                = obj.name.gsub(/\.$/, "")
    #  record           = remote(n) || create(:zone => zone, :rid => n, :name => n)
    #  record.ttl       = obj.ttl
    #  record.type      = obj.type
    #  record.values    = [*obj.value].flatten
    #  record.synced_at = Time.now
    #  record.save
    #  record
    #end

    def create_from_cloud(zone, obj)
      record = remote(obj.identity) || create(:zone => zone, :rid => obj.identity, :name => obj.name)
      record.from_cloud(obj)
      record.synced_at = Time.now
      record.save
      record
    end

    def find_by_record(record)
      #r = Record.where(:name => record.long).first
      #return r.nameable if r && r.nameable
      #
      #r = Record.any_in(values: record.long).first
      #return r.nameable if r && r.nameable

      record.values.each do |val|
        r = Record.where(name: val).first
        return r.nameable if r && r.nameable

        r = Record.any_in(values: val).first
        return r.nameable if r && r.nameable
      end

      nil
    end
  end
end
